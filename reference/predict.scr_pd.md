# Predict grade and PD from an scr_pd object

Predict grade and PD from an scr_pd object

## Usage

``` r
# S3 method for class 'scr_pd'
predict(
  object,
  newdata = NULL,
  score = NULL,
  type = c("grade", "pd", "pd_final", "score"),
  ...
)
```

## Arguments

- object:

  An
  [`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md)
  object.

- newdata:

  A table with the source columns of the scorecard, scored with
  [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md);
  ignored when `score` is given.

- score:

  Production scores, as an alternative to `newdata`.

- type:

  `"grade"`, `"pd"` (calibrated individual PD), `"pd_final"` (grade PD
  after MoC and floor) or `"score"`.

- ...:

  Ignored.

## Value

A vector of the length of the input.

## See also

Other irb-pd:
[`predict.scr_grades()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_grades.md),
[`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md),
[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md),
[`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md),
[`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md),
[`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md),
[`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md),
[`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md),
[`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 40, n_boot = 10)
d <- scr_demo[, c("default", "ref_date", "ds_region", "ds_band", "vl_score_01",
                  "vl_score_02", "vl_score_05", "vl_score_10", "vl_hist_01")]
res <- scr_select(d, "default", config = cfg, date_col = "ref_date")
sc <- scr_scorecard(res)
pd <- scr_pd(scr_grades(sc, n_grades = 6, min_defaults = 10))
predict(pd, score = c(480, 560, 640), type = "pd_final")
#> [1] 0.29761905 0.12701613 0.05227273
head(predict(pd, newdata = scr_demo[1:10, ], type = "grade"))
#> [1] 4 1 1 4 3 1
```
