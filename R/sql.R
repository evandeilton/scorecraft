# ============================================================================ #
# sql.R - production SQL engine (D11, non-negotiable requirement)
# ============================================================================ #
# Two blocks, in this order: a pre-processing CTE (training median,
# special-population flags, categorical COALESCE) and the WOE/BIN
# transformation emitted by the binning engine from the authoritative cut
# points. For the scorecard, a third block composes the score from the WOE
# columns and the whole points from the bin index. Covers exactly the
# shortlist.
# ============================================================================ #

#' Production SQL
#'
#' Code ready to run in the database, covering **exactly** the approved
#' variables (or those of the scorecard), in blocks in this order:
#'
#' \enumerate{
#'   \item CTE `base_scr`: reproduces the Stage 1 pre-processing -
#'     imputation of missing and sentinel by the **training** median,
#'     special-population flags, `COALESCE` of the categorical missing.
#'   \item The WOE/BIN transformation, emitted by
#'     [OptimalBinningWoE::obwoe_sql()] from the authoritative cut points
#'     with full precision.
#'   \item (Scorecard) CTE `woe_scr` with WOE and bin index, followed by the
#'     final `SELECT` with `score` (exact, `a + b * logit`), `<f>_points`
#'     per variable and `score_points` (whole points).
#' }
#'
#' The order matters: without the first block, the WOE would be applied to
#' data different from what was binned. The score computed by the SQL
#' matches [scr_apply()] numerically, by an automated test that runs both
#' paths.
#'
#' @param x An object from [scr_select()] or from [scr_scorecard()].
#' @param table Source table name. `NULL` uses `config$sql_table`.
#' @param dialect Dialect (`"ansi"`, `"databricks"`, `"spark"`, `"hive"`,
#'   `"mysql"`, `"mariadb"`, `"sqlserver"`, `"bigquery"`, `"postgres"`,
#'   `"oracle"`, `"snowflake"`, `"redshift"`, `"duckdb"`, `"sqlite"`).
#'   `NULL` uses `config$sql_dialect`.
#' @param file Path to write to. `NULL` (default) returns the lines.
#' @param ... Passed on to the methods.
#' @param output For `scr_result`: `"woe"`, `"bin"` or `"both"`. `NULL` uses
#'   `config$sql_output`.
#' @param what For `scr_scorecard`: `"score"` (default, the three blocks) or
#'   `"woe"` (the WOE/BIN SQL of the scorecard variables only).
#'
#' @return A character vector with the SQL (invisibly, when `file` is given).
#'
#' @family production
#' @examples
#' cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
#'                   xgb_rounds = 60, n_boot = 20)
#' res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
#'                   date_col = "ref_date")
#' cat(head(scr_sql(res, table = "prd.customers", dialect = "databricks"), 20), sep = "\n")
#' sc <- scr_scorecard(res)
#' cat(tail(scr_sql(sc), 12), sep = "\n")
#' @export
scr_sql <- function(x, table = NULL, dialect = NULL, file = NULL, ...) UseMethod("scr_sql")

#' @rdname scr_sql
#' @export
scr_sql.scr_result <- function(x, table = NULL, dialect = NULL, file = NULL, output = NULL, ...) {
  cfg <- x$config
  if (!is.null(table)) cfg$sql_table <- table
  if (!is.null(dialect)) cfg$sql_dialect <- dialect
  if (!is.null(output)) cfg$sql_output <- output
  out <- if (is.null(table) && is.null(dialect) && is.null(output)) x$sql else
    build_sql_woe(x$fit, x$triage$ledger, scr_selected(x), cfg, x$target, provenance = .provenance_line(x$lab))
  .sql_out(out, file)
}

#' @rdname scr_sql
#' @export
scr_sql.scr_scorecard <- function(x, table = NULL, dialect = NULL, file = NULL, what = c("score", "woe"), ...) {
  what <- match.arg(what)
  cfg <- x$config
  if (!is.null(table)) cfg$sql_table <- table
  if (!is.null(dialect)) cfg$sql_dialect <- dialect
  out <- if (identical(what, "woe")) build_sql_woe(x$fit, x$ledger, x$features, cfg, x$target, provenance = .provenance_line(x$lab))
         else if (is.null(table) && is.null(dialect)) x$sql
         else { y <- x; y$config <- cfg; build_sql_score(y) }
  .sql_out(out, file)
}

