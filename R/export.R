# ============================================================================ #
# export.R - deliverables: hardened xlsx writer, four workbooks, SQL, summary
# ============================================================================ #
# Writer contract: sanitise
# formula injection -> write to a temporary file -> reopen and verify sheet
# names and row counts -> rename atomically. An empty sheet receives an
# availability/reason_code row, never a fabricated zero.
# ============================================================================ #

#' Write the deliverables
#'
#' For an `scr_result`: the selection workbook (`selection_<target>.xlsx`:
#' funnel, gains, screening, hold-out, models, votes, consensus, ledger,
#' redundancy), the WOE SQL and the executive summary in Markdown. For an
#' `scr_scorecard`: three workbooks (the detailing decision of SPEC section 7
#' resolved as separate files) plus the score SQL:
#'
#' \describe{
#'   \item{`scorecard_<target>.xlsx`}{`Score_Summary` (with `odds_orientation`),
#'     `Final_Scorecard`, `Coefficients`, `Sign_Check`, `Alignment`,
#'     `Model_Card`, `Challenger` and `Swap_Set` (when a challenger exists).}
#'   \item{`validation_<target>.xlsx`}{`Score_Gains_Frozen`, `Variable_Gains_IV`,
#'     `Discrimination_CI`, `Stability_PSI_Timeline`, `Stability_CSI_Timeline`,
#'     `Calibration`, `Performance_By_Vintage`, `Rank_Order_Diagnostics`.}
#'   \item{`strategy_<target>.xlsx`}{`Population_Scope`, `Cutoff_Sweep`,
#'     `Strategy_Bands`, `Reject_Sensitivity`, `Monitoring_Plan`.}
#' }
#'
#' The timeline and vintage sheets need the date column of the split; when it
#' is absent they carry an availability row instead of a fabricated number.
#'
#' @param x An object from [scr_select()] or [scr_scorecard()].
#' @param dir Output directory. Created if it does not exist.
#' @param stamp If `TRUE` (default), writes to a timestamped subdirectory,
#'   preserving earlier runs.
#' @param ... For `scr_scorecard`: precomputed `cutoff`, `strategy`,
#'   `reject` and `monitor` objects, and `revenue_good`/`loss_bad` for the
#'   default strategy table.
#'
#' @return The object `x`, with `$files` filled, invisibly.
#'
#' @family production
#' @examplesIf requireNamespace("openxlsx", quietly = TRUE)
#' cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
#'                   xgb_rounds = 60, n_boot = 20)
#' res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
#'                   date_col = "ref_date")
#' out <- file.path(tempdir(), "scorecraft-example")
#' res <- scr_export(res, out, stamp = FALSE)
#' basename(unlist(res$files))
#' sc <- scr_export(scr_scorecard(res), out, stamp = FALSE)
#' basename(unlist(sc$files))
#' @export
scr_export <- function(x, dir, stamp = TRUE, ...) UseMethod("scr_export")

#' @rdname scr_export
#' @export
scr_export.scr_result <- function(x, dir, stamp = TRUE, ...) {
  .need_openxlsx()
  out_dir <- .export_dir(dir, stamp)
  tag <- tolower(x$target)
  sheets <- list(
    "01_Funnel"      = x$funnel,
    "02_Gains"       = x$gains,
    "03_Screening"   = x$screen$summary,
    "04_Holdout"     = x$holdout,
    "05_Models"      = x$models$metrics,
    "06_Votes"       = x$models$votes,
    "07_Consensus"   = x$consensus$table,
    "08_Ledger"      = x$triage$ledger,
    "09_Redundancy"  = x$prune$dropped,
    "10_Coarse_Classing" = if (is.null(x$lab)) NULL else x$lab$spec,
    "11_Decision_Ledger" = if (is.null(x$lab)) NULL else x$lab$ledger
  )
  files <- list(
    xlsx = .scr_write_xlsx(sheets, file.path(out_dir, sprintf("selection_%s.xlsx", tag))),
    sql  = file.path(out_dir, sprintf("sql_woe_%s.sql", tag)),
    md   = file.path(out_dir, sprintf("summary_%s.md", tag)))
  writeLines(x$sql, files$sql); writeLines(x$summary_md, files$md)
  for (f in files) msg("  %s", f)
  x$files <- files
  invisible(x)
}

