# Grade a score vector with the cut points of an scr_grades object

Grade a score vector with the cut points of an scr_grades object

## Usage

``` r
# S3 method for class 'scr_grades'
predict(object, score, type = c("grade", "pd"), ...)
```

## Arguments

- object:

  An
  [`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md)
  object.

- score:

  Numeric production scores.

- type:

  `"grade"` (integer grade) or `"pd"` (calibrated individual PD).

- ...:

  Ignored.

## Value

A vector of the length of `score`.

## See also

Other irb-pd:
[`predict.scr_pd()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_pd.md),
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
gr <- scr_grades(sc, scr_calibrate(sc, target = 0.06), n_grades = 7, min_defaults = 10)
predict(gr, score = c(480, 560, 640))
#> [1] 5 2 1
predict(gr, score = c(480, 560, 640), type = "pd")
#> [1] 0.30171014 0.02629432 0.00168493
```
