# ============================================================================ #
# data-raw/scr_demo_lgd.R - default events, workout cash flows and reference
# rates for the LGD examples
# ============================================================================ #
# Run with: Rscript data-raw/scr_demo_lgd.R
#
# 900 default events on three products observed until 2026-06-30. Every
# event has a latent cure propensity (rising with time on book, falling with
# the worst delinquency before default, the loan-to-value and the product)
# and, when it does not cure, an ultimate recovery whose level and timing are
# product-specific: unsecured recoveries dribble in over up to four years,
# mortgages recover little until a collateral sale between one and three
# years in, cars are repossessed and sold within nine months. Direct costs
# are booked at the start of the workout and at the sale. A few unsecured
# defaults draw further after default. Events that are still running at
# the observation date are `open`; a handful of very old open defaults
# exercise the maximum-recovery-period rule. Thirty facilities default a
# second time after curing: half within nine months of the cure, so that the
# workout engine merges the two spells into one default event, half later.
#
# Cash flows of a cure are the payments that brought the facility back to
# performing, not the outstanding balance: scr_workout() adds the balance
# outstanding at the cure date as an artificial recovery.
# ============================================================================ #

set.seed(20260904)
obs_date <- as.Date("2026-06-30")
add_m <- function(d, k) as.Date(vapply(seq_along(d), function(i)
  as.character(seq(d[i], by = "month", length.out = k[i] + 1L)[k[i] + 1L]), character(1)))

# -- reference rate: monthly annualised rate, 2019-01 to 2026-06 ------------ #
dates_r <- seq(as.Date("2019-01-01"), as.Date("2026-06-01"), by = "month")
knots <- data.frame(
  date = as.Date(c("2019-01-01", "2019-12-01", "2020-04-01", "2020-08-01", "2021-03-01", "2021-12-01",
                   "2022-08-01", "2023-08-01", "2024-06-01", "2025-03-01", "2026-06-01")),
  rate = c(0.065, 0.045, 0.0375, 0.02, 0.02, 0.0925, 0.1375, 0.1375, 0.105, 0.1325, 0.12))
rate <- stats::approx(as.numeric(knots$date), knots$rate, xout = as.numeric(dates_r))$y
rate <- round(rate + stats::rnorm(length(rate), 0, 0.0008), 4)
scr_demo_rates <- data.frame(date = dates_r, rate = rate)

# -- primary default events ------------------------------------------------- #
n1 <- 870L
product <- sample(c("unsecured", "mortgage", "auto"), n1, TRUE, prob = c(0.50, 0.25, 0.25))
ead <- round(ifelse(product == "unsecured", stats::rlnorm(n1, log(8000), 0.7),
              ifelse(product == "mortgage", stats::rlnorm(n1, log(180000), 0.5),
                     stats::rlnorm(n1, log(35000), 0.45))), 2)
ltv <- round(ifelse(product == "unsecured", 0,
              ifelse(product == "mortgage", stats::runif(n1, 0.40, 1.10), stats::runif(n1, 0.50, 1.30))), 3)
collateral_value <- ifelse(product == "unsecured", 0, round(ead / pmax(ltv, 0.05), 2))
months_on_book <- pmin(180L, as.integer(round(ifelse(product == "mortgage", stats::rexp(n1, 1 / 60), stats::rexp(n1, 1 / 30)))) + 1L)
prior_dpd_max <- 30L * sample(0:4, n1, TRUE, prob = c(0.30, 0.35, 0.20, 0.10, 0.05))
region <- sample(c("north", "south", "east", "west", "central"), n1, TRUE, prob = c(0.15, 0.30, 0.25, 0.20, 0.10))
default_date <- as.Date("2019-01-01") + sample.int(as.integer(as.Date("2026-03-31") - as.Date("2019-01-01")), n1, TRUE)
default_date <- as.Date(format(default_date, "%Y-%m-01")) + sample(0:27, n1, TRUE)

