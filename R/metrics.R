# ============================================================================ #
# metrics.R - discrimination (AUC/KS/Gini with CI), IV and adjusted PSI
# ============================================================================ #

#' AUC, KS and Gini of a score, with a bootstrap confidence interval
#'
#' AUC through the Mann-Whitney U statistic with tie correction, computed on
#' the table of counts per unique score: a WOE score is constant within the
#' bin, so ties are the rule. Everything in `double` on purpose: with integer
#' counts, `n1 * n0` overflows `2^31` from about 46 thousand observations per
#' class and returns `NA`.
#'
#' The confidence interval is **always** computed by default (project
#' decision D18): a bootstrap stratified by outcome, percentile method, with
#' `n_boot` resamples. Gini is derived from AUC (`2 * AUC - 1`) inside each
#' resample, never bootstrapped separately. The cost is absorbed by
#' `nthread` (parallelism by resample).
#'
#' @param score Numeric vector with the score.
#' @param y 0/1 outcome vector, same length as `score`.
#' @param higher_is_event If `TRUE` (default), a higher score means a higher
#'   probability of the event (logit, probability, propensity score). Pass
#'   `FALSE` for a credit points score (`higher_is_safer`), and the AUC is
#'   reported above 0.5 when the score ranks correctly.
#' @param ci Compute the confidence interval. `FALSE` returns point estimates only.
#' @param n_boot Number of bootstrap resamples.
#' @param level Confidence level.
#' @param seed Bootstrap seed; `NULL` leaves it unset.
#' @param nthread Parallel workers for the resamples.
#'
#' @return A list of class `scr_metrics` with `auc`, `ks`, `gini`, the
#'   bounds `auc_lo`/`auc_hi`, `ks_lo`/`ks_hi`, `gini_lo`/`gini_hi` (`NA`
#'   when `ci = FALSE`), `n`, `events`, `n_boot` and `level`. Everything is
#'   `NA_real_` when only one class is present or no valid case exists.
#'
#' @references
#' DeLong, E. R., DeLong, D. M. and Clarke-Pearson, D. L. (1988). Comparing
#' the areas under two or more correlated receiver operating characteristic
#' curves. *Biometrics*, 44(3), 837-845.
#'
#' @family metrics
#' @examples
#' set.seed(1)
#' y <- rep(0:1, each = 500)
#' s <- stats::rnorm(1000) + 0.8 * y
#' m <- scr_metrics(s, y, n_boot = 50, seed = 1)
#' m
#' as.data.frame(m)
#' @export
scr_metrics <- function(score, y, higher_is_event = TRUE, ci = TRUE, n_boot = 200L,
                        level = 0.95, seed = NULL, nthread = 1L) {
  empty <- list(auc = NA_real_, ks = NA_real_, gini = NA_real_,
                auc_lo = NA_real_, auc_hi = NA_real_, ks_lo = NA_real_, ks_hi = NA_real_,
                gini_lo = NA_real_, gini_hi = NA_real_, n = 0L, events = 0L,
                n_boot = 0L, level = level)
  if (length(score) != length(y)) stop("`score` and `y` must have the same length.", call. = FALSE)
  ok <- is.finite(score) & !is.na(y)
  if (!any(ok)) return(structure(empty, class = c("scr_metrics", "list")))
  score <- as.double(score[ok]); y <- as.integer(y[ok])
  if (!isTRUE(higher_is_event)) score <- -score
  n1 <- sum(y == 1L); n0 <- sum(y == 0L)
  if (n1 == 0L || n0 == 0L) {
    empty$n <- length(y); empty$events <- n1
    return(structure(empty, class = c("scr_metrics", "list")))
  }

  pt <- .auc_ks(score, y)
  out <- empty
  out$auc <- pt$auc; out$ks <- pt$ks; out$gini <- pt$gini
  out$n <- length(y); out$events <- n1

  if (isTRUE(ci) && n_boot >= 2L) {
    i1 <- which(y == 1L); i0 <- which(y == 0L)
    if (!is.null(seed)) set.seed(seed)
    # The seed of every resample is drawn HERE, in the main process, so the
    # result is identical with 1 or N workers.
    seeds <- sample.int(.Machine$integer.max, n_boot)
    reps <- .scr_lapply(seeds, function(sd) {
      set.seed(sd)
      j <- c(i1[sample.int(n1, n1, replace = TRUE)], i0[sample.int(n0, n0, replace = TRUE)])
      r <- .auc_ks(score[j], y[j])
      c(r$auc, r$ks)
    }, nthread = nthread)
    b <- do.call(rbind, reps)
    a <- (1 - level) / 2
    q_auc <- stats::quantile(b[, 1], c(a, 1 - a), na.rm = TRUE, names = FALSE)
    q_ks  <- stats::quantile(b[, 2], c(a, 1 - a), na.rm = TRUE, names = FALSE)
    out$auc_lo <- q_auc[1]; out$auc_hi <- q_auc[2]
    out$ks_lo <- q_ks[1];   out$ks_hi <- q_ks[2]
    out$gini_lo <- 2 * q_auc[1] - 1; out$gini_hi <- 2 * q_auc[2] - 1
    out$n_boot <- as.integer(n_boot)
  }
  structure(out, class = c("scr_metrics", "list"))
}

