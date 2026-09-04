# ============================================================================ #
# data-raw/scr_demo.R - generates the example dataset of the package
# ============================================================================ #
# Run with: Rscript data-raw/scr_demo.R
#
# The dataset exists so that EVERY example and EVERY vignette runs without a
# database. It is fabricated to carry, on purpose, the same defects real data
# has: sentinel -999 in several masses, missing values, a constant column, a
# near-constant one, an exact duplicate, high cardinality, a redundant pair,
# a column that only degrades in the hold-out period, and pure noise. Without
# those defects the examples would show an empty funnel.
#
# Two targets: `default` (risk, ~10% events) and `churn` (propensity, ~25%).
# ============================================================================ #

set.seed(20260903)
n <- 4200L

dt <- data.frame(
  id       = sprintf("C%06d", seq_len(n)),
  ref_date = as.Date(rep(c("2026-01-01", "2026-02-01", "2026-03-01",
                           "2026-04-01", "2026-05-01", "2026-06-01"), each = n / 6L)),
  stringsAsFactors = FALSE
)
lin <- rep(0, n)

# numerics with signal, decreasing strength
for (i in 1:12) {
  x <- stats::rnorm(n, mean = 50 + 3 * i, sd = 12)
  dt[[sprintf("vl_score_%02d", i)]] <- round(x, 2)
  lin <- lin + (0.65 / sqrt(i)) * as.numeric(scale(x))
}

# numerics with a -999 sentinel population (the signal is in the absence)
mass <- c(0.06, 0.15, 0.30, 0.45, 0.86)
for (i in seq_along(mass)) {
  x  <- round(stats::rlnorm(n, meanlog = 3.2, sdlog = 0.8), 2)
  sp <- stats::runif(n) < mass[i]
  x[sp] <- -999
  dt[[sprintf("vl_hist_%02d", i)]] <- x
  lin <- lin + 0.70 * sp
}

# numerics with genuine missing values
for (i in 1:3) {
  x <- round(stats::rnorm(n), 3)
  x[stats::runif(n) < c(0.12, 0.40, 0.82)[i]] <- NA_real_
  dt[[sprintf("vl_parcial_%02d", i)]] <- x
}

# a column that only degrades in the hold-out (last period)
late <- dt$ref_date >= as.Date("2026-06-01")
xs <- round(stats::rnorm(n), 3)
lin <- lin + 0.45 * xs
xs[late & stats::runif(n) < 0.30] <- NA_real_
xs[late & stats::runif(n) < 0.20] <- -999
dt$vl_tardio <- xs

# pure noise
for (i in 1:6) dt[[sprintf("vl_ruido_%02d", i)]] <- round(stats::rnorm(n), 3)

# structural pathologies
dt$vl_constante   <- 7
qc <- rep(1, n); qc[sample.int(n, 5L)] <- 2
dt$vl_quase_const <- qc
dt$ds_constante   <- "UNICO"
dt$vl_duplicada   <- dt$vl_score_01
dt$vl_redundante  <- round(dt$vl_score_02 + stats::rnorm(n, 0, 0.1), 2)
dt$ds_alta_card   <- sprintf("CEP%05d", sample.int(900L, n, replace = TRUE))

# categoricals
reg <- sample(c("SP", "RJ", "MG", "BA", "RS"), n, replace = TRUE, prob = c(.40, .20, .20, .12, .08))
dt$ds_regiao <- reg
lin <- lin + ifelse(reg %in% c("BA", "RS"), 0.65, -0.15)
fx <- sample(c("A", "B", "C", "D"), n, replace = TRUE)
dt$ds_faixa <- fx
lin <- lin + c(A = 0.45, B = 0.15, C = -0.15, D = -0.45)[fx]
dt$ds_canal <- sample(c("APP", "WEB", "LOJA"), n, replace = TRUE, prob = c(.5, .3, .2))
lin <- lin + ifelse(dt$ds_canal == "APP", 0.40, 0)
with_na <- sample(c("SIM", "NAO", NA_character_), n, replace = TRUE, prob = c(.45, .45, .10))
dt$ds_optin <- with_na
lin <- lin + ifelse(is.na(with_na), 0.40, 0)

# targets
lin  <- lin - mean(lin)
lin2 <- 0.7 * lin + 0.5 * as.numeric(scale(dt$vl_score_03))
lin2 <- lin2 - mean(lin2)
dt$default <- stats::rbinom(n, 1L, stats::plogis(-2.35 + lin))
dt$churn   <- stats::rbinom(n, 1L, stats::plogis(-1.15 + lin2))

scr_demo <- dt[, c("id", "ref_date",
                   setdiff(names(dt), c("id", "ref_date", "default", "churn")),
                   "default", "churn")]

cat(sprintf("scr_demo: %d rows x %d columns | default: %.1f%% | churn: %.1f%%\n",
            nrow(scr_demo), ncol(scr_demo), 100 * mean(scr_demo$default), 100 * mean(scr_demo$churn)))
usethis::use_data(scr_demo, overwrite = TRUE, compress = "xz")
