# ============================================================================ #
# data-raw/scr_demo_ead.R - monthly facility snapshots for the EAD/CCF module
# ============================================================================ #
# Run with: Rscript data-raw/scr_demo_ead.R
#
# 1,200 revolving facilities (cards, overdrafts, revolving lines) of about
# 950 obligors, observed at month ends over 30 months. Utilisation follows
# a facility-specific level with a mild AR(1) drift. About 10% of the
# facilities default: their utilisation ramps up over the twelve months
# before the default month, with an intensity that depends on the drivers
# a CCF model is expected to find (utilisation, product, months on book,
# days past due) so that the pools have something to separate. Some
# defaulters are fully drawn or over the limit at the reference date, some
# repay before default (negative realised CCF), some have their limit cut
# by the lender two months before default, and a share of all facilities
# gets a limit change during the window. A few facilities originate inside
# the window, so that fast defaults exist. Days past due are multiples of
# 30 and reach 90 at the default month; `defaulted` stays 1 from the
# default month onwards.
# ============================================================================ #

set.seed(20260904)
n_fac <- 1200L; n_m <- 30L
dates <- seq(as.Date("2023-01-01"), by = "month", length.out = n_m)
fac_ids <- sprintf("F%04d", seq_len(n_fac))
obl_ids <- sprintf("O%04d", c(seq_len(950L), sample.int(950L, n_fac - 950L, replace = TRUE)))

product <- sample(c("card", "overdraft", "line"), n_fac, TRUE, prob = c(0.55, 0.30, 0.15))
limit0 <- vapply(product, function(p) switch(p,
  card      = sample(c(1000, 2000, 3000, 5000, 8000, 12000), 1),
  overdraft = sample(c(500, 1000, 2000, 5000), 1),
  line      = sample(c(10000, 20000, 50000), 1)), numeric(1))
# months on book at the first window month; negative = originates later
mob0 <- sample(c(-11:-1, 0:72), n_fac, TRUE, prob = c(rep(1.2, 11), rep(1, 73)))
u0 <- stats::rbeta(n_fac, 2, 3)                  # long-run utilisation level
defaulter <- stats::runif(n_fac) < 0.105
d_month <- ifelse(defaulter, sample(6:30, n_fac, TRUE, prob = c(rep(0.4, 7), rep(1, 18))), NA_integer_)
# drawdown intensity before default: lower at high utilisation, higher for
# cards, lower with age; the realised CCF follows it
intensity <- stats::plogis(0.8 - 3.5 * u0 + 1.2 * (product == "card") - 0.025 * pmax(mob0, 0) +
                             stats::rnorm(n_fac, 0, 0.25))
repayer  <- defaulter & stats::runif(n_fac) < 0.05      # drawn falls before default
cut_lim  <- defaulter & stats::runif(n_fac) < 0.10      # lender cuts the limit before default
over_lim <- defaulter & stats::runif(n_fac) < 0.18      # over the limit at default
lim_up   <- stats::runif(n_fac) < 0.10
lim_dn   <- !lim_up & stats::runif(n_fac) < 0.05
lim_m    <- sample(3:26, n_fac, TRUE)
full_nd  <- !defaulter & stats::runif(n_fac) < 0.04     # non-defaulters sitting at the limit
full_d   <- defaulter & stats::runif(n_fac) < 0.07      # defaulters sitting at the limit all along

rows <- vector("list", n_fac)
for (i in seq_len(n_fac)) {
  first <- max(1L, 1L - mob0[i])
  months <- first:n_m
  k <- length(months)
  lim <- rep(limit0[i], k)
  if (lim_up[i]) lim[months >= lim_m[i]] <- limit0[i] * sample(c(1.25, 1.5), 1)
  if (lim_dn[i]) lim[months >= lim_m[i]] <- limit0[i] * 0.7
  e <- stats::rnorm(k, 0, 0.04); u <- numeric(k); u[1] <- u0[i] + e[1]
  for (m in seq_len(k)[-1]) u[m] <- u0[i] + 0.6 * (u[m - 1] - u0[i]) + e[m]
  u <- pmin(pmax(u, 0), 0.98)
  if (full_nd[i] || full_d[i]) u <- pmin(1.05, u + 0.5)
  dpd <- integer(k); def <- integer(k)
  if (defaulter[i]) {
    D <- d_month[i]
    if (D < first) D <- first + 1L
    if (D > n_m) D <- n_m
    tt <- months - D                                    # months relative to default
    ramp <- pmax(0, pmin(1, (12 + tt) / 12))^1.6 * intensity[i]
    ramp[tt > 0] <- intensity[i]
    u <- ifelse(tt <= 0, u + (1 - u) * ramp, u)
    if (repayer[i]) u <- ifelse(tt > -12 & tt <= 0, pmax(0.02, u - 0.35 * (12 + tt) / 12), u)
    if (cut_lim[i]) lim[tt >= -2] <- lim[tt >= -2] * 0.6
    if (over_lim[i]) u[tt == 0] <- 1 + stats::runif(1, 0.02, 0.15)
    u[tt > 0] <- pmin(u[tt > 0] + 0.01 * seq_len(sum(tt > 0)), 1.1)
    dpd[tt == -2] <- 30L; dpd[tt == -1] <- 60L
    dpd[tt >= 0] <- 90L + 30L * pmin(tt[tt >= 0], 6L)
    def[tt >= 0] <- 1L
    u <- pmin(pmax(u, 0), 1.2)
  }
  drawn <- round(u * lim / 10) * 10
  rows[[i]] <- data.frame(
    facility_id = fac_ids[i], obligor_id = obl_ids[i], ref_date = dates[months],
    limit = lim, drawn = drawn, product = product[i],
    months_on_book = as.integer(mob0[i] + months - 1L), dpd = dpd, defaulted = def,
    stringsAsFactors = FALSE)
}
scr_demo_ead <- do.call(rbind, rows)
rownames(scr_demo_ead) <- NULL
usethis::use_data(scr_demo_ead, overwrite = TRUE, compress = "xz")
