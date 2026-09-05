# Apply an alignment to raw scores

Apply an alignment to raw scores

## Usage

``` r
# S3 method for class 'scr_align'
predict(object, raw, type = c("score", "prob"), ...)
```

## Arguments

- object:

  An object from
  [`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md).

- raw:

  Raw scores on the same scale used in the fit.

- type:

  `"score"` (default) returns points; `"prob"` returns the calibrated
  event probability implied by the alignment.

- ...:

  Ignored.

## Value

A numeric vector of the length of `raw`.

## See also

Other production:
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md),
[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md),
[`scr_monitoring_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_monitoring_plan.md),
[`scr_reasons()`](https://evandeilton.github.io/scorecraft/reference/scr_reasons.md),
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)

## Examples

``` r
set.seed(3)
y   <- stats::rbinom(2000, 1, 0.15)
raw <- stats::qlogis(0.15) + 1.3 * y + stats::rnorm(2000)
al  <- scr_align(raw, y)
head(predict(al, raw))
#> [1] 545.4062 603.0933 597.0212 642.2758 539.8784 586.7383
head(predict(al, raw, type = "prob"))
#> [1] 0.117124721 0.017649730 0.021694049 0.004599538 0.138432936 0.030697183
```
