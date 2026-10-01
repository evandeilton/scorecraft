# Thresholds of the red / amber / green lights

The editable table read by
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md):
one row per metric with its thresholds and the rule that turns a value
into a light. Edit a value, or drop a row to leave a metric out, and
pass the table as `plan`.

## Usage

``` r
scr_rag_plan(objective = c("risk", "propensity"))
```

## Arguments

- objective:

  `"risk"` or `"propensity"`: the Gini ratio thresholds are looser under
  propensity (0.90 / 0.80 against 0.95 / 0.90), and the calibration
  checks are one-sided under risk, two-sided under propensity (see the
  section Calibration under risk and propensity).

## Value

A `data.frame` with `family`, `metric`, `green`, `red`, `green_hi`,
`red_hi` (upper edges of the two-sided rule), `higher_better`, `rule`
and `note`.

## Rules

Every rule follows one convention: a light is amber or red only when the
confidence interval shows the metric beyond the threshold (for a
p-value, when the test rejects); with too few events it is `"grey"`.

- `ci`:

  With `higher_better`: green when the upper bound of the interval
  reaches `green`, red when it stays below `red`, amber in between; the
  mirror image on the lower bound when lower is better.

- `threshold`:

  The same on the value alone.

- `p_value`:

  Red at or below `red`, amber at or below `green`, green above.

- `interval`:

  Two-sided: green when the interval meets `[green, green_hi]`, red when
  it lies entirely outside `[red, red_hi]`, amber otherwise.

- `psi`:

  Effect and significance: red when the index reaches `red` **and**
  exceeds the n-adjusted critical value (Yurdakul and Naranjo, 2020),
  amber when it reaches `green` and exceeds it, green otherwise.
  Significance alone never colors a light, which on a large sample would
  flag every negligible shift.

- `count`:

  Green at or below `green`, red at or above `red` (never when `red` is
  `NA`), amber in between.

- `none`:

  Reported without a light.

Every threshold is a convention of this package, documented in `note`,
except where a source is cited there; adjust them to the validation
policy in force.

## Calibration under risk and propensity

Under `objective = "risk"` every calibration check is one-sided:
over-prediction (more expected than observed events) is prudent and only
under-prediction is penalized. `oe_ratio` then follows the rule `ci`
with lower better, lit on the lower bound of its interval: green when it
is at or below 1.10, red above 1.25, amber in between; a conservative
model (O/E well below 1) stays green. `band_calibration` tests every
band against under-prediction only. Under `"propensity"` both directions
count: `oe_ratio` follows the two-sided rule `interval` (green when the
interval meets `[0.90, 1.10]`, red when it lies outside `[0.80, 1.25]`)
and the band tests are two-sided.

## References

European Central Bank (2019). *Instructions for reporting the validation
results of internal models: IRB Pillar I models for credit risk*. ECB
Banking Supervision.

Yurdakul, B. and Naranjo, J. (2020). Statistical properties of the
population stability index. *Journal of Risk Model Validation*, 14(4),
89-100.

## See also

Other score-studies:
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md),
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md),
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md),
[`scr_score_cross()`](https://evandeilton.github.io/scorecraft/reference/scr_score_cross.md),
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)

## Examples

``` r
plan <- scr_rag_plan()
plan[, c("family", "metric", "green", "red", "rule")]
#>            family           metric green  red      rule
#> 1  discrimination       gini_ratio  0.95 0.90        ci
#> 2  discrimination     auc_change_p  0.05 0.01   p_value
#> 3  discrimination               ks    NA   NA      none
#> 4     calibration         oe_ratio  1.10 1.25        ci
#> 5     calibration band_calibration  0.00 2.00     count
#> 6       stability        score_psi  0.10 0.25       psi
#> 7       stability       rank_order  0.00 2.00     count
#> 8       variables              csi  0.10 0.25       psi
#> 9       variables         iv_ratio  0.80 0.50 threshold
#> 10      variables    woe_sign_flip  0.00   NA     count
# a stricter policy on the score PSI
plan$green[plan$metric == "score_psi"] <- 0.05
```
