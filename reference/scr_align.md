# Stage 5: align a raw score to the declared scale

Takes the raw score of **any** engine (the scorecard logit, the output
of a tree challenger, a legacy score) to the scale defined by
`base_score`, `base_odds` and `pdo`, recording `odds_orientation` on the
object. This is what makes two scorecards directly comparable. It runs
automatically inside
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
(decision D9); it is exposed to align other scores to the same scale.

## Usage

``` r
scr_align(
  raw,
  y,
  base_score = 600,
  base_odds = 50,
  pdo = 20,
  direction = c("higher_is_safer", "higher_is_riskier"),
  method = c("regression", "direct"),
  n_bands = 10L,
  laplace = 0.5,
  weights = NULL
)
```

## Arguments

- raw:

  Raw score: an event logit (or any score on which a higher value means
  a higher probability of the event).

- y:

  0/1 outcome vector, same length as `raw`.

- base_score:

  Score at which the odds are `base_odds`.

- base_odds:

  Odds at `base_score`, positive, in the orientation of `direction`.

- pdo:

  Points that double the odds, positive.

- direction:

  `"higher_is_safer"` or `"higher_is_riskier"`.

- method:

  `"regression"` (default) or `"direct"`.

- n_bands:

  Bands of the calibration regression.

- laplace:

  Smoothing of the counts per band.

- weights:

  Optional weights per observation (sample reweighting).

## Value

An `scr_align` object with `base_score`, `base_odds`, `pdo`,
`direction`, `odds_orientation`, `factor`, `offset`, `sign`,
`calibration` (`method`, `intercept`, `slope`, `r2`, `n_bands`, `bands`)
and the final coefficients `a` and `b` of `score = a + b * raw`. Use
[`predict.scr_align()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_align.md)
to apply it.

## Mechanism

With `method = "regression"` (default): the raw score is banded by
quantiles on the reference data, the empirical log-odds of every band is
computed with Laplace smoothing in the orientation `direction` implies,
and a regression weighted by band size fits \$\$\ln(\mathrm{odds}) = I +
S \cdot \mathrm{raw}.\$\$ This absorbs sample reweighting,
miscalibration of the WOE fit and prior shift. It then composes with the
PDO map: \$\$\mathrm{factor} = \mathrm{pdo}/\ln 2,\quad \mathrm{offset}
= \mathrm{base\\score} -
\mathrm{factor}\cdot\ln(\mathrm{base\\odds}),\$\$ \$\$\mathrm{score} =
\mathrm{offset} + \mathrm{factor}\\(I + S\cdot\mathrm{raw}) = a +
b\cdot\mathrm{raw}.\$\$

With `method = "direct"`, the model is assumed calibrated: `I = 0` and
`S` is the sign of the direction (`-1` under `higher_is_safer`, `+1`
under `higher_is_riskier`), that is, `ln(odds)` is `raw` itself in the
right orientation.

## Odds orientation

`base_odds` is always expressed in the orientation `direction` implies:
non-event:event (`"safe:event"`) under `higher_is_safer`,
event:non-event (`"event:safe"`) under `higher_is_riskier`. The same
word, `odds`, changes meaning between the two, and that is the most
common sign trap in the literature; hence the object records
`odds_orientation` explicitly.

## References

Siddiqi, N. (2006). *Credit Risk Scorecards*. Wiley, chapter 6.

## See also

Other stages:
[`predict.scr_align()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_align.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md),
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md),
[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md),
[`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md),
[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md),
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md),
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)

## Examples

``` r
set.seed(3)
y   <- stats::rbinom(4000, 1, 0.15)
raw <- stats::qlogis(0.15) + 1.3 * y + stats::rnorm(4000, sd = 1.2)
al  <- scr_align(raw, y, base_score = 600, base_odds = 50, pdo = 20)
al
#> <scr_align> 600 points at odds 50:1 (safe:event), PDO 20 | higher_is_safer
#>   factor = 28.853901 | offset = 487.122876
#>   calibration: ln(odds) = 0.784416 + -0.827142 * raw  (adj. R2 = 0.9900, 10 bands)
#>   score = 509.756344 + -23.866273 * raw
head(predict(al, raw))
#> [1] 579.0785 545.5461 534.3009 575.8285 543.0500 562.7087
head(predict(al, raw, type = "prob"))
#> [1] 0.03966021 0.11662403 0.16313782 0.04417982 0.12583606 0.06788722

# propensity: more points = more event, odds event:non-event
scr_align(raw, y, base_score = 500, base_odds = 1/9, pdo = 40,
          direction = "higher_is_riskier")
#> <scr_align> 500 points at odds 0.1111111:1 (event:safe), PDO 40 | higher_is_riskier
#>   factor = 57.707802 | offset = 626.797000
#>   calibration: ln(odds) = -0.784416 + 0.827142 * raw  (adj. R2 = 0.9900, 10 bands)
#>   score = 581.530064 + 47.732546 * raw
```
