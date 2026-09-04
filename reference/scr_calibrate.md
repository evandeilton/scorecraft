# Calibrate the alignment to a central tendency

Re-anchors the probability of default of a scorecard to a long-run
average default rate (the central tendency, CT) without touching the
points: the result is a **new** alignment `(I*, S*)` such that
`predict(alignment, raw, type = "prob")` is the calibrated PD, while the
scorecard keeps its own alignment for the score. Four methods:

## Usage

``` r
scr_calibrate(
  x,
  target,
  sample_rate = NULL,
  method = NULL,
  ar_target = NULL,
  segment = NULL,
  raw = NULL,
  y = NULL,
  sample = "holdout"
)
```

## Arguments

- x:

  An
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
  (uses the ln(odds) and outcome of `sample`), an
  [`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md)
  (pass `raw` and, for the two-parameter methods, `y`) or a numeric
  vector of event ln(odds) (aligned directly to the default 600/50/20
  scale).

- target:

  The central tendency: a number in `(0, 1)` or an `scr_dr` from
  [`scr_default_rate()`](https://evandeilton.github.io/scorecraft/reference/scr_default_rate.md)
  (its `lra$mean` is used). With `segment`, a named vector with one CT
  per segment.

- sample_rate:

  Event rate of the calibration sample; `NULL` uses the mean of `y`.

- method:

  `"intercept"`, `"logodds_ab"`, `"scaling"` or `"qmm"`; `NULL` uses
  `config$pd_calibration`.

- ar_target:

  Target accuracy ratio for `"logodds_ab"` and `"qmm"`.

- segment:

  Optional vector of segment labels, one per calibration row: one
  alignment per segment is fitted as well.

- raw, y:

  Raw ln(odds) and 0/1 outcome when `x` is not a scorecard.

- sample:

  Sample of the scorecard used for the calibration.

## Value

An object of class `scr_pd_calibration`: `alignment` (the new
`scr_align`), `alignment_before`, `method`, `ct`, `target_source`,
`sample_rate`, `shift` (change of the event intercept), `shift_prior`
(the closed-form King-Zeng shift), `slope_ratio` (`S* / S`),
`mean_pd_before`, `mean_pd_after`, `ar_before`, `ar_after` (observed),
`ar_implied_before`, `ar_implied_after`, `n`, `segments` (table and
alignments when `segment` is given), `ledger`.

## Details

- `"intercept"`:

  The prior-correction shift of King and Zeng (2001), \\\delta =
  \ln\[\tau(1-\bar y) / ((1-\tau)\bar y)\]\\, added to the event
  ln(odds); `S` unchanged, so the rank order and every discrimination
  statistic are untouched. The closed form is exact on the odds; when
  the calibration sample is available the shift is refined by a
  one-dimensional root so that the mean PD equals the CT exactly (the
  closed form is reported as `shift_prior`).

- `"logodds_ab"`:

  Tasche (2013): `ln(odds*) = a + b ln(odds)`, with `(a, b)` solving
  `mean(PD*) = CT` and implied accuracy ratio equal to `ar_target`
  (default: the accuracy ratio observed on the sample).

- `"qmm"`:

  Quasi-moment matching: the same two equations, with the target
  accuracy ratio taken from the PD distribution itself (the implied AR
  of the current PDs), so no outcome is needed.

- `"scaling"`:

  `PD* = PD * CT / ybar`. The proportional rescaling is not a logit map,
  so the slope is the least-squares projection of `logit(PD*)` on the
  ln(odds) and the intercept is solved to the CT.

## References

King, G. and Zeng, L. (2001). Logistic regression in rare events data.
*Political Analysis*, 9(2), 137-163.

Tasche, D. (2013). The art of probability-of-default curve calibration.
*Journal of Credit Risk*, 9(4), 63-103.

## See also

Other irb-pd:
[`predict.scr_grades()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_grades.md),
[`predict.scr_pd()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_pd.md),
[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md),
[`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md),
[`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md),
[`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md),
[`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md),
[`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md),
[`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md)

## Examples

``` r
set.seed(1)
l <- stats::qlogis(0.12) + stats::rnorm(2000)
y <- stats::rbinom(2000, 1, stats::plogis(l))
cal <- scr_calibrate(l, target = 0.04, y = y)
cal
#> <scr_pd_calibration> method intercept | CT 4.000% (numeric) | sample rate 16.450% | n 2,000
#>   event ln(odds)* = -1.642243 +1.000000 * ln(odds)   [prior shift -1.552934]
#>   alignment: I 0.000000 -> 1.642243 | S -1.000000 -> -1.000000
#>   mean PD 15.709% -> 4.000% | AR observed 0.5532 -> 0.5532 | AR implied 0.5061 -> 0.5237
mean(predict(cal$alignment, l, type = "prob"))
#> [1] 0.04
scr_calibrate(l, target = 0.04, y = y, method = "logodds_ab", ar_target = 0.55)
#> <scr_pd_calibration> method logodds_ab | CT 4.000% (numeric) | sample rate 16.450% | n 2,000
#>   event ln(odds)* = -1.570900 +1.065298 * ln(odds)   [prior shift -1.552934]
#>   alignment: I 0.000000 -> 1.570900 | S -1.000000 -> -1.065298
#>   mean PD 15.709% -> 4.000% | AR observed 0.5532 -> 0.5532 | AR implied 0.5061 -> 0.5500
```