#' @rdname scr_export
#' @export
scr_export.scr_scorecard <- function(x, dir, stamp = TRUE, ...) {
  .need_openxlsx()
  extra <- list(...)
  out_dir <- .export_dir(dir, stamp)
  tag <- tolower(x$target)
  ct <- extra$cutoff %||% scr_cutoff(x)
  st <- extra$strategy %||% scr_strategy(x, revenue_good = extra$revenue_good %||% 1, loss_bad = extra$loss_bad %||% 1)
  rj <- extra$reject %||% scr_reject(x)
  mo <- extra$monitor

  na_tl <- data.frame(availability = "not_available", reason_code = "NO_DATE_COLUMN_IN_SPLIT", stringsAsFactors = FALSE)
  tl <- .timelines(x, mo)

  scorecard <- list(
    "Score_Summary"   = .kv_table(c(list(target = x$target, direction = x$direction, odds_orientation = x$odds_orientation),
                                    x$scale[c("base_score", "base_odds", "pdo", "factor", "offset")],
                                    list(a = x$alignment$a, b = x$alignment$b, base_points = x$base_points,
                                         points_style = x$points_style, n_features = length(x$features)))),
    "Final_Scorecard" = x$points,
    "Coefficients"    = data.frame(term = names(x$coef), estimate = unname(x$coef), stringsAsFactors = FALSE),
    "Sign_Check"      = x$sign_check,
    "Alignment"       = .kv_table(c(x$alignment[c("base_score", "base_odds", "pdo", "direction", "odds_orientation", "factor", "offset", "a", "b")],
                                    x$alignment$calibration[c("method", "intercept", "slope", "r2", "n_bands")])),
    "Alignment_Bands" = x$alignment$calibration$bands,
    "Model_Card"      = .kv_table(x$model_card),
    "Challenger"      = if (is.null(x$challenger)) NULL else cbind(engine = x$challenger$engine,
                          supports_scorecard = FALSE, x$challenger$metrics),
    "Swap_Set"        = if (is.null(x$challenger)) NULL else x$challenger$swapset,
    "Coarse_Classing" = if (is.null(x$lab)) NULL else x$lab$spec[x$lab$spec$variable %in% x$features, , drop = FALSE],
    "Decision_Ledger" = if (is.null(x$lab)) NULL else x$lab$ledger
  )
  validation <- list(
    "Score_Gains_Frozen"      = x$gains,
    "Variable_Gains_IV"       = x$points[, c("variable", "bin_id", "bin", "count_fit", "pos_rate", "woe", "iv", "points")],
    "Discrimination_CI"       = x$metrics,
    "Stability_PSI_Timeline"  = tl$psi %||% na_tl,
    "Stability_CSI_Timeline"  = tl$csi %||% na_tl,
    "Stability_Variables"     = x$stability$variables,
    "Calibration"             = x$calibration$summary,
    "Calibration_Bands"       = x$calibration$table,
    "Performance_By_Vintage"  = tl$vintage %||% na_tl,
    "Rank_Order_Diagnostics"  = x$rank_order
  )
  strategy <- list(
    "Population_Scope"   = .kv_table(rj$scope),
    "Band_Coverage"      = rj$coverage,
    "Cutoff_Sweep"       = ct$table,
    "Strategy_Bands"     = st$table,
    "Reject_Sensitivity" = rj$sensitivity,
    "Monitoring_Plan"    = as.data.frame(if (!is.null(mo)) mo$plan else x$monitoring_plan %||% scr_monitoring_plan(x))
  )
  files <- list(
    scorecard  = .scr_write_xlsx(scorecard,  file.path(out_dir, sprintf("scorecard_%s.xlsx", tag))),
    validation = .scr_write_xlsx(validation, file.path(out_dir, sprintf("validation_%s.xlsx", tag))),
    strategy   = .scr_write_xlsx(strategy,   file.path(out_dir, sprintf("strategy_%s.xlsx", tag))),
    sql_score  = file.path(out_dir, sprintf("sql_score_%s.sql", tag)),
    sql_woe    = file.path(out_dir, sprintf("sql_woe_%s.sql", tag)))
  writeLines(x$sql, files$sql_score)
  writeLines(scr_sql(x, what = "woe"), files$sql_woe)
  for (f in files) msg("  %s", f)
  x$files <- files
  invisible(x)
}

