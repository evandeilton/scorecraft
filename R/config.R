# ============================================================================ #
# config.R - the single pipeline configuration
# ============================================================================ #
# One config object crosses every stage. Presets touch only the tightness of
# the funnel (how many variables survive); everything else is identical.
# ============================================================================ #

#' Pipeline configuration
#'
#' Builds the configuration object that crosses every stage, from
#' [scr_split()] to [scr_export()]. A preset sets the tightness of the
#' selection funnel; any individual key can be overridden through `...`.
#'
#' @section Presets:
#'
#' A preset touches four keys and nothing else: `target_max`, `min_votes`,
#' `corr_cutoff` and `iv_min`.
#'
#' | preset | variables at the end | `min_votes` | `corr_cutoff` | `iv_min` |
#' |---|---:|---:|---:|---:|
#' | `"aggressive"` | 10 to 15 | 3 | 0.60 | 0.03 |
#' | `"moderate"` | 10 to 25 | 2 | 0.70 | 0.02 |
#' | `"lazy"` | 10 to 40 | 1 | 0.80 | 0.02 |
#'
#' Use [scr_presets()] to see the resolved table and [scr_config_keys()] for
#' the full key dictionary.
#'
#' @section Risk or propensity (`objective`):
#'
#' The two literatures use the same mathematics with opposite conventions.
#' In credit and fraud, `target = 1` is the **bad** case and the scorecard is
#' built so that more points mean less risk. In propensity, `target = 1` is
#' the **good** case and the campaign list needs more points to mean a higher
#' chance of engaging.
#'
#' | | `"risk"` (default) | `"propensity"` |
#' |---|---|---|
#' | `target = 1` means | undesirable event | desirable event |
#' | Points scale | more points = safer | more points = more likely |
#' | Derived `direction` | `"higher_is_safer"` | `"higher_is_riskier"` |
#' | `odds_orientation` | `safe:event` | `event:safe` |
#'
#' **`objective` does not touch the selection.** It does not change the
#' modelled target, the cut points, the IV or the shortlist; it acts on the
#' direction of the points scale, on the odds orientation of the alignment
#' and on the vocabulary of the reports. To model the other class as the
#' event, the argument is `event_level` in [scr_split()] and [scr_select()],
#' and that one, unlike this, rewrites everything.
#'
#' @section Binning algorithm (`algorithm`):
#'
#' `"jedi"` is the default and stays exposed side by side with the
#' alternatives (decision D6), never hidden behind an `"auto"`. Choices with
#' distinct properties: `"ivb"`, `"dp"` and `"sblp"` are provably optimal for
#' categoricals; `"cm"` (ChiMerge) and `"fetb"` have a principled stopping
#' rule; `"ir"` (isotonic) guarantees monotone WOE; `"fast_mdlp"` is the
#' faithful Fayyad-Irani. The full list is in
#' [OptimalBinningWoE::obwoe_algorithms()]. A numeric-only or
#' categorical-only algorithm applies where it is valid and the other type
#' falls back to `"jedi"`.
#'
#' @section The Information Value gate:
#'
#' \describe{
#'   \item{`iv_min`}{Admission floor. Fails with `IV_BELOW_MIN`.}
#'   \item{`iv_max`}{Admission ceiling. Fails with `IV_SUSPICIOUS`. `1.00`
#'     (default) tolerates a legitimately strong predictor and cuts the
#'     absurd; `0.50` is the engine default, calibrated for credit default.}
#'   \item{`iv_suspect`}{Only the threshold of the report warning. Fails nothing.}
#' }
#'
#' The real leakage detector is `allow_degenerate = FALSE`: a bin with no
#' events or no non-events is the symptom that has no innocent explanation.
#'
#' @section Scorecard scale:
#'
#' `base_score`, `base_odds` and `pdo` are one statement: *at `base_score`
#' points the odds are `base_odds`, and every `pdo` points they double*.
#' `base_odds` is always expressed in the orientation `direction` implies
#' (non-event:event under `higher_is_safer`; event:non-event under
#' `higher_is_riskier`), and the alignment object records
#' `odds_orientation` so this is never implicit. The classic 600/50/20 is
#' Siddiqi's (2006) textbook example, not a parameter published by any
#' bureau. `align_method = "regression"` (default) takes the raw score to
#' that scale by regressing empirical log-odds on score bands, which absorbs
#' reweighting, miscalibration and prior shift; `"direct"` assumes the model
#' is calibrated and uses the logit as is.
#'
#' @param preset One of `"moderate"` (default), `"aggressive"` or `"lazy"`.
#' @param ... Overrides of any configuration key, by name. `NULL` means
#'   "keep the preset value", not "delete the key". An unknown name is an
#'   error, on purpose: a silent override leaves dead configuration in the
#'   file.
#'
#' @return An object of class `scr_config`: a named list with every key resolved.
#'
#' @references
#' Siddiqi, N. (2006). *Credit Risk Scorecards: Developing and Implementing
#' Intelligent Credit Scoring*. Wiley.
#'
#' @seealso [scr_select()] to use the configuration, [scr_presets()] to
#'   compare presets, [scr_config_keys()] for the key dictionary.
#' @family configuration
#' @examples
#' cfg <- scr_config()
#' cfg
#'
#' # propensity: more points = more likely to have the event
#' scr_config(objective = "propensity")$objective
#'
#' # NULL keeps the preset value (here, iv_min = 0.03 from aggressive)
#' scr_config("aggressive", iv_min = NULL)$iv_min
#'
#' # a wrong name fails loudly instead of becoming dead configuration
#' try(scr_config(iv_maximum = 1))
#' @export
scr_config <- function(preset = c("moderate", "aggressive", "lazy"), ...) {

  preset <- match.arg(preset)

  base <- list(

    # ---- general --------------------------------------------------------- #
    preset       = preset,
    seed         = 2203L,
    nthread      = 2L,
    verbose      = TRUE,
    objective    = "risk",

    # ---- Stage 0: split -------------------------------------------------- #
    oot_date_col  = NULL,
    holdout_ratio = 0.30,

    # ---- Stage 1: triage ------------------------------------------------- #
    special_values      = -999,
    max_missing         = 0.70,
    near_constant       = 0.995,
    max_cat_levels      = 300L,
    min_iv_quick        = 0.005,
    quick_iv_groups     = 20L,
    check_duplicates    = TRUE,
    special_min_share   = 0.01,
    special_min_woe     = 0.05,
    flag_suffix         = "__sp",
    allow_derived_final = FALSE,

    # ---- Stage 2: binning ------------------------------------------------ #
    min_bins       = 3L,
    max_bins       = 7L,
    algorithm      = "jedi",
    bin_cutoff     = 0.03,
    max_n_prebins  = 30L,
    max_iterations = 1000L,
    bin_separator  = "%;%",

    # ---- Stage 2: screening ---------------------------------------------- #
    iv_min            = 0.02,
    iv_max            = 1.00,
    iv_suspect        = 0.50,
    require_monotonic = "numeric",
    monotonicity      = "weak",
    min_bin_pct       = 0.02,
    screen_min_bins   = 2L,
    allow_degenerate  = FALSE,
    screen_top_n      = NULL,

    # ---- Stage 2: hold-out revalidation ---------------------------------- #
    iv_ratio_min = 0.50,
    psi_max      = 0.25,
    psi_alpha    = 0.05,
    max_unbinned = 0.02,

    # ---- Stage 2: redundancy --------------------------------------------- #
    corr_cutoff = 0.70,
    corr_method = "spearman",

    # ---- Stage 3: classifiers -------------------------------------------- #
    use_glmnet   = TRUE,
    use_xgboost  = TRUE,
    use_ranger   = TRUE,
    use_lightgbm = TRUE,
    cv_folds     = 5L,
    en_alpha     = 0.50,
    xgb_rounds   = 400L,
    xgb_eta      = 0.05,
    xgb_max_depth = 4L,
    xgb_subsample = 0.80,
    xgb_colsample = 0.80,
    xgb_min_child_weight = 20,
    xgb_early_stopping   = 40L,
    rf_trees      = 300L,
    rf_importance = "permutation",
    model_top_k   = 40L,
    model_max_rows = 200000L,

    # ---- Stage 4: consensus ---------------------------------------------- #
    min_votes  = 2L,
    target_min = 10L,
    target_max = 25L,
    weight_by_gini = TRUE,

    # ---- Stages 4-5: scorecard and alignment ----------------------------- #
    base_score    = 600,
    base_odds     = 50,
    pdo           = 20,
    direction     = NULL,
    align_method  = "regression",
    align_bands   = 10L,
    points_style  = "base_plus_deviation",
    points_round  = TRUE,
    challenger    = NULL,
    max_abs_coef  = 15,
    n_boot        = 200L,
    ci_level      = 0.95,
    score_groups  = 10L,

    # ---- Stage 6: cut-off and strategy ----------------------------------- #
    cutoff_n           = 20L,
    reject_multipliers = c(2, 4, 8),
    lab_max_iv_loss    = 0.10,
    lab_min_bin_pct_hard = 0.005,

    # ---- Stage 7: outputs ------------------------------------------------ #
    sql_table        = "your_table",
    sql_dialect      = "ansi",
    sql_output       = "both",
    sql_keep_columns = character()
  )

  tight <- switch(preset,
    aggressive = list(target_max = 15L, min_votes = 3L, corr_cutoff = 0.60, iv_min = 0.03),
    moderate   = list(target_max = 25L, min_votes = 2L, corr_cutoff = 0.70, iv_min = 0.02),
    lazy       = list(target_max = 40L, min_votes = 1L, corr_cutoff = 0.80, iv_min = 0.02)
  )
  cfg <- utils::modifyList(base, tight)

  over <- list(...)
  over <- over[!vapply(over, is.null, logical(1))]
  dup <- unique(names(over)[duplicated(names(over))])
  if (length(dup)) {
    stop("scr_config(): repeated key(s): ", paste(dup, collapse = ", "),
         ". Pass each key once.", call. = FALSE)
  }
  unknown <- setdiff(names(over), names(cfg))
  if (length(unknown)) {
    stop("scr_config(): unknown key(s): ", paste(unknown, collapse = ", "),
         ". Fix the name - a silent override hides dead configuration.", call. = FALSE)
  }
  cfg <- utils::modifyList(cfg, over)
  .scr_validate_config(cfg)
}

