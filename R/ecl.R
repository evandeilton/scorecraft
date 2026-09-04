# ============================================================================ #
# ecl.R - expected credit loss in discrete time (12-month and lifetime)
# ============================================================================ #
# Survival-weighted sum of marginal monthly hazards times LGD and EAD,
# discounted at the effective interest rate, over probability-weighted
# scenarios; stage allocation from days past due and the PD deterioration
# ratio when the caller does not supply it.
# ============================================================================ #

#' Expected credit loss with stage allocation
#'
#' Discrete-time expected credit loss of every exposure:
#'
#' \deqn{ECL_H = \sum_{t=1}^{H} S(t-1)\, h_t\, LGD_t\, EAD_t\, (1+r)^{-t/12}, \qquad S(t) = \prod_{s \le t}(1 - h_s - p_s)}
#'
#' with `h_t` the marginal monthly default hazard, `p_t` an optional
#' prepayment hazard and `r` the annual effective interest rate
#' (`config$ecl_discount = "none"` switches the discounting off). The
#' 12-month figure uses `H = config$ecl_horizon_months`, the lifetime figure
#' the full term `T`. Stage 1 exposures carry the 12-month loss, stages 2
#' and 3 the lifetime loss; stage 3 exposures are credit-impaired and carry
#' `LGD_1 * EAD_1`. When `stage` is `NULL` the rule is: stage 3 if `dpd >=
#' config$ecl_stage_dpd[2]`, stage 2 if `dpd >= config$ecl_stage_dpd[1]` or
#' the 12-month PD now over the one at origination (`pd_orig`) is at least
#' `config$ecl_sicr_ratio`, else stage 1.
#'
#' Scenarios are a named list of shocks applied to the base inputs, each a
#' list with any of `pd_mult` (multiplier of the hazards, capped at one),
#' `z` (systematic factor of the one-factor model applied to the hazards
#' with correlation `rho`, negative in a bad year), `lgd_add` (added to the
#' LGD) and `ead_mult`; `weights` (normalised to one) give the
#' probability-weighted result.
#'
#' @param pd_term Marginal monthly PDs: a matrix `n x T`, or a vector of
#'   length `n` (a flat hazard recycled over `t_max` months), or a single
#'   number.
#' @param lgd,ead Vectors of length `n` (or one) or matrices `n x T`.
#' @param eir Annual effective interest rate, vector of length `n` or one.
#' @param stage Optional stage vector (1, 2, 3); `NULL` applies the rule.
#' @param dpd Days past due (the rule); optional.
#' @param pd_orig 12-month PD at origination (the rule); optional.
#' @param scenarios Named list of scenario shocks (see Details); `NULL`
#'   runs the base case only.
#' @param weights Scenario weights; equal when `NULL`.
#' @param prepay Monthly prepayment hazard: `NULL`, a vector or an `n x T`
#'   matrix.
#' @param rho Asset correlation used by scenario shocks with `z`.
#' @param t_max Term in months when `pd_term` is a vector (default
#'   `config$ecl_horizon_months`).
#' @param segment Optional character vector of length `n` for a segment
#'   summary.
#' @param id Optional identifier vector of length `n`.
#' @param config An [scr_config()] object (`ecl_*` keys, `verbose`).
#' @param keep_rows Keep the per-exposure table.
#'
#' @return An object of class `scr_ecl`: a list with `exposures` (only
#'   with `keep_rows = TRUE`: `id`, `segment`, `stage`, `ead`, `pd_12m`,
#'   `pd_life`, `ecl_12m`, `ecl_life`, `ecl`), `stages` (`stage`, `n`,
#'   `ead`, `ecl_12m`, `ecl_life`, `ecl`, `coverage`), `segments` (when a
#'   segment is given), `scenarios` (`scenario`, `weight`, `ecl_12m`,
#'   `ecl_life`, `ecl`), `totals` (`n`, `ead`, `ecl_12m`, `ecl_life`, `ecl`,
#'   `coverage`, `share_stage2`, `share_stage3`), `horizon`, `t_max`,
#'   `discount`, `stage_rule`, `ledger` and `config`.
#'
#' @references
#' International Accounting Standards Board (2014). *IFRS 9 Financial
#' Instruments*, section 5.5 and paragraphs B5.5.1-B5.5.55.
#'
#' @family irb-capital
#' @examples
#' cfg <- scr_config(verbose = FALSE)
#' d <- scr_demo_portfolio
#' h <- 1 - (1 - d$pd)^(1 / 12)       # flat monthly hazard from the annual PD
#' e <- scr_ecl(h, d$lgd, d$ead, eir = d$eir, dpd = d$dpd, pd_orig = d$pd_orig,
#'              t_max = 36L, segment = d$segment, config = cfg)
#' e
#' e$stages
#' @export
scr_ecl <- function(pd_term, lgd, ead, eir = 0, stage = NULL, dpd = NULL, pd_orig = NULL, scenarios = NULL,
                    weights = NULL, prepay = NULL, rho = 0.15, t_max = NULL, segment = NULL, id = NULL,
                    config = scr_config(), keep_rows = FALSE) {
  check_config(config, "scr_ecl")
  cfg <- config
  old <- scr_verbose(isTRUE(cfg$verbose)); on.exit(scr_verbose(old), add = TRUE)
  t0 <- Sys.time()
  horizon <- as.integer(cfg$ecl_horizon_months)
  t_max <- as.integer(t_max %||% horizon)
  if (t_max < 1L) stop("scr_ecl(): `t_max` must be at least one month.", call. = FALSE)

  # -- shape the inputs into n x T matrices ---------------------------------- #
  n <- max(if (is.matrix(pd_term)) nrow(pd_term) else length(pd_term),
           if (is.matrix(lgd)) nrow(lgd) else length(lgd), if (is.matrix(ead)) nrow(ead) else length(ead),
           length(eir), length(stage), length(dpd), length(pd_orig), length(segment), length(id))
  H <- if (is.matrix(pd_term)) ncol(pd_term) else t_max
  if (H < 1L) stop("scr_ecl(): `pd_term` needs at least one column.", call. = FALSE)
  mat <- function(v, what) {
    if (is.matrix(v)) {
      if (ncol(v) != H) stop(sprintf("scr_ecl(): `%s` has %d columns, expected %d.", what, ncol(v), H), call. = FALSE)
      if (nrow(v) == n) return(unname(v))
      if (nrow(v) == 1L) return(matrix(v, n, H, byrow = TRUE))
      stop(sprintf("scr_ecl(): `%s` has %d rows, expected %d.", what, nrow(v), n), call. = FALSE)
    }
    matrix(rep_len(as.double(v), n), n, H)
  }
  h <- mat(pd_term, "pd_term"); L <- mat(lgd, "lgd"); E <- mat(ead, "ead")
  if (anyNA(h) || any(h < 0 | h > 1)) stop("scr_ecl(): `pd_term` must hold marginal PDs in [0, 1] without missing values.", call. = FALSE)
  if (anyNA(L) || any(L < 0)) stop("scr_ecl(): `lgd` must be non-negative without missing values.", call. = FALSE)
  if (anyNA(E) || any(E < 0)) stop("scr_ecl(): `ead` must be non-negative without missing values.", call. = FALSE)
  P <- if (is.null(prepay)) NULL else mat(prepay, "prepay")
  if (!is.null(P) && (anyNA(P) || any(P < 0 | P + h > 1))) stop("scr_ecl(): `prepay` must be in [0, 1 - pd_term].", call. = FALSE)
  r <- rep_len(as.double(eir), n)
  if (anyNA(r) || any(r <= -1)) stop("scr_ecl(): `eir` must be a rate above -1 without missing values.", call. = FALSE)
  discount <- identical(cfg$ecl_discount, "eir")
  DF <- if (discount) outer(1 + r, -(seq_len(H)) / 12, `^`) else matrix(1, n, H)
  hz <- min(horizon, H)

  # -- stage ------------------------------------------------------------------ #
  pd12 <- 1 - .row_prod(1 - h[, seq_len(hz), drop = FALSE])
  rule <- NULL
  if (is.null(stage)) {
    st <- rep(1L, n)
    thr <- as.integer(cfg$ecl_stage_dpd)
    if (!is.null(pd_orig)) {
      po <- rep_len(as.double(pd_orig), n)
      ratio <- ifelse(!is.na(po) & po > 0, pd12 / po, NA_real_)
      st[!is.na(ratio) & ratio >= cfg$ecl_sicr_ratio] <- 2L
    }
    if (!is.null(dpd)) {
      dd <- rep_len(as.double(dpd), n)
      st[!is.na(dd) & dd >= thr[1]] <- 2L
      st[!is.na(dd) & dd >= thr[2]] <- 3L
    }
    rule <- list(source = if (is.null(dpd) && is.null(pd_orig)) "none (all stage 1)" else "rule",
                 dpd_stage2 = thr[1], dpd_stage3 = thr[2], sicr_ratio = cfg$ecl_sicr_ratio,
                 uses_dpd = !is.null(dpd), uses_pd_orig = !is.null(pd_orig))
  } else {
    st <- as.integer(rep_len(stage, n))
    if (anyNA(st) || !all(st %in% 1:3)) stop("scr_ecl(): `stage` must be 1, 2 or 3.", call. = FALSE)
    rule <- list(source = "supplied")
  }

  # -- scenarios --------------------------------------------------------------- #
  if (is.null(scenarios)) scenarios <- list(base = list())
  if (!is.list(scenarios) || is.null(names(scenarios)) || any(!nzchar(names(scenarios)))) {
    stop("scr_ecl(): `scenarios` must be a named list of shocks.", call. = FALSE)
  }
  w <- if (is.null(weights)) rep(1 / length(scenarios), length(scenarios)) else as.double(weights)
  if (length(w) != length(scenarios) || anyNA(w) || any(w < 0) || sum(w) <= 0) {
    stop("scr_ecl(): `weights` must be non-negative, one per scenario.", call. = FALSE)
  }
  w_raw <- w; w <- w / sum(w)
  ok_keys <- c("pd_mult", "z", "lgd_add", "ead_mult")
  runs <- lapply(scenarios, function(s) {
    bad <- setdiff(names(s), ok_keys)
    if (length(bad)) stop("scr_ecl(): unknown scenario key(s): ", lst(bad), ". Use ", lst(ok_keys), ".", call. = FALSE)
    hs <- h
    if (!is.null(s$z)) hs <- .vasicek_pit(hs, s$z, rho)
    if (!is.null(s$pd_mult)) hs <- pmin(hs * s$pd_mult, 1)   # first argument keeps the dims
    Ls <- if (is.null(s$lgd_add)) L else L + s$lgd_add
    Es <- if (is.null(s$ead_mult)) E else E * s$ead_mult
    .ecl_paths(hs, Ls, Es, P, DF, hz, st)
  })
  ecl12 <- Reduce(`+`, Map(function(x, wi) x$ecl_12m * wi, runs, w))
  ecll <- Reduce(`+`, Map(function(x, wi) x$ecl_life * wi, runs, w))
  ecl <- ifelse(st == 1L, ecl12, ecll)
  scen <- data.table::data.table(
    scenario = names(scenarios), weight = w,
    ecl_12m = vapply(runs, function(x) sum(x$ecl_12m), numeric(1)),
    ecl_life = vapply(runs, function(x) sum(x$ecl_life), numeric(1)),
    ecl = vapply(runs, function(x) sum(ifelse(st == 1L, x$ecl_12m, x$ecl_life)), numeric(1)))

  # -- tables ------------------------------------------------------------------- #
  ead1 <- E[, 1]
  ex <- data.table::data.table(id = if (is.null(id)) seq_len(n) else rep_len(id, n),
                               segment = if (is.null(segment)) NA_character_ else as.character(rep_len(segment, n)),
                               stage = st, ead = ead1, pd_12m = pd12, pd_life = 1 - .row_prod(1 - h),
                               ecl_12m = ecl12, ecl_life = ecll, ecl = ecl)
  stages <- ex[, list(n = .N, ead = sum(ead), ecl_12m = sum(ecl_12m), ecl_life = sum(ecl_life), ecl = sum(ecl)), by = "stage"]
  stages <- merge(data.table::data.table(stage = 1:3), stages, by = "stage", all.x = TRUE)
  for (j in c("n", "ead", "ecl_12m", "ecl_life", "ecl")) data.table::set(stages, which(is.na(stages[[j]])), j, if (j == "n") 0L else 0)
  stages[, coverage := ifelse(ead > 0, ecl / ead, NA_real_)]
  segs <- if (is.null(segment)) NULL else {
    s <- ex[, list(n = .N, ead = sum(ead), ecl_12m = sum(ecl_12m), ecl_life = sum(ecl_life), ecl = sum(ecl),
                   share_stage2 = mean(stage == 2L), share_stage3 = mean(stage == 3L)), by = "segment"]
    s[, coverage := ifelse(ead > 0, ecl / ead, NA_real_)]
    data.table::setorder(s, -ecl)[]
  }
  tot_ead <- sum(ead1)
  totals <- list(n = n, ead = tot_ead, ecl_12m = sum(ecl12), ecl_life = sum(ecll), ecl = sum(ecl),
                 coverage = if (tot_ead > 0) sum(ecl) / tot_ead else NA_real_,
                 share_stage2 = mean(st == 2L), share_stage3 = mean(st == 3L), n_scenarios = length(scenarios))
  ledger <- data.table::rbindlist(list(
    .cap_ledger("stage", if (identical(rule$source, "supplied")) "stage supplied by the caller" else
                  sprintf("rule: stage 3 if dpd >= %d; stage 2 if dpd >= %d or pd_12m / pd_orig >= %g%s",
                          rule$dpd_stage3, rule$dpd_stage2, rule$sicr_ratio,
                          if (!rule$uses_dpd && !rule$uses_pd_orig) " (no dpd nor pd_orig: every exposure in stage 1)" else "")),
    .cap_ledger("discount", if (discount) "effective interest rate, monthly compounding" else "none"),
    .cap_ledger("horizon", sprintf("12-month figure over %d months, lifetime over %d months%s", hz, H,
                                   if (is.null(P)) "" else "; prepayment hazard applied")),
    .cap_ledger("scenarios", sprintf("%s", paste(sprintf("%s (%.3f)", names(scenarios), w), collapse = ", ")),
                if (!isTRUE(all.equal(w_raw, w))) "weights normalised to one" else NA_character_)))
  msg("  ecl: %s exposures | ECL %s (coverage %s) | stage 2 %s, stage 3 %s (%.2fs)", n_fmt(n),
      format(round(totals$ecl)), fmt_pct(totals$coverage, 2), fmt_pct(totals$share_stage2), fmt_pct(totals$share_stage3),
      as.numeric(difftime(Sys.time(), t0, units = "secs")))
  structure(list(exposures = if (isTRUE(keep_rows)) ex[] else NULL, stages = stages[], segments = segs, scenarios = scen,
                 totals = totals, horizon = hz, t_max = H, discount = if (discount) "eir" else "none",
                 stage_rule = rule, ledger = ledger, config = cfg),
            class = c("scr_ecl", "list"))
}