#' AUC/KS core without validation (called inside the bootstrap)
#' @keywords internal
#' @noRd
.auc_ks <- function(score, y) {
  n1 <- as.double(sum(y == 1L)); n0 <- as.double(sum(y == 0L))
  d <- data.table::data.table(s = score, y = y)[
    , .(n1 = as.double(sum(y == 1L)), n0 = as.double(sum(y == 0L))), by = s][order(s)]
  cum0 <- cumsum(d$n0)
  auc  <- sum(d$n1 * (cum0 - d$n0 + d$n0 / 2)) / (n1 * n0)
  ks   <- max(abs(cumsum(d$n1) / n1 - cum0 / n0))
  list(auc = auc, ks = ks, gini = 2 * auc - 1)
}

#' @export
print.scr_metrics <- function(x, ...) {
  ci <- function(v, lo, hi) {
    if (is.na(v)) return("-")
    if (is.na(lo)) sprintf("%.4f", v) else sprintf("%.4f [%.4f, %.4f]", v, lo, hi)
  }
  cat(sprintf("<scr_metrics> n = %s | events = %s%s\n", n_fmt(x$n), n_fmt(x$events),
              if (x$n_boot > 0) sprintf(" | %.0f%% bootstrap CI (%d resamples)",
                                        100 * x$level, x$n_boot) else ""))
  cat(sprintf("  AUC  %s\n  KS   %s\n  Gini %s\n",
              ci(x$auc, x$auc_lo, x$auc_hi), ci(x$ks, x$ks_lo, x$ks_hi),
              ci(x$gini, x$gini_lo, x$gini_hi)))
  invisible(x)
}

#' @export
as.data.frame.scr_metrics <- function(x, ...) {
  as.data.frame(unclass(x)[c("n", "events", "auc", "auc_lo", "auc_hi", "ks", "ks_lo",
                             "ks_hi", "gini", "gini_lo", "gini_hi", "n_boot", "level")],
                stringsAsFactors = FALSE)
}

# -- Information Value ------------------------------------------------------ #

#' Information Value of any grouping
#'
#' Laplace smoothing by default. It is not cosmetic: without it, a
#' single-class group (a normal situation in a small sentinel population)
#' yields `Inf` and contaminates any ordering that depends on the IV.
#'
#' Implemented with [tabulate()] on integer codes rather than `data.table`
#' aggregation: this function is called once per candidate variable, hundreds
#' of times per run, and the fixed cost dominated the triage.
#'
#' @param g Group vector (any coercible type; `NA` is ignored).
#' @param y 0/1 outcome vector.
#' @param laplace Smoothing constant added to each count. `0` switches it off.
#'
#' @return Total IV, a scalar. Zero when fewer than two groups are populated.
#'
#' @family metrics
#' @examples
#' set.seed(1)
#' y <- stats::rbinom(1000, 1, 0.3)
#' g <- ifelse(stats::runif(1000) < 0.5 + 0.3 * y, "A", "B")
#' scr_iv(g, y)
#' @export
scr_iv <- function(g, y, laplace = 0.5) {
  gi <- if (is.integer(g) && min(g, na.rm = TRUE) >= 1L) g else match(g, unique(g))
  k  <- suppressWarnings(max(gi, na.rm = TRUE))
  if (!is.finite(k) || k < 2L) return(0)
  y  <- as.integer(y)
  np <- tabulate(gi[y == 1L], nbins = k)
  nn <- tabulate(gi[y == 0L], nbins = k)
  live <- (np + nn) > 0L
  if (sum(live) < 2L) return(0)
  np <- np[live]; nn <- nn[live]
  p <- (np + laplace) / sum(np + laplace)
  q <- (nn + laplace) / sum(nn + laplace)
  sum((p - q) * log(p / q))
}

#' WOE of a subpopulation against the rest
#' @keywords internal
#' @noRd
woe_subpop <- function(mask, y, laplace = 0.5) {
  y <- as.integer(y)
  n1 <- sum(y == 1L); n0 <- sum(y == 0L)
  if (n1 == 0L || n0 == 0L) return(0)
  s1 <- sum(y[mask] == 1L); s0 <- sum(y[mask] == 0L)
  log(((s1 + laplace) / (n1 + 2 * laplace)) / ((s0 + laplace) / (n0 + 2 * laplace)))
}

# -- PSI / CSI with adjusted threshold -------------------------------------- #

