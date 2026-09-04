# Margin of conservatism, by category

Appends entries to the MoC ledger of an
[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md)
object. Category `"C"` (general estimation error) is quantified:
`"ci_timeseries"` takes the upper bound of a one-sided `level` interval
of the long-run average from the cohort series, \\t\_{q, T-1}\\
sd(DR_t)/\sqrt{T}\\ per grade; `"ci_binomial"` uses \\z_q
\sqrt{PD(1-PD)/n}\\ on the obligors (or obligor-years when a series
exists); `"bootstrap"` resamples the outcomes of the sample within each
grade and takes the `level` quantile of the default rate above the
estimate. Categories `"A"` (data and methodological deficiencies) and
`"B"` (changes in standards or environment) are expert quantities:
`value` (one number or one per grade, in PD units) and a non-empty
`reason` are mandatory. The ledger is append-only: `A` and `B` entries
accumulate, a new `C` supersedes the previous one (kept with
`active = FALSE`).

## Usage

``` r
scr_moc(
  x,
  category = c("A", "B", "C"),
  method = NULL,
  level = NULL,
  value = NULL,
  reason = NULL,
  dr = NULL,
  n_boot = 200L,
  seed = NULL
)
```

## Arguments

- x:

  An
  [`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md)
  object.

- category:

  `"A"`, `"B"` or `"C"`.

- method:

  For `"C"`: `"ci_timeseries"`, `"ci_binomial"` or `"bootstrap"`; `NULL`
  reads `config$pd_moc_method`.

- level:

  One-sided confidence level; `NULL` reads `config$pd_moc_level`.

- value:

  For `"A"`/`"B"`: the add-on in PD units, length 1 or one per grade.

- reason:

  Justification (mandatory for `"A"`/`"B"`).

- dr:

  Optional `scr_dr` by grade for `"ci_timeseries"`, keyed by the final
  grades of `x` (stored in `x$dr` when absent).

- n_boot, seed:

  Bootstrap resamples and seed for `"bootstrap"`.

## Value

The `scr_grades` object with the entries appended to `moc`.

## See also

Other irb-pd:
[`predict.scr_grades()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_grades.md),
[`predict.scr_pd()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_pd.md),
[`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md),
[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md),
[`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md),
[`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md),
[`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md),
[`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md),
[`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 40, n_boot = 10)
res <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                  date_col = "ref_date")
sc <- scr_scorecard(res)
gr <- scr_grades(sc, n_grades = 6, min_defaults = 10)
gr <- scr_moc(gr, "C", method = "ci_binomial")
gr <- scr_moc(gr, "A", value = 0.002, reason = "missing unlikeliness-to-pay trigger before 2024")
gr$moc
#>       id category      method level grade      pd_be      value
#>    <int>   <char>      <char> <num> <int>      <num>      <num>
#> 1:     1        C ci_binomial  0.95     1 0.03382664 0.01367268
#> 2:     1        C ci_binomial  0.95     2 0.12800000 0.02457568
#> 3:     1        C ci_binomial  0.95     3 0.26567164 0.03969379
#> 4:     1        C ci_binomial  0.95     4 0.36956522 0.08277496
#> 5:     2        A      manual    NA     1 0.03382664 0.00200000
#> 6:     2        A      manual    NA     2 0.12800000 0.00200000
#> 7:     2        A      manual    NA     3 0.26567164 0.00200000
#> 8:     2        A      manual    NA     4 0.36956522 0.00200000
#>                                             reason active       date
#>                                             <char> <lgcl>     <char>
#> 1:  estimation error, ci_binomial at 95% one-sided   TRUE 2026-09-04
#> 2:  estimation error, ci_binomial at 95% one-sided   TRUE 2026-09-04
#> 3:  estimation error, ci_binomial at 95% one-sided   TRUE 2026-09-04
#> 4:  estimation error, ci_binomial at 95% one-sided   TRUE 2026-09-04
#> 5: missing unlikeliness-to-pay trigger before 2024   TRUE 2026-09-04
#> 6: missing unlikeliness-to-pay trigger before 2024   TRUE 2026-09-04
#> 7: missing unlikeliness-to-pay trigger before 2024   TRUE 2026-09-04
#> 8: missing unlikeliness-to-pay trigger before 2024   TRUE 2026-09-04
```