#' Validation of the keys that, when wrong, would only blow up stages later
#' @keywords internal
#' @noRd
.scr_validate_config <- function(cfg) {
  cfg$target_min <- max(1L, as.integer(cfg$target_min))
  cfg$target_max <- min(40L, max(cfg$target_min, as.integer(cfg$target_max)))

  if (!cfg$objective %in% c("risk", "propensity")) {
    stop("`objective` must be \"risk\" or \"propensity\" (got \"", cfg$objective, "\").", call. = FALSE)
  }
  if (!is.null(cfg$direction) && !cfg$direction %in% c("higher_is_safer", "higher_is_riskier")) {
    stop("`direction` must be NULL, \"higher_is_safer\" or \"higher_is_riskier\".", call. = FALSE)
  }
  algs <- OptimalBinningWoE::obwoe_algorithms()$algorithm
  if (!identical(cfg$algorithm, "auto") && !cfg$algorithm %in% algs) {
    stop("unknown `algorithm`: \"", cfg$algorithm, "\". See OptimalBinningWoE::obwoe_algorithms().", call. = FALSE)
  }
  if (!cfg$align_method %in% c("regression", "direct")) {
    stop("`align_method` must be \"regression\" or \"direct\".", call. = FALSE)
  }
  if (!cfg$points_style %in% c("base_plus_deviation", "distributed")) {
    stop("`points_style` must be \"base_plus_deviation\" or \"distributed\".", call. = FALSE)
  }
  if (!is.null(cfg$challenger) && !cfg$challenger %in% c("xgboost", "lightgbm")) {
    stop("`challenger` must be NULL, \"xgboost\" or \"lightgbm\".", call. = FALSE)
  }
  .scr_num1(cfg$pdo, "pdo", lower = 0, open_lower = TRUE)
  .scr_num1(cfg$base_odds, "base_odds", lower = 0, open_lower = TRUE)
  .scr_num1(cfg$base_score, "base_score")
  .scr_num1(cfg$holdout_ratio, "holdout_ratio", lower = 0, upper = 1, open_lower = TRUE)
  if (!cfg$sql_output %in% c("woe", "bin", "both")) {
    stop("`sql_output` must be \"woe\", \"bin\" or \"both\".", call. = FALSE)
  }
  cfg$nthread <- max(1L, as.integer(cfg$nthread))
  structure(cfg, class = c("scr_config", "list"))
}

