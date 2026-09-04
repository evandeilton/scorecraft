# ============================================================================ #
# monitor.R - PSI/CSI over time (D19: exported, never runs by itself)
# ============================================================================ #

#' Monitor the scorecard on new data
#'
#' Recomputes, per period of `date_col` (or for the whole data), the score
#' PSI against train with frozen bands, the CSI of every variable with
#' frozen bins plus the signed points shift and, when the target is
#' present, the performance by vintage (event rate, AUC/KS/Gini with CI).
#' Always reports both thresholds (fixed and n-adjusted, D17). Schedules
#' nothing: the analyst calls it when needed (D19).
#'
#' @param x An object from [scr_scorecard()].
#' @param newdata New table with the source columns.
#' @param date_col Period column. `NULL` treats `newdata` as a single period.
#' @param target Target column in `newdata`, for the performance by vintage.
#'   `NULL` skips it.
#' @param alpha Level of the adjusted threshold.
#' @param n_boot CI resamples per vintage. `NULL` uses the configuration.
#'
#' @return An `scr_monitor` object with `psi` (score, per period), `csi`
#'   (per variable and period), `vintage` (or `NULL`) and `plan` (the
#'   monitoring contract: thresholds and frozen bands).
#'
#' @family stages
#' @examples
#' cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
#'                   xgb_rounds = 60, n_boot = 20)
#' res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
#'                   date_col = "ref_date")
#' sc <- scr_scorecard(res)
#' mo <- scr_monitor(sc, scr_demo, date_col = "ref_date", target = "default")
#' mo
#' mo$psi
#' head(mo$csi)
#' @export
scr_monitor <- function(x, newdata, date_col = NULL, target = NULL, alpha = 0.05, n_boot = NULL) {
  check_scorecard(x, "scr_monitor")
  n_boot <- n_boot %||% x$config$n_boot
  dt <- data.table::as.data.table(newdata)
  if (!is.null(date_col) && !date_col %in% names(dt)) stop("`date_col` does not exist in newdata.", call. = FALSE)
  if (!is.null(target) && !target %in% names(dt)) stop("`target` does not exist in newdata.", call. = FALSE)
  base <- .scr_preprocess(dt, x$ledger, x$features, x$config$special_values)
  w <- apply_woe(x$fit, base, x$features, "both")
  link <- .glm_link(x$coef, w, x$features)
  score <- x$alignment$a + x$alignment$b * link
  period <- if (is.null(date_col)) rep("all", nrow(dt)) else as.character(dt[[date_col]])
  periods <- sort(unique(period))
  tr_score <- x$samples$train$score

  psi <- data.table::rbindlist(lapply(periods, function(p) {
    i <- period == p
    r <- scr_psi(tr_score, score[i], breaks = x$breaks, alpha = alpha)
    data.table::data.table(period = p, n = sum(i), mean_score = mean(score[i]), psi = r$psi,
                           flag_fixed = r$flag_fixed, critical = r$critical, flag_adjusted = r$flag_adjusted)
  }))
  csi <- data.table::rbindlist(lapply(periods, function(p) {
    i <- period == p
    data.table::rbindlist(lapply(x$features, function(f) {
      pt <- x$points[variable == f]
      cb <- paste0(f, "_bin")
      # the base distribution is the training bin share stored in the points
      # table; the adjusted critical value uses the real training size
      cmp <- tabulate(match(w[[cb]][i], pt$bin), nbins = nrow(pt))
      n_new <- sum(cmp); n_tr <- sum(pt$count_train)
      csi_v <- if (n_new > 0L) {
        sm <- if (any(pt$count_train == 0L) || any(cmp == 0L)) 0.5 else 0
        pb <- (pt$count_train + sm) / (n_tr + sm * nrow(pt)); pc <- (cmp + sm) / (n_new + sm * nrow(pt))
        sum((pb - pc) * log(pb / pc))
      } else NA_real_
      crit <- (1 / n_tr + 1 / max(1L, n_new)) * stats::qchisq(1 - alpha, df = max(1L, nrow(pt) - 1L))
      data.table::data.table(
        period = p, variable = f, n = n_new, csi = csi_v,
        flag_fixed = if (is.na(csi_v)) NA_character_ else if (csi_v < 0.10) "stable" else if (csi_v < 0.25) "moderate" else "shift",
        critical = crit,
        flag_adjusted = if (is.na(csi_v)) NA_character_ else if (csi_v < crit) "stable" else "shift",
        points_shift = if (n_new > 0L) .points_shift(pt$count_train / n_tr, cmp / n_new, pt$points) else NA_real_)
    }))
  }))
  vintage <- NULL
  if (!is.null(target)) {
    y <- .target_as_int(dt[[target]], target, if (isTRUE(x$event$inverted)) 0L else NULL)$y
    hie <- identical(x$direction, "higher_is_riskier")
    vintage <- data.table::rbindlist(lapply(periods, function(p) {
      i <- period == p
      m <- scr_metrics(score[i], y[i], higher_is_event = hie, ci = TRUE, n_boot = n_boot,
                       level = x$config$ci_level, seed = x$config$seed, nthread = x$config$nthread)
      data.table::data.table(period = p, n = sum(i), events = sum(y[i]), event_rate = mean(y[i]),
                             mean_score = mean(score[i]), auc = m$auc, auc_lo = m$auc_lo, auc_hi = m$auc_hi,
                             ks = m$ks, ks_lo = m$ks_lo, ks_hi = m$ks_hi, gini = m$gini)
    }))
  }
  plan <- data.table::data.table(
    item = c("psi_score_fixed_moderate", "psi_score_fixed_action", "psi_adjusted_alpha", "csi_variable_fixed_moderate",
             "csi_variable_fixed_action", "score_bands", "min_events_per_period", "threshold_source"),
    value = c("0.10", "0.25", as.character(alpha), "0.10", "0.25", paste(round(x$breaks[is.finite(x$breaks)], 2), collapse = " | "),
              "100", "0.10/0.25: market convention, no published authority; adjusted: Yurdakul & Naranjo (2020)"))
  structure(list(psi = psi[], csi = csi[], vintage = vintage, plan = plan, periods = periods, target = x$target),
            class = c("scr_monitor", "list"))
}

