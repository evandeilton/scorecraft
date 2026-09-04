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

Other stages:
[`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md),
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md),
[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md),
[`scr_monitoring_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_monitoring_plan.md),
[`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md),
[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md),
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md),
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)
