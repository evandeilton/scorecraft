# ============================================================================ #
# data-raw/scr_demo_panel.R - monthly panel for the default engine and PD
# ============================================================================ #
# Run with: Rscript data-raw/scr_demo_panel.R
#
# 600 obligors observed over 36 months: days past due evolve as a Markov
# chain whose transition to arrears depends on a latent risk score, arrears
# are proportional to the exposure, a few obligors are restructured, and
# some arrears are immaterial on purpose (below the absolute threshold) so
# that the materiality test has something to do. `score` is a behavioural
# score (higher = safer) with genuine rank-ordering power.
# ============================================================================ #

set.seed(20260904)
n_id <- 600L; n_m <- 36L
ids <- sprintf("O%04d", seq_len(n_id))
dates <- seq(as.Date("2023-01-01"), by = "month", length.out = n_m)
risk <- stats::rnorm(n_id)                       # latent risk, higher = riskier
score <- round(600 - 60 * risk + stats::rnorm(n_id, 0, 15))
exposure <- round(stats::rlnorm(n_id, log(20000), 0.6), 2)
restr_id <- sample(ids, 25L)

rows <- vector("list", n_id)
for (i in seq_len(n_id)) {
  p_slip <- stats::plogis(-4.1 + 1.1 * risk[i])   # monthly probability of missing a payment
  p_cure <- 0.35
  dpd <- integer(n_m); state <- 0L
  for (m in seq_len(n_m)) {
    if (state == 0L) {
      if (stats::runif(1) < p_slip) state <- 30L
    } else {
      if (stats::runif(1) < p_cure) state <- 0L else state <- state + 30L
    }
    dpd[m] <- state
  }
  arrears <- ifelse(dpd > 0L, pmax(0, exposure[i] * (0.004 * dpd / 30) * stats::runif(n_m, 0.6, 1.4)), 0)
  # immaterial arrears for a few obligors: below the absolute threshold
  if (i %% 23L == 0L) arrears <- pmin(arrears, 80)
  rows[[i]] <- data.frame(
    id = ids[i], ref_date = dates, dpd = dpd, arrears = round(arrears, 2), exposure = exposure[i],
    restructured = ids[i] %in% restr_id & seq_len(n_m) >= 18L, score = score[i],
    stringsAsFactors = FALSE)
}
scr_demo_panel <- do.call(rbind, rows)
rownames(scr_demo_panel) <- NULL
usethis::use_data(scr_demo_panel, overwrite = TRUE, compress = "xz")