#' @export
print.scr_monitor <- function(x, ...) {
  cat(sprintf("<scr_monitor> target \"%s\" | %d period(s)\n", x$target, length(x$periods)))
  cat(sprintf("  %-12s %8s %10s %8s %-9s %9s %-8s\n", "period", "n", "score", "PSI", "fixed", "critical", "adj."))
  p <- x$psi
  for (i in seq_len(nrow(p))) cat(sprintf("  %-12s %8s %10.1f %8.4f %-9s %9.4f %-8s\n", p$period[i], n_fmt(p$n[i]), p$mean_score[i],
                                          p$psi[i], p$flag_fixed[i], p$critical[i], p$flag_adjusted[i]))
  top <- x$csi[order(-abs(points_shift))][seq_len(min(5L, nrow(x$csi)))]
  if (nrow(top)) {
    cat("  largest points shifts (variable @ period):\n")
    for (i in seq_len(nrow(top))) cat(sprintf("    %-28s %-12s CSI %.4f  shift %+.2f pts\n", top$variable[i], top$period[i], top$csi[i], top$points_shift[i]))
  }
  if (!is.null(x$vintage)) {
    v <- x$vintage
    cat("  performance by vintage:\n")
    for (i in seq_len(nrow(v))) cat(sprintf("    %-12s n %-7s event %6.2f%%  AUC %.4f [%.4f, %.4f]  KS %.4f\n", v$period[i], n_fmt(v$n[i]),
                                            100 * v$event_rate[i], v$auc[i], v$auc_lo[i], v$auc_hi[i], v$ks[i]))
  }
  invisible(x)
}