ev <- data.frame(default_id = sprintf("D%04d", seq_len(n1)), facility_id = sprintf("F%04d", seq_len(n1)),
                 default_date = default_date, ead = ead, product = product, collateral_value = collateral_value,
                 ltv = ltv, months_on_book = months_on_book, prior_dpd_max = prior_dpd_max, region = region,
                 stringsAsFactors = FALSE)

# -- one workout per event: returns status, close_date and the cash flows ---- #
workout <- function(e, force_no_cure = FALSE) {
  z_dpd <- e$prior_dpd_max / 30 - 1.2
  z_mob <- (e$months_on_book - 35) / 40
  reg <- c(north = -0.35, south = 0.30, east = 0.05, west = -0.10, central = 0)[e$region]
  prod_c <- c(unsecured = -0.25, mortgage = 0.45, auto = 0.05)[e$product]
  lp <- -0.55 - 0.55 * z_dpd + 0.45 * z_mob + prod_c + reg - 0.9 * (e$ltv - 0.8) * (e$product != "unsecured") +
    stats::rnorm(1, 0, 0.35)
  cure <- !force_no_cure && stats::runif(1) < stats::plogis(lp)
  d0 <- e$default_date
  if (cure) {
    m <- sample(1:6, 1L)
    paid <- e$ead * stats::runif(1, 0.05, 0.25)
    cf <- data.frame(default_id = e$default_id, date = add_m(rep(d0, m), 1:m),
                     amount = round(rep(paid / m, m), 2), type = "recovery", stringsAsFactors = FALSE)
    cf <- rbind(cf, data.frame(default_id = e$default_id, date = add_m(d0, 1L),
                               amount = round(e$ead * stats::runif(1, 0.003, 0.015), 2), type = "direct_cost"))
    close <- add_m(d0, m)
    if (close > obs_date) return(list(status = "open", close_date = as.Date(NA), cf = cf[cf$date <= obs_date, , drop = FALSE]))
    return(list(status = "cured", close_date = close, cf = cf))
  }
  if (e$product == "unsecured") {
    u <- stats::plogis(-0.55 - 0.5 * z_dpd + 0.35 * z_mob + reg + stats::rnorm(1, 0, 0.45))
    len <- sample(24:48, 1L)
    if (stats::runif(1) < 0.02) len <- sample(72:90, 1L)      # workouts that drag on beyond the maximum period
    ms <- c(1, 2, 3, 6, 9, 12, 18, 24, 30, 36, 42, 48, 60, 72, 84)
    ms <- ms[ms <= len]
    w <- exp(-ms / 14); w <- w / sum(w)
    cf <- data.frame(default_id = e$default_id, date = add_m(rep(d0, length(ms)), ms),
                     amount = round(u * e$ead * w, 2), type = "recovery", stringsAsFactors = FALSE)
    cost <- data.frame(default_id = e$default_id, date = add_m(c(d0, d0), c(1L, min(len, 12L))),
                       amount = round(c(e$ead * stats::runif(1, 0.03, 0.06), u * e$ead * 0.03), 2), type = "direct_cost")
    cf <- rbind(cf, cost)
    if (stats::runif(1) < 0.08) cf <- rbind(cf, data.frame(default_id = e$default_id, date = add_m(d0, 1L),
                                                           amount = round(e$ead * stats::runif(1, 0.03, 0.10), 2), type = "drawing"))
  } else if (e$product == "mortgage") {
    u <- stats::plogis(1.4 - 2.2 * (e$ltv - 0.8) - 0.25 * z_dpd + 0.3 * reg + stats::rnorm(1, 0, 0.35))
    sale <- sample(12:36, 1L); len <- sale + sample(1:6, 1L)
    cf <- data.frame(default_id = e$default_id, date = add_m(rep(d0, 3L), c(3L, 9L, sale)),
                     amount = round(u * e$ead * c(0.03, 0.03, 0.94), 2), type = "recovery", stringsAsFactors = FALSE)
    cf <- rbind(cf, data.frame(default_id = e$default_id, date = add_m(c(d0, d0), c(2L, sale)),
                               amount = round(c(e$ead * stats::runif(1, 0.02, 0.04), u * e$ead * 0.05), 2), type = "direct_cost"))
  } else {
    u <- stats::plogis(0.5 - 1.6 * (e$ltv - 0.9) - 0.3 * z_dpd + 0.2 * reg + stats::rnorm(1, 0, 0.35))
    sale <- sample(3:9, 1L); len <- sale + sample(1:3, 1L)
    cf <- data.frame(default_id = e$default_id, date = add_m(rep(d0, 2L), c(1L, sale)),
                     amount = round(u * e$ead * c(0.05, 0.95), 2), type = "recovery", stringsAsFactors = FALSE)
    cf <- rbind(cf, data.frame(default_id = e$default_id, date = add_m(c(d0, d0), c(1L, sale)),
                               amount = round(c(e$ead * stats::runif(1, 0.015, 0.03), u * e$ead * 0.08), 2), type = "direct_cost"))
  }
  close <- add_m(d0, len)
  if (close > obs_date) {
    cf <- cf[cf$date <= obs_date, , drop = FALSE]
    return(list(status = "open", close_date = as.Date(NA), cf = cf))
  }
  list(status = "closed", close_date = close, cf = cf)
}