#' Timelines by period of the split date column (or of a monitor object)
#' @keywords internal
#' @noRd
.timelines <- function(x, mo = NULL) {
  if (!is.null(mo)) return(list(psi = mo$psi, csi = mo$csi, vintage = mo$vintage))
  if (is.null(x$date_col) || is.null(x$samples$holdout$date)) return(list(psi = NULL, csi = NULL, vintage = NULL))
  # rebuild newdata-free timelines from the scored samples: the hold-out
  # periods against the training distribution
  s <- x$samples$holdout; tr <- x$samples$train
  periods <- sort(unique(as.character(s$date)))
  hie <- identical(x$direction, "higher_is_riskier")
  pl <- .read_plan(x$monitoring_plan %||% scr_monitoring_plan(x))$thresholds
  psi <- data.table::rbindlist(lapply(periods, function(p) {
    i <- as.character(s$date) == p
    r <- scr_psi(tr$score, s$score[i], breaks = x$breaks, alpha = pl$alpha, thresholds = pl$psi)
    data.table::data.table(period = p, n = sum(i), mean_score = mean(s$score[i]), psi = r$psi,
                           flag_fixed = r$flag_fixed, critical = r$critical, flag_adjusted = r$flag_adjusted)
  }))
  vintage <- data.table::rbindlist(lapply(periods, function(p) {
    i <- as.character(s$date) == p
    m <- scr_metrics(s$score[i], s$y[i], higher_is_event = hie, ci = TRUE, n_boot = x$config$n_boot,
                     level = x$config$ci_level, seed = x$config$seed, nthread = x$config$nthread)
    data.table::data.table(period = p, n = sum(i), events = sum(s$y[i]), event_rate = mean(s$y[i]),
                           mean_score = mean(s$score[i]), auc = m$auc, auc_lo = m$auc_lo, auc_hi = m$auc_hi,
                           ks = m$ks, ks_lo = m$ks_lo, ks_hi = m$ks_hi, gini = m$gini)
  }))
  csi <- if (is.null(x$holdout_bins)) data.table::copy(x$stability$variables)[, period := "holdout"] else
    data.table::rbindlist(lapply(periods, function(p) {
      i <- as.character(s$date) == p
      data.table::rbindlist(lapply(x$features, function(f) {
        pt <- x$points[variable == f]
        cmp <- tabulate(x$holdout_bins[[f]][i], nbins = nrow(pt))
        .csi_dt(p, f, .csi_row(pt, cmp, pl$alpha, pl$csi))
      }))
    }))
  list(psi = psi, csi = csi, vintage = vintage)
}

#' @keywords internal
#' @noRd
.kv_table <- function(l) {
  l <- l[!vapply(l, is.null, logical(1))]
  data.frame(item = names(l), value = vapply(l, function(v) paste(format(v), collapse = ", "), character(1)),
             stringsAsFactors = FALSE, row.names = NULL)
}

#' @keywords internal
#' @noRd
.need_openxlsx <- function() {
  if (!requireNamespace("openxlsx", quietly = TRUE)) stop("scr_export() needs the 'openxlsx' package.", call. = FALSE)
}

#' @keywords internal
#' @noRd
.export_dir <- function(dir, stamp) {
  out_dir <- if (isTRUE(stamp)) file.path(dir, format(Sys.time(), "%Y%m%d_%H%M%S")) else dir
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  out_dir
}

#' Hardened xlsx writer: sanitise, write to a temporary file, reopen and verify, rename
#' @keywords internal
#' @noRd
.scr_write_xlsx <- function(sheets, file) {
  sheets <- sheets[!vapply(sheets, is.null, logical(1))]
  clean <- lapply(sheets, .sanitise_sheet)
  tmp <- file.path(dirname(file), paste0(".", basename(file), ".tmp"))
  on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
  openxlsx::write.xlsx(clean, file = tmp, asTable = TRUE, overwrite = TRUE, tableStyle = "TableStyleLight10")
  # reopen and verify: every sheet present, every row count as written
  got <- openxlsx::getSheetNames(tmp)
  if (!identical(got, names(clean))) stop("xlsx verification failed: sheet names differ in ", file, call. = FALSE)
  for (nm in names(clean)) {
    back <- openxlsx::read.xlsx(tmp, sheet = nm)
    if (nrow(back) != nrow(clean[[nm]])) {
      stop("xlsx verification failed: sheet '", nm, "' has ", nrow(back), " rows, expected ", nrow(clean[[nm]]), call. = FALSE)
    }
  }
  if (file.exists(file)) unlink(file)
  if (!file.rename(tmp, file)) stop("could not move the verified workbook to ", file, call. = FALSE)
  file
}

#' Sanitise a sheet: plain data.frame, no formula injection, no empty table
#' @keywords internal
#' @noRd
.sanitise_sheet <- function(d) {
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  if (nrow(d) == 0L || ncol(d) == 0L) {
    return(data.frame(availability = "not_available", reason_code = "NO_ROWS_THIS_RUN", stringsAsFactors = FALSE))
  }
  for (j in seq_along(d)) {
    v <- d[[j]]
    if (is.factor(v)) v <- as.character(v)
    if (is.list(v)) v <- vapply(v, function(e) paste(format(e), collapse = "; "), character(1))
    if (is.character(v)) {
      hit <- !is.na(v) & grepl("^[=+@-]", v)
      if (any(hit)) v[hit] <- paste0("'", v[hit])
    }
    d[[j]] <- v
  }
  d
}
