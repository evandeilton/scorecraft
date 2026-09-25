# Validate a PD model on a cohort panel

Runs the standard battery on a monthly panel with the default flag and
the grade (or the score) at every month: obligors non-defaulted at each
cohort start form the population, the outcome is a default within
`horizon` months, exactly as
[`scr_default_rate()`](https://evandeilton.github.io/scorecraft/reference/scr_default_rate.md)
does.

## Usage

``` r
scr_pd_validate(
  x,
  newdata,
  id = "id",
  date = "date",
  default = "default",
  grade = NULL,
  score = NULL,
  auc_init = NULL,
  cv_init = NULL,
  tests = c("jeffreys", "binomial", "normal", "hl", "multi_period", "auc",
    "concentration", "psi", "migration"),
  alpha = 0.05,
  lights = NULL,
  pd_column = c("pd_final", "pd_moc", "pd_be"),
  horizon = 12L,
  by = NULL,
  n_boot = NULL,
  seed = NULL
)
```

## Arguments

- x:

  An
  [`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md)
  object.

- newdata:

  A `data.frame`/`data.table` panel, one row per `id` and month.

- id, date, default:

  Column names.

- grade:

  Column name of the grade at every month; `NULL` derives it from
  `score` with the cut points of `x`.

- score:

  Column name of the production score at every month, optional.

- auc_init:

  Development AUC; `NULL` uses the scorecard's hold-out AUC.

- cv_init:

  Development coefficient of variation; `NULL` uses the one of `x`.

- tests:

  Subset of the battery to run.

- alpha:

  Significance level of the binomial critical count.

- lights:

  Two p-value thresholds (red at or below the first, amber at or below
  the second, green above; the convention shared with the LGD and EAD
  validations); `NULL` reads `config$pd_lights`.

- pd_column:

  Grade PD tested: `"pd_final"` (default), `"pd_moc"` or `"pd_be"`.

- horizon, by:

  Cohort window in months and frequency (`NULL` reads
  `config$pd_dr_by`).

- n_boot, seed:

  Bootstrap resamples and seed of the discrimination interval.

## Value

An object of class `scr_pd_validation`: `calibration` (per grade,
pooled), `calibration_cohort` (per cohort and grade), `portfolio` (per
cohort), `portfolio_tests` (list: `n`, `d`, `dr`, `pd`, `p_jeffreys`,
`p_binomial`, `hl_chi2`, `hl_df`, `hl_p`, `multi_period_z`,
`multi_period_p`, `brier`), `discrimination`, `stability` (`psi` table,
`migration`, `concentration`), `summary` (one row per test with
`statistic`, `p_value`, `light`), `light` (the worst light of the
summary), `n_cohorts`, `alpha`, `lights`. `portfolio_tests` also carries
`critical`, `z`, `p_normal`, `n_cohorts` and `pd_column`; the object
also has `horizon`, `by`, `pd_column` and `target`.

## Details

- Calibration:

  Per grade (pooled over cohorts) and per cohort and grade: Jeffreys
  `p = F_Beta(PD; D + 1/2, N - D + 1/2)`, the binomial `P(X >= D)` with
  its critical count at `alpha`, the normal `z`, and the traffic light
  on the Jeffreys p-value. Portfolio: the same tests on the totals,
  Hosmer-Lemeshow over the grades (`K - 2` degrees of freedom), the
  multi-period normal test over the cohort default rates and the Brier
  score.

- Discrimination:

  AUC, Gini and KS with a bootstrap interval
  ([`scr_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_metrics.md))
  on the score when a `score` column exists, otherwise on the grade; the
  `S` statistic against `auc_init` (`(AUC_init - AUC_curr) / se`,
  Hanley-McNeil), `p = 1 - Phi(S)`.

- Stability:

  PSI of the grade distribution against the development sample per
  cohort
  ([`scr_psi()`](https://evandeilton.github.io/scorecraft/reference/scr_psi.md));
  the migration matrix pooled over the cohorts whose end date is
  observed
  ([`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md));
  the concentration test on the coefficient of variation of the latest
  cohort against `cv_init`.

## See also

Other irb-pd:
[`predict.scr_grades()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_grades.md),
[`predict.scr_pd()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_pd.md),
[`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md),
[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md),
[`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md),
[`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md),
[`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md),
[`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md),
[`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 40, n_boot = 10)
res <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                  date_col = "ref_date")
sc <- scr_scorecard(res)
pd <- scr_pd(scr_moc(scr_grades(sc, n_grades = 6, min_defaults = 10), "C", method = "ci_binomial"))
# the validation panel: default flag at every month plus the grade at the
# cohort start; here the behavioural score of the panel is graded with the
# cut points of the PD model
d <- scr_default(scr_demo_panel, "id", "ref_date", dpd = "dpd", config = cfg)
pnl <- merge(d$flags, scr_demo_panel[, c("id", "ref_date", "score")],
             by.x = c("id", "date"), by.y = c("id", "ref_date"))
pnl$grade <- predict(pd, score = pnl$score, type = "grade")
v <- scr_pd_validate(pd, pnl, id = "id", date = "date", default = "default",
                     grade = "grade", score = "score", by = "quarter")
v
#> <scr_pd_validation> target "default" | 8 quarterly cohorts, 12-month window | overall light: RED
#>   portfolio: N 4,568 | D 562 | DR 12.30% vs pd_final 10.54% | Jeffreys p 0.0001 | binomial p 0.0001 (critical 517) | HL chi2 51.00 (p 0.0000) | multi-period z 4.53
#>   grade       n     d       dr       pd    p_jeff   p_binom light 
#>   1        3373   234    6.94%    4.75%    0.0000    0.0000 red   
#>   2         498   103   20.68%   15.26%    0.0006    0.0007 red   
#>   3         475   125   26.32%   30.54%    0.9782    0.9808 green 
#>   4         222   100   45.05%   45.23%    0.5217    0.5485 green 
#>   discrimination (score): AUC 0.7682 [0.7517, 0.7832] vs initial 0.7394 | S -2.38, p 0.9914 | KS 0.4177
#>   stability: grade PSI 0.7658 (shift, adjusted shift) at cohort 2024-10-01 | MWB up - / down - | CV 1.158 vs 0.462 (p 0.2213)
v$summary
#>                    test     level   statistic      p_value  light
#>                  <char>    <char>       <num>        <num> <char>
#>  1:            jeffreys portfolio   0.1230298 7.604480e-05    red
#>  2: jeffreys_grades_red     grade   2.0000000 9.742426e-09    red
#>  3:            binomial portfolio 517.0000000 8.340461e-05    red
#>  4:              normal portfolio   3.8701036 5.439457e-05    red
#>  5:     hosmer_lemeshow portfolio  51.0038064 8.407448e-12    red
#>  6:        multi_period portfolio   4.5283667 2.972068e-06    red
#>  7:      auc_vs_initial portfolio  -2.3811341 9.913703e-01  green
#>  8:          psi_grades portfolio   0.7658293           NA    red
#>  9: migration_mwb_upper portfolio          NA           NA   <NA>
#> 10:    concentration_cv portfolio   1.1575073 2.213365e-01  green
```
