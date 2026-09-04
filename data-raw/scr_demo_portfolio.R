# ============================================================================ #
# data-raw/scr_demo_portfolio.R - exposure snapshot for EL, capital and ECL
# ============================================================================ #
# Run with: Rscript data-raw/scr_demo_portfolio.R
#
# 5,000 exposures across six segments that map one-to-one to the asset
# classes of the risk-weight function. PD is a grade PD (constant within
# asset class x grade, a master scale of ten geometric grades starting below
# the regulatory floors on purpose), LGD is a pool value constant within the
# segment, so that segment x grade is a homogeneous pool: the production SQL
# emits one row of constants per pool and reproduces R exactly. About 3 % of
# the exposures are in default with a best estimate of expected loss (ELBE)
# and a larger provision; the remaining columns feed the standardised
# comparison (LTV, rating, transactor flag, sales) and the accounting stage
# rule (days past due, PD at origination, effective interest rate).
# ============================================================================ #

set.seed(20260904)
seg <- data.frame(
  segment     = c("retail_loans", "mortgages", "cards_revolver", "cards_transactor", "corporate_large", "corporate_sme"),
  asset_class = c("retail_other", "retail_mortgage", "qrre_revolver", "qrre_transactor", "corporate", "corporate_sme"),
  n           = c(1500L, 1000L, 800L, 500L, 500L, 700L),
  lgd         = c(0.45, 0.15, 0.75, 0.70, 0.40, 0.42),
  ead_mu      = log(c(8000, 150000, 3000, 2500, 2e6, 3e5)),
  ead_sd      = c(0.7, 0.4, 0.8, 0.8, 0.9, 0.8),
  grade_mu    = c(5.5, 4.0, 6.0, 4.5, 4.5, 5.5),
  stringsAsFactors = FALSE)
scale <- data.frame(grade = sprintf("G%02d", 1:10),
                    pd = round(0.0003 * (0.30 / 0.0003)^((0:9) / 9), 6))   # 0.03 % to 30 %, geometric

rows <- lapply(seq_len(nrow(seg)), function(i) {
  s <- seg[i, ]
  n <- s$n
  g <- pmin(10L, pmax(1L, round(stats::rnorm(n, s$grade_mu, 1.8))))
  ead <- round(stats::rlnorm(n, s$ead_mu, s$ead_sd))
  revolving <- s$asset_class %in% c("qrre_revolver", "qrre_transactor", "corporate", "corporate_sme")
  util <- if (revolving) stats::rbeta(n, 3, 2) else 1
  drawn <- round(ead * util)
  undrawn <- ead - drawn
  wholesale <- s$asset_class %in% c("corporate", "corporate_sme")
  data.frame(
    segment = s$segment, asset_class = s$asset_class, grade = scale$grade[g], pd = scale$pd[g],
    lgd = s$lgd, ead = ead, drawn = drawn, undrawn = undrawn,
    m = if (wholesale) round(stats::runif(n, 1, 5), 1) else NA_real_,
    sales = if (s$asset_class == "corporate") round(stats::rlnorm(n, log(800), 0.8))
            else if (s$asset_class == "corporate_sme") round(stats::runif(n, 5, 280)) else NA_real_,
    ltv = if (s$asset_class == "retail_mortgage") round(stats::runif(n, 0.2, 1.1), 2) else NA_real_,
    rating = if (s$asset_class == "corporate") sample(c("AA", "A", "BBB", "BB", "B", NA), n, TRUE,
                                                      prob = c(.05, .2, .3, .2, .1, .15)) else NA_character_,
    transactor = s$asset_class == "qrre_transactor",
    stringsAsFactors = FALSE)
})
port <- do.call(rbind, rows)
n <- nrow(port)
port <- port[sample.int(n), ]
port$id <- sprintf("E%05d", seq_len(n))
rownames(port) <- NULL

# defaults: about 3 %, more likely in the riskier grades
p_def <- stats::plogis(-7 + 0.6 * as.integer(substr(port$grade, 2, 3)))
port$defaulted <- as.integer(stats::runif(n) < p_def)
port$elbe <- ifelse(port$defaulted == 1L, round(pmin(0.95, pmax(0.05, port$lgd + stats::rnorm(n, 0, 0.12))), 2), NA_real_)
# days past due: defaulted 90+, a few performing exposures in early arrears
port$dpd <- ifelse(port$defaulted == 1L, sample(c(90L, 120L, 180L, 360L), n, TRUE),
                   ifelse(stats::runif(n) < 0.05, sample(c(5L, 15L, 30L, 45L, 60L), n, TRUE), 0L))
# PD at origination: mostly the same grade, a share deteriorated since origination
shift <- sample(c(-2L, -1L, 0L, 1L), n, TRUE, prob = c(0.02, 0.06, 0.87, 0.05))
g_now <- as.integer(substr(port$grade, 2, 3))
port$pd_orig <- scale$pd[pmin(10L, pmax(1L, g_now + shift))]
port$stage <- ifelse(port$dpd >= 90L, 3L, ifelse(port$dpd >= 30L | port$pd / port$pd_orig >= 2, 2L, 1L))
# provisions: coverage by stage, plus the ELBE on the defaulted book
cov <- c(0.006, 0.05, 0)[port$stage]
port$provision <- round(ifelse(port$defaulted == 1L, port$elbe * port$ead * stats::runif(n, 0.9, 1.15),
                               cov * port$ead * stats::runif(n, 0.5, 1.5)))
port$eir <- round(c(retail_loans = 0.24, mortgages = 0.10, cards_revolver = 0.38, cards_transactor = 0.30,
                    corporate_large = 0.12, corporate_sme = 0.16)[port$segment] + stats::rnorm(n, 0, 0.01), 3)

scr_demo_portfolio <- port[, c("id", "segment", "asset_class", "grade", "pd", "lgd", "ead", "drawn", "undrawn", "m",
                               "sales", "ltv", "rating", "transactor", "defaulted", "elbe", "provision", "stage",
                               "dpd", "pd_orig", "eir")]
usethis::use_data(scr_demo_portfolio, overwrite = TRUE, compress = "xz")