#' @keywords internal
#' @noRd
.sql_out <- function(out, file) {
  if (!is.null(file)) {
    writeLines(out, con = file)
    msg("SQL written to %s", file)
    return(invisible(out))
  }
  out
}

#' Block 1: lines of the SELECT of the pre-processing CTE
#' @keywords internal
#' @noRd
.sql_preprocess_lines <- function(ledger, features, cfg) {
  sources <- unique(vapply(features, function(f) {
    r <- ledger[output == f & kind == "num_flag", source]
    if (length(r)) r[1] else f
  }, character(1)))
  lines <- character()
  for (s in cfg$sql_keep_columns) lines <- c(lines, sprintf("    %s", s))
  sp <- cfg$special_values
  for (s in sources) {
    imp <- ledger[kind == "num_impute" & source == s]
    flg <- ledger[kind == "num_flag"   & source == s]
    coa <- ledger[kind == "cat_coalesce" & source == s]
    if (s %in% features) {
      if (nrow(imp)) {
        cond <- sprintf("%s IS NULL", s)
        if (length(sp)) cond <- sprintf("%s OR %s IN (%s)", cond, s, paste(vapply(sp, .sql_num, character(1)), collapse = ", "))
        lines <- c(lines, sprintf("    CASE WHEN %s THEN %s ELSE %s END AS %s", cond, .sql_num(imp$impute_value[1]), s, s))
      } else if (nrow(coa)) {
        lines <- c(lines, sprintf("    COALESCE(%s, %s) AS %s", s, .sql_str("MISSING"), s))
      } else {
        lines <- c(lines, sprintf("    %s", s))
      }
    }
    if (nrow(flg) && flg$output[1] %in% features) {
      whens <- sprintf("WHEN %s IS NULL THEN %s", s, .sql_str("MISSING"))
      for (v in sp) whens <- c(whens, sprintf("WHEN %s = %s THEN %s", s, .sql_num(v), .sql_str(paste0("S", v))))
      lines <- c(lines, sprintf("    CASE %s ELSE %s END AS %s", paste(whens, collapse = " "), .sql_str("REGULAR"), flg$output[1]))
    }
  }
  lines
}