#' Population stability index, with the fixed and the sample-size-adjusted threshold
#'
#' `PSI = sum((p - q) * ln(p / q))` over bins frozen on the base. Reports
#' both thresholds side by side (project decision D17): the traditional fixed
#' one (`< 0.10` stable, `0.10-0.25` moderate, `>= 0.25` act) and the
#' sample-size-adjusted critical value of Yurdakul and Naranjo (2020), under
#' which the PSI is asymptotically `(1/n + 1/m) * chi-squared(B - 1)`. With
#' `n = m = 1000` and ten bins the 5% critical value is 0.034, not 0.10; on a
#' monthly base of a hundred thousand rows, `PSI = 0.01` is already
#' significant. The fixed threshold remains what the market knows; the
#' adjusted one is what the statistics support.
#'
#' @param base Reference vector (the "development" distribution).
#' @param compare Vector to compare.
#' @param levels For categorical vectors: the levels to consider. `NULL`
#'   uses the union of the observed ones.
#' @param breaks For numeric vectors: frozen cut points. `NULL` derives
#'   `n_groups` quantiles of `base`.
#' @param n_groups Number of bands when `breaks = NULL`.
#' @param alpha Significance level of the adjusted threshold.
#' @param thresholds The two fixed thresholds (moderate, act).
#'
#' @return A list of class `scr_psi` with `psi`, `flag_fixed`, `critical`
#'   (adjusted critical value), `flag_adjusted` (`"stable"` or `"shift"`),
#'   `n_base`, `n_compare`, `n_bins` and `table` (per band: `pct_base`,
#'   `pct_compare`, `psi_band`).
#'
#' @references
#' Yurdakul, B. and Naranjo, J. (2020). Statistical properties of the
#' population stability index. *Journal of Risk Model Validation*, 14(4),
#' 89-100.
#'
#' @family metrics
#' @examples
#' set.seed(2)
#' base <- stats::rnorm(5000)
#' new  <- stats::rnorm(5000, mean = 0.15)
#' p <- scr_psi(base, new)
#' p
#' p$table
#' @export
scr_psi <- function(base, compare, levels = NULL, breaks = NULL, n_groups = 10L,
                    alpha = 0.05, thresholds = c(0.10, 0.25)) {
  if (is.numeric(base) && is.numeric(compare) && is.null(levels)) {
    if (is.null(breaks)) {
      probs  <- seq(0, 1, length.out = n_groups + 1L)[-c(1L, n_groups + 1L)]
      breaks <- unique(c(-Inf, stats::quantile(base, probs = probs, na.rm = TRUE, names = FALSE), Inf))
    }
    gb <- cut(base, breaks = breaks, include.lowest = TRUE)
    gc <- cut(compare, breaks = breaks, include.lowest = TRUE)
    lv <- levels(gb)
  } else {
    gb <- as.character(base); gc <- as.character(compare)
    lv <- levels %||% sort(union(unique(gb[!is.na(gb)]), unique(gc[!is.na(gc)])))
  }
  nb <- tabulate(match(gb, lv), nbins = length(lv))
  nc <- tabulate(match(gc, lv), nbins = length(lv))
  n <- sum(nb); m <- sum(nc); B <- length(lv)
  if (n == 0L || m == 0L || B < 2L) {
    return(structure(list(psi = NA_real_, flag_fixed = NA_character_, critical = NA_real_,
                          flag_adjusted = NA_character_, n_base = n, n_compare = m,
                          n_bins = B, alpha = alpha, table = NULL), class = c("scr_psi", "list")))
  }
  # empty bins on one side: minimal smoothing only when a zero exists, so the
  # PSI of populated bands is left untouched
  smooth <- if (any(nb == 0L) || any(nc == 0L)) 0.5 else 0
  p <- (nb + smooth) / (n + smooth * B)
  q <- (nc + smooth) / (m + smooth * B)
  band <- (p - q) * log(p / q)
  psi <- sum(band)
  crit <- (1 / n + 1 / m) * stats::qchisq(1 - alpha, df = B - 1L)
  flag_fixed <- if (psi < thresholds[1]) "stable" else if (psi < thresholds[2]) "moderate" else "shift"
  structure(list(
    psi = psi, flag_fixed = flag_fixed, critical = crit,
    flag_adjusted = if (psi < crit) "stable" else "shift",
    n_base = n, n_compare = m, n_bins = B, alpha = alpha,
    table = data.frame(band = lv, n_base = nb, n_compare = nc, pct_base = nb / n,
                       pct_compare = nc / m, psi_band = band, stringsAsFactors = FALSE)
  ), class = c("scr_psi", "list"))
}

#' @export
print.scr_psi <- function(x, ...) {
  if (is.na(x$psi)) { cat("<scr_psi> undefined (insufficient sample or bands)\n"); return(invisible(x)) }
  cat(sprintf("<scr_psi> PSI = %.4f | bands = %d | n = %s vs %s\n", x$psi, x$n_bins,
              n_fmt(x$n_base), n_fmt(x$n_compare)))
  cat(sprintf("  fixed threshold (0.10/0.25):       %s\n", x$flag_fixed))
  cat(sprintf("  n-adjusted threshold (%.4f):     %s  [Yurdakul & Naranjo, alpha = %.2f]\n",
              x$critical, x$flag_adjusted, x$alpha))
  invisible(x)
}

#' Signed points shift of a variable
#'
#' `sum((q - p) * points)`: how much the change in bin distribution moved the
#' mean score, and in which direction. Additive across variables, unlike the
#' CSI, and answers "which variable moved the score".
#' @keywords internal
#' @noRd
.points_shift <- function(pct_base, pct_compare, points) {
  sum((pct_compare - pct_base) * points)
}