#' Row-wise product of a matrix
#' @keywords internal
#' @noRd
.row_prod <- function(M) if (ncol(M) == 1L) M[, 1] else apply(M, 1L, prod)

#' Survival-weighted ECL over the horizon and the lifetime; stage 3 rows carry LGD_1 * EAD_1
#' @keywords internal
#' @noRd
.ecl_paths <- function(h, L, E, P, DF, hz, st) {
  n <- nrow(h); H <- ncol(h)
  exit <- if (is.null(P)) h else h + P
  S_prev <- matrix(1, n, H)
  if (H > 1L) for (j in 2:H) S_prev[, j] <- S_prev[, j - 1L] * (1 - exit[, j - 1L])
  loss <- S_prev * h * L * E * DF
  life <- rowSums(loss)
  m12 <- rowSums(loss[, seq_len(hz), drop = FALSE])
  s3 <- st == 3L
  if (any(s3)) { v <- L[s3, 1] * E[s3, 1]; life[s3] <- v; m12[s3] <- v }
  list(ecl_12m = m12, ecl_life = life)
}

#' @export
print.scr_ecl <- function(x, ...) {
  t <- x$totals
  cat(sprintf("<scr_ecl> %s exposures | ECL %s | coverage %s | 12-month horizon %d of %d months | discount: %s\n",
              n_fmt(t$n), format(round(t$ecl), big.mark = ","), fmt_pct(t$coverage, 2), x$horizon, x$t_max, x$discount))
  cat(sprintf("  stage rule: %s\n", if (identical(x$stage_rule$source, "supplied")) "supplied" else
        sprintf("dpd >= %d -> stage 3; dpd >= %d or PD ratio >= %g -> stage 2", x$stage_rule$dpd_stage3,
                x$stage_rule$dpd_stage2, x$stage_rule$sicr_ratio)))
  s <- x$stages
  for (i in seq_len(nrow(s))) {
    cat(sprintf("  stage %d  n %-7s EAD %-14s ECL %-12s coverage %s\n", s$stage[i], n_fmt(s$n[i]),
                format(round(s$ead[i]), big.mark = ","), format(round(s$ecl[i]), big.mark = ","), fmt_pct(s$coverage[i], 2)))
  }
  cat(sprintf("  12-month %s | lifetime %s | scenarios: %s\n", format(round(t$ecl_12m), big.mark = ","),
              format(round(t$ecl_life), big.mark = ","),
              paste(sprintf("%s %.2f", x$scenarios$scenario, x$scenarios$weight), collapse = ", ")))
  invisible(x)
}

# NSE column names used in data.table expressions of this file
utils::globalVariables(c(
  "ecl_12m",
  "ecl_life"
))
