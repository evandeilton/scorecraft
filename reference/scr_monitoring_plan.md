# Monitoring plan read by scr_monitor()

A small `item`/`value` table with the thresholds and the frozen score
bands of a scorecard. It is created by
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
from the configuration, written to the `Monitoring_Plan` sheet of the
strategy workbook by
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md),
and **read back** by
[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md):
change a threshold in the sheet, pass the file (or the edited table) as
`plan`, and the flags follow the plan, not the configuration.

## Usage

``` r
scr_monitoring_plan(x, breaks = NULL)
```

## Arguments

- x:

  An object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
  or a configuration from
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md)
  plus `breaks`.

- breaks:

  Frozen score bands, when `x` is a configuration.

## Value

A `data.frame` of class `scr_monitoring_plan` with the items
`psi_score_fixed_moderate`, `psi_score_fixed_action`,
`psi_adjusted_alpha`, `csi_variable_fixed_moderate`,
`csi_variable_fixed_action`, `score_bands`, `min_events_per_period` and
`threshold_source`.

## See also

Other production:
[`predict.scr_align()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_align.md),
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md),
[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md),
[`scr_reasons()`](https://evandeilton.github.io/scorecraft/reference/scr_reasons.md),
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)

## Examples

``` r
plan <- scr_monitoring_plan(scr_config(), breaks = c(-Inf, 500, 550, 600, Inf))
plan
#>                          item
#> 1    psi_score_fixed_moderate
#> 2      psi_score_fixed_action
#> 3          psi_adjusted_alpha
#> 4 csi_variable_fixed_moderate
#> 5   csi_variable_fixed_action
#> 6                 score_bands
#> 7       min_events_per_period
#> 8            threshold_source
#>                                                                                       value
#> 1                                                                                      0.10
#> 2                                                                                      0.25
#> 3                                                                                      0.05
#> 4                                                                                      0.10
#> 5                                                                                      0.25
#> 6                                                                           500 | 550 | 600
#> 7                                                                                       100
#> 8 0.10/0.25: market convention, no published authority; adjusted: Yurdakul & Naranjo (2020)
```
