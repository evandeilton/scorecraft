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