#' Selection SQL: pre-processing CTE + WOE/BIN from the engine
#' @keywords internal
#' @noRd
build_sql_woe <- function(fit, ledger, features, cfg, target = NULL, provenance = NULL) {
  if (!length(features)) return("-- no approved variable: nothing to generate")
  cte <- "base_scr"
  lines <- .sql_preprocess_lines(ledger, features, cfg)
  woe_sql <- OptimalBinningWoE::obwoe_sql(
    obj = fit, table = cte, features = features, output = cfg$sql_output, style = "select",
    dialect = cfg$sql_dialect, keep_columns = if (length(cfg$sql_keep_columns)) cfg$sql_keep_columns else NULL,
    digits = NULL, comment = TRUE, bin_separator = cfg$bin_separator)
  c("-- =============================================================",
    sprintf("-- scorecraft | target: %s | %d approved variables | dialect: %s", target %||% "?", length(features), cfg$sql_dialect),
    sprintf("-- Generated on %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    "-- Block 1 (CTE base_scr): Stage 1 pre-processing - imputation of missing",
    "--   and sentinel values by the TRAINING median, special-population flags.",
    "-- Block 2: WOE/BIN transformation emitted by OptimalBinningWoE::obwoe_sql().",
    if (!is.null(provenance)) paste0("-- ", provenance),
    "-- =============================================================", "",
    sprintf("WITH %s AS (", cte), "  SELECT", paste(lines, collapse = ",\n"),
    sprintf("  FROM %s", cfg$sql_table), ")", "", as.character(woe_sql)) |> .sql_lines()
}

#' One element per line, so head()/tail()/grep() work line by line
#' @keywords internal
#' @noRd
.sql_lines <- function(x) unlist(strsplit(paste(x, collapse = "\n"), "\n", fixed = TRUE))

#' Extract the column expressions of a SELECT emitted by obwoe_sql
#' @keywords internal
#' @noRd
.sql_select_exprs <- function(sql) {
  l <- unlist(strsplit(as.character(sql), "\n", fixed = TRUE))
  i0 <- which(trimws(l) == "SELECT")[1]
  i1 <- max(which(grepl("^FROM ", trimws(l))))
  body <- l[(i0 + 1L):(i1 - 1L)]
  body <- body[nzchar(trimws(body))]
  body[length(body)] <- sub(",\\s*$", "", body[length(body)])
  body
}

#' Scorecard SQL: pre-processing CTE + WOE/index CTE + score
#' @keywords internal
#' @noRd
build_sql_score <- function(sc) {
  cfg <- sc$config
  feats <- sc$features
  keep <- cfg$sql_keep_columns
  lines <- .sql_preprocess_lines(sc$ledger, feats, cfg)
  woe_x <- OptimalBinningWoE::obwoe_sql(obj = sc$fit, table = "base_scr", features = feats, output = "woe",
                                        style = "select", dialect = cfg$sql_dialect, digits = NULL,
                                        comment = FALSE, bin_separator = cfg$bin_separator)
  idx_x <- OptimalBinningWoE::obwoe_sql(obj = sc$fit, table = "base_scr", features = feats, output = "index",
                                        style = "select", dialect = cfg$sql_dialect, digits = NULL,
                                        comment = FALSE, bin_separator = cfg$bin_separator)
  exprs <- c(if (length(keep)) paste0(keep, ","), .sql_select_exprs(woe_x))
  exprs[length(exprs)] <- paste0(exprs[length(exprs)], ",")
  exprs <- c(exprs, .sql_select_exprs(idx_x))

  al <- sc$alignment
  base_raw <- al$a + al$b * unname(sc$coef["(Intercept)"])
  score_terms <- c(.sql_num(base_raw), vapply(feats, function(f)
    sprintf("%s * %s_woe", .sql_num(al$b * unname(sc$coef[f])), f), character(1)))
  pts_cases <- vapply(feats, function(f) {
    p <- sc$points[variable == f]
    sprintf("    CASE %s_idx %s ELSE 0 END AS %s_points", f,
            paste(sprintf("WHEN %d THEN %s", p$bin_id, .sql_num(p$points)), collapse = " "), f)
  }, character(1))
  # the subselect computes the points columns once; the outer SELECT exposes
  # them by name and sums them into score_points
  final <- c(
    "SELECT",
    if (length(keep)) sprintf("    %s,", keep),
    sprintf("    %s AS score,", paste(score_terms, collapse = "\n      + ")),
    paste0(vapply(feats, function(f) sprintf("    %s_points", f), character(1)), ","),
    sprintf("    %s AS score_points", paste(c(.sql_num(sc$base_points), paste0(feats, "_points")), collapse = " + ")),
    "FROM (", "  SELECT", "    *,", paste0("  ", pts_cases, collapse = ",\n"), "  FROM woe_scr", ") pts;")

  c("-- =============================================================",
    sprintf("-- scorecraft | scorecard of target: %s | %d variables | dialect: %s", sc$target, length(feats), cfg$sql_dialect),
    sprintf("-- Generated on %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    sprintf("-- Scale: %s points at odds %s:1 (%s), PDO %s | %s", format(sc$scale$base_score), format(sc$scale$base_odds),
            sc$odds_orientation, format(sc$scale$pdo), sc$direction),
    sprintf("-- score = %s + %s * logit | base_points = %s", .sql_num(al$a), .sql_num(al$b), format(sc$base_points)),
    "-- Block 1 (CTE base_scr): pre-processing frozen on train.",
    "-- Block 2 (CTE woe_scr): WOE and bin index, emitted by OptimalBinningWoE::obwoe_sql().",
    "-- Block 3: exact score (from the WOE) and whole points (from the bin index).",
    if (!is.null(sc$lab)) paste0("-- ", .provenance_line(sc$lab)),
    "-- =============================================================", "",
    "WITH base_scr AS (", "  SELECT", paste(lines, collapse = ",\n"), sprintf("  FROM %s", cfg$sql_table), "),",
    "woe_scr AS (", "  SELECT", exprs, "  FROM base_scr", ")", "", final) |> .sql_lines()
}