#' Direction of the points scale, resolved
#'
#' An explicit `direction` wins; `NULL` derives it from `objective`.
#' @keywords internal
#' @noRd
resolve_direction <- function(cfg) {
  cfg$direction %||%
    if (identical(cfg$objective, "propensity")) "higher_is_riskier" else "higher_is_safer"
}

#' Report vocabulary under the project convention
#' @keywords internal
#' @noRd
vocab <- function(cfg) {
  if (identical(cfg$objective, "risk")) {
    list(event = "event (undesirable)", target1 = "target = 1 is the BAD case",
         points = "more points = lower probability of the event (safer)", score = "risk")
  } else {
    list(event = "event (desirable)", target1 = "target = 1 is the GOOD case",
         points = "more points = higher probability of the event (more likely)", score = "propensity")
  }
}

#' @export
print.scr_config <- function(x, ...) {
  cat(sprintf("<scr_config> preset \"%s\" | objective \"%s\" | seed %s | threads %d\n\n",
              x$preset, x$objective, x$seed, x$nthread))
  line <- function(lab, val) cat(sprintf("  %-22s %s\n", lab, val))
  v <- vocab(x)
  cat("Convention\n")
  line("target = 1", v$target1)
  line("points scale", sprintf("%s [%s]", v$points, resolve_direction(x)))
  cat("\nFunnel\n")
  line("variables at the end", sprintf("%d to %d", x$target_min, x$target_max))
  line("minimum votes", x$min_votes)
  line("admissible IV", sprintf("[%s, %s)  warning at %s", x$iv_min, x$iv_max, x$iv_suspect))
  line("correlation", sprintf("%s (%s)", x$corr_cutoff, x$corr_method))
  cat("\nBinning\n")
  line("bins", sprintf("%d to %d, algorithm \"%s\"", x$min_bins, x$max_bins, x$algorithm))
  line("monotonicity", sprintf("%s (%s)", x$require_monotonic, x$monotonicity))
  line("smallest bin", fmt_pct(x$min_bin_pct))
  cat("\nScorecard\n")
  line("scale", sprintf("%s points at odds %s:1, PDO %s", x$base_score, x$base_odds, x$pdo))
  line("alignment", sprintf("%s (%d bands)", x$align_method, x$align_bands))
  line("challenger", x$challenger %||% "none")
  line("bootstrap CI", sprintf("%d resamples, %.0f%%", x$n_boot, 100 * x$ci_level))
  cat("\nData\n")
  line("sentinels", if (length(x$special_values)) paste(x$special_values, collapse = ", ") else "(none)")
  line("derived at the end", if (isTRUE(x$allow_derived_final)) "yes" else "no (diagnostic only)")
  line("hold-out", sprintf("%s%s", fmt_pct(x$holdout_ratio),
                           if (!is.null(x$oot_date_col)) sprintf(", OOT by \"%s\"", x$oot_date_col) else ""))
  cat("\nModels\n")
  mods <- c("glmnet", "xgboost", "ranger", "lightgbm")[c(x$use_glmnet, x$use_xgboost, x$use_ranger, x$use_lightgbm)]
  line("enabled", paste(mods, collapse = ", "))
  line("row cap", n_fmt(x$model_max_rows))
  invisible(x)
}

