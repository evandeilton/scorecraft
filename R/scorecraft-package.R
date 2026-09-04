#' scorecraft: scorecard engine with alignment, cut-off strategy and production SQL
#'
#' A professional scorecard is born of seven chained stages, and this package
#' exposes each of them as a function of its own, next to the shortcut
#' [scr_select()] that chains them for the common case:
#'
#' \enumerate{
#'   \item **Split** ([scr_split()]): train/hold-out by whole periods
#'     (out-of-time) before any supervised fit.
#'   \item **Triage** ([scr_triage()]): structural filters, decomposition of
#'     sentinels and missing values, exact duplicates. The data leaves with no
#'     `NA`.
#'   \item **Binning and screening** ([scr_bin()]): optimal bins parallelised
#'     by column, eight admission rules, hold-out revalidation with frozen
#'     bins, redundancy pruning.
#'   \item **Multi-strategy selection** ([scr_model()]): elastic net, boosting
#'     and random forest on the WOE space; consensus weighted by hold-out Gini.
#'   \item **Scorecard** ([scr_scorecard()]): logistic regression on the
#'     shortlist, sign check, points per bin, a tree challenger explicitly
#'     without points.
#'   \item **Alignment** ([scr_align()]): log-odds regression on the raw score
#'     composed with the PDO map, with `odds_orientation` recorded. Runs
#'     automatically inside [scr_scorecard()].
#'   \item **Cut-off and strategy** ([scr_cutoff()], [scr_strategy()],
#'     [scr_reject()]): sweep with frozen cuts, bands with marginal expected
#'     profit, honest reject inference through a sensitivity band.
#' }
#'
#' The deliverables ([scr_export()]) are the audit funnel, the gains tables,
#' the production SQL ([scr_sql()]) with R-SQL equivalence verified by test,
#' and four `.xlsx` workbooks. [scr_monitor()] recomputes PSI/CSI on new data,
#' with both the fixed and the sample-size-adjusted threshold, and never
#' schedules anything by itself.
#'
#' @section Reading conventions:
#'
#' `objective` declares the vocabulary and the direction of the scale
#' (`"risk"`: more points, safer; `"propensity"`: more points, more likely)
#' and does **not** change what is modelled. `event_level` changes what is
#' modelled. Both are documented in [scr_config()] and [scr_split()].
#'
#' @keywords internal
#' @importFrom data.table := .N .SD as.data.table copy data.table dcast fcase
#'   fifelse rbindlist set setDT setcolorder setnames setorder setorderv uniqueN
#' @importFrom stats coef glm binomial median quantile sd predict qchisq qnorm
#'   plogis qlogis pbinom setNames lm weighted.mean
#' @importFrom utils head modifyList packageVersion
"_PACKAGE"

## data.table: this package knows how to use `[.data.table`
.datatable.aware <- TRUE

## silence the "no visible binding" NOTE for columns used inside `[.data.table`
utils::globalVariables(c(
  ".", "feature", "error", "selected", "reason", "N", "triage_status",
  "triage_reason", "holdout_ok", "holdout_reason", "iv_holdout", "approved",
  "exit_stage", "consensus_rank", "total_iv", "iv_suspect", "screen_reason",
  "screen_selected", "bin_error", "prune_status", "prune_corr_with", "prune_corr",
  "consensus_selected", "consensus_reason", "votes", "consensus_score",
  "vote", "importance", "score_pct", "weight", "model", "gini",
  "kind", "source", "output", "impute_value", "derived_from", "corr_with", "corr",
  "i.corr_with", "i.corr", "i.of", "of", "band", "y", "s", "n1", "n0", "psi",
  "psi_flag", "pct_unbinned", "iv_train_bins", "iv_ratio", "variable", "bin",
  "points", "woe", "points_raw", "n", "events", "score", "cum_pct", "period",
  "sample", "target", "pos", "n_targets", "mean_rank", "bin_id", "type", "id",
  "n_bins", "ks", "auc", "count", "event_rate", "cut", "decision", "n_pos",
  "pct", "csi", "shift", "level", "pct_base", "pct_compare", "value",
  "iv_quick", "in_model", "n_events", "n_total", "keep", "action", "ln_odds",
  "ln_odds_fit", "raw_mean", "w", "non_events", "cum_event_pct",
  "cum_nonevent_pct", "lift", "cum_lift", "odds", "log_odds", "gap", "prev_rate",
  "monotone", "p_value", "break_flag", "date", "score_points", "min_score",
  "max_score", "mean_score", "ep_per_account", "band_profit", "cum_event_rate",
  "cum_profit", "n_dev", "events_dev", "rate_dev", "n_pop", "n_unknown",
  "coverage", "coverage_flag", "multiplier", "rate_unknown", "events_implied",
  "rate_implied", "points_shift", "Feature", "Gain", ".tmp", ".linha", ".i",
  "i.corr_com", "n_vote", "count_train", "pct_train", "observed", "expected",
  "psi_critical", "psi_flag_adjusted", "provenance", "manual_reason", "pct_shift",
  "pct_holdout", "current", "metric", "optimal", "manual", "delta", "blocking"
))