res <- lapply(seq_len(n1), function(i) workout(ev[i, ]))
ev$status <- vapply(res, `[[`, character(1), "status")
ev$close_date <- as.Date(vapply(res, function(r) as.character(r$close_date), character(1)))
cfs <- lapply(res, `[[`, "cf")

# -- second defaults of thirty cured facilities ----------------------------- #
cand <- which(ev$status == "cured" & ev$close_date <= as.Date("2024-06-30"))
second <- sample(cand, 30L)
gap <- c(sample(1:6, 15L, TRUE), sample(12:30, 15L, TRUE))
ev2 <- ev[second, ]
ev2$default_id <- sprintf("D%04d", n1 + seq_len(30L))
ev2$default_date <- add_m(ev$close_date[second], gap)
ev2$ead <- round(ev2$ead * stats::runif(30L, 0.85, 1.0), 2)
ev2$months_on_book <- ev2$months_on_book + gap + as.integer(round(as.numeric(ev$close_date[second] - ev$default_date[second]) / 30.4))
ev2$prior_dpd_max <- 90L
res2 <- lapply(seq_len(30L), function(i) workout(ev2[i, ], force_no_cure = stats::runif(1) < 0.6))
ev2$status <- vapply(res2, `[[`, character(1), "status")
ev2$close_date <- as.Date(vapply(res2, function(r) as.character(r$close_date), character(1)))
cfs <- c(cfs, lapply(res2, `[[`, "cf"))

scr_demo_lgd <- rbind(ev, ev2)
rownames(scr_demo_lgd) <- NULL
scr_demo_lgd_cashflows <- do.call(rbind, cfs)
scr_demo_lgd_cashflows <- scr_demo_lgd_cashflows[order(scr_demo_lgd_cashflows$default_id, scr_demo_lgd_cashflows$date,
                                                       scr_demo_lgd_cashflows$type), ]
rownames(scr_demo_lgd_cashflows) <- NULL

cat(sprintf("scr_demo_lgd: %d events | %s | cash flows: %d rows | rates: %d months\n",
            nrow(scr_demo_lgd), paste(sprintf("%s %d", names(table(scr_demo_lgd$status)), table(scr_demo_lgd$status)), collapse = ", "),
            nrow(scr_demo_lgd_cashflows), nrow(scr_demo_rates)))
usethis::use_data(scr_demo_lgd, overwrite = TRUE, compress = "xz")
usethis::use_data(scr_demo_lgd_cashflows, overwrite = TRUE, compress = "xz")
usethis::use_data(scr_demo_rates, overwrite = TRUE, compress = "xz")