#' Selection presets, side by side
#'
#' Returns the keys a preset changes, resolved, to compare before choosing.
#' Every other configuration key is identical across presets.
#'
#' @return A `data.frame` with one row per preset.
#'
#' @family configuration
#' @examples
#' scr_presets()
#' @export
scr_presets <- function() {
  p <- c("aggressive", "moderate", "lazy")
  do.call(rbind, lapply(p, function(nm) {
    c0 <- scr_config(nm)
    data.frame(preset = nm, target_min = c0$target_min, target_max = c0$target_max,
               min_votes = c0$min_votes, corr_cutoff = c0$corr_cutoff,
               iv_min = c0$iv_min, iv_max = c0$iv_max, stringsAsFactors = FALSE)
  }))
}

#' Dictionary of configuration keys
#'
#' One row per [scr_config()] key, with the stage it acts on, the default
#' value and what it controls.
#'
#' @param stage Optional filter by stage (`0` to `7`). `NULL` returns everything.
#'
#' @return A `data.frame` with `key`, `stage`, `default` and `description`.
#'
#' @family configuration
#' @examples
#' head(scr_config_keys(), 8)
#' scr_config_keys(stage = 5)
#' @export
scr_config_keys <- function(stage = NULL) {
  d <- rbind(
    .ck("preset", 0, "moderate", "Tightness of the selection funnel"),
    .ck("objective", 0, "risk", "Convention: target=1 is an undesirable (risk) or desirable (propensity) event"),
    .ck("seed", 0, "2203", "Seed of everything random"),
    .ck("nthread", 0, "2", "Parallel workers (binning by column, bootstrap, CSI)"),
    .ck("verbose", 0, "TRUE", "Progress messages"),
    .ck("oot_date_col", 0, "NULL", "Date column of the out-of-time cut"),
    .ck("holdout_ratio", 0, "0.30", "Target hold-out fraction"),
    .ck("special_values", 1, "-999", "Business sentinels"),
    .ck("max_missing", 1, "0.70", "Ceiling of missing+sentinel share for a numeric"),
    .ck("near_constant", 1, "0.995", "Mode dominance that fails"),
    .ck("max_cat_levels", 1, "300", "Maximum categorical cardinality"),
    .ck("min_iv_quick", 1, "0.005", "Noise floor of the coarse IV"),
    .ck("quick_iv_groups", 1, "20", "Quantiles of the coarse IV"),
    .ck("check_duplicates", 1, "TRUE", "Detect identical columns"),
    .ck("special_min_share", 1, "0.01", "Minimum mass to create the flag"),
    .ck("special_min_woe", 1, "0.05", "Minimum |WOE| to create the flag"),
    .ck("flag_suffix", 1, "__sp", "Suffix of the special-population flag"),
    .ck("allow_derived_final", 1, "FALSE", "A derived flag may enter the deliverable"),
    .ck("min_bins", 2, "3", "Bins requested from the algorithm"),
    .ck("max_bins", 2, "7", "Maximum bins requested from the algorithm"),
    .ck("algorithm", 2, "jedi", "Binning algorithm (see obwoe_algorithms())"),
    .ck("bin_cutoff", 2, "0.03", "Minimum fraction per bin inside the algorithm"),
    .ck("max_n_prebins", 2, "30", "Pre-bins; strongly affects numerics"),
    .ck("max_iterations", 2, "1000", "Maximum optimiser iterations"),
    .ck("bin_separator", 2, "%;%", "Separator of merged categories"),
    .ck("iv_min", 2, "0.02", "IV admission floor"),
    .ck("iv_max", 2, "1.00", "IV admission ceiling (leakage)"),
    .ck("iv_suspect", 2, "0.50", "Threshold of the suspicious-IV warning"),
    .ck("require_monotonic", 2, "numeric", "Where monotonicity is required"),
    .ck("monotonicity", 2, "weak", "Monotonicity strictness"),
    .ck("min_bin_pct", 2, "0.02", "Minimum population of the smallest bin"),
    .ck("screen_min_bins", 2, "2", "Structural floor of bins at admission"),
    .ck("allow_degenerate", 2, "FALSE", "Accept a single-class bin"),
    .ck("screen_top_n", 2, "NULL", "Ranking cut at screening"),
    .ck("iv_ratio_min", 2, "0.50", "Minimum hold-out IV / train IV"),
    .ck("psi_max", 2, "0.25", "Maximum fixed PSI between train and hold-out"),
    .ck("psi_alpha", 2, "0.05", "Alpha of the n-adjusted PSI threshold"),
    .ck("max_unbinned", 2, "0.02", "Tolerated fraction of hold-out without a bin"),
    .ck("corr_cutoff", 2, "0.70", "Correlation that defines redundancy"),
    .ck("corr_method", 2, "spearman", "Correlation method (rank)"),
    .ck("use_glmnet", 3, "TRUE", "Elastic net as a voter"),
    .ck("use_xgboost", 3, "TRUE", "XGBoost as a voter (required by the package)"),
    .ck("use_ranger", 3, "TRUE", "Random forest as a voter"),
    .ck("use_lightgbm", 3, "TRUE", "LightGBM if installed"),
    .ck("cv_folds", 3, "5", "Cross-validation folds of glmnet"),
    .ck("en_alpha", 3, "0.50", "Elastic net alpha"),
    .ck("xgb_rounds", 3, "400", "Maximum boosting trees"),
    .ck("xgb_eta", 3, "0.05", "Boosting learning rate"),
    .ck("xgb_max_depth", 3, "4", "Maximum tree depth"),
    .ck("xgb_subsample", 3, "0.80", "Row fraction per tree"),
    .ck("xgb_colsample", 3, "0.80", "Column fraction per tree"),
    .ck("xgb_min_child_weight", 3, "20", "Minimum weight per leaf"),
    .ck("xgb_early_stopping", 3, "40", "Rounds without hold-out improvement"),
    .ck("rf_trees", 3, "300", "Random forest trees"),
    .ck("rf_importance", 3, "permutation", "Random forest importance type"),
    .ck("model_top_k", 3, "40", "Top-K of each model that counts as a vote"),
    .ck("model_max_rows", 3, "200000", "Row cap for the classifiers"),
    .ck("min_votes", 4, "2", "Minimum votes to enter the shortlist"),
    .ck("target_min", 4, "10", "Floor of variables at the end"),
    .ck("target_max", 4, "25", "Ceiling of variables at the end"),
    .ck("weight_by_gini", 4, "TRUE", "Weight votes by hold-out Gini"),
    .ck("base_score", 5, "600", "Reference score of the scale"),
    .ck("base_odds", 5, "50", "Odds at the reference score (in the orientation of direction)"),
    .ck("pdo", 5, "20", "Points to double the odds"),
    .ck("direction", 5, "NULL", "Scale direction; NULL derives it from objective"),
    .ck("align_method", 5, "regression", "regression (bands + ln(odds) ~ raw) or direct"),
    .ck("align_bands", 5, "10", "Bands of the alignment regression"),
    .ck("points_style", 5, "base_plus_deviation", "Points: base + deviation, or distributed intercept"),
    .ck("points_round", 5, "TRUE", "Round points per bin"),
    .ck("challenger", 5, "NULL", "Tree challenger (xgboost/lightgbm), without points"),
    .ck("max_abs_coef", 5, "15", "Maximum absolute glm coefficient tolerated"),
    .ck("n_boot", 5, "200", "Bootstrap CI resamples (always computed)"),
    .ck("ci_level", 5, "0.95", "CI level"),
    .ck("score_groups", 5, "10", "Bands of the score gains"),
    .ck("cutoff_n", 6, "20", "Candidate cuts of the sweep"),
    .ck("reject_multipliers", 6, "2, 4, 8", "Sensitivity band of reject inference"),
    .ck("lab_max_iv_loss", 6, "0.10", "Coarse classing: advisory hold-out IV loss vs optimal"),
    .ck("lab_min_bin_pct_hard", 6, "0.005", "Coarse classing: blocking floor of a manual bin share"),
    .ck("sql_table", 7, "your_table", "Source table in the generated SQL"),
    .ck("sql_dialect", 7, "ansi", "Dialect of the generated SQL"),
    .ck("sql_output", 7, "both", "Emit WOE, BIN or both"),
    .ck("sql_keep_columns", 7, "character(0)", "Key columns carried untransformed")
  )
  if (!is.null(stage)) d <- d[d$stage %in% stage, , drop = FALSE]
  rownames(d) <- NULL
  d
}

#' @keywords internal
#' @noRd
.ck <- function(key, stage, default, description) {
  data.frame(key = key, stage = stage, default = default, description = description,
             stringsAsFactors = FALSE)
}

#' Binning control derived from the configuration
#'
#' A single point of truth: the Stage 2 fit and everything that reapplies
#' the bins read from here, which guarantees the cut points are the same.
#' @keywords internal
#' @noRd
obwoe_control <- function(cfg) {
  OptimalBinningWoE::control.obwoe(
    bin_cutoff     = cfg$bin_cutoff,
    max_n_prebins  = cfg$max_n_prebins,
    max_iterations = cfg$max_iterations,
    bin_separator  = cfg$bin_separator,
    verbose        = FALSE
  )
}

#' @keywords internal
#' @noRd
check_config <- function(config, fn) {
  if (!inherits(config, "scr_config")) {
    stop(sprintf("%s(): `config` must come from scr_config().", fn), call. = FALSE)
  }
  invisible(TRUE)
}
