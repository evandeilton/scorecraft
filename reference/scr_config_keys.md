# Dictionary of configuration keys

One row per
[`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md)
key, with the stage it acts on, the default value and what it controls.

## Usage

``` r
scr_config_keys(stage = NULL)
```

## Arguments

- stage:

  Optional filter by stage (`0` to `7` for the scorecard pipeline, `8`
  to `12` for the IRB models). `NULL` returns everything.

## Value

A `data.frame` with `key`, `stage`, `default` and `description`.

## See also

Other configuration:
[`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md),
[`scr_presets()`](https://evandeilton.github.io/scorecraft/reference/scr_presets.md),
[`scr_verbose()`](https://evandeilton.github.io/scorecraft/reference/scr_verbose.md)

## Examples

``` r
head(scr_config_keys(), 8)
#>              key stage  default
#> 1         preset     0 moderate
#> 2      objective     0     risk
#> 3           seed     0     2203
#> 4        nthread     0        2
#> 5        verbose     0     TRUE
#> 6   oot_date_col     0     NULL
#> 7  holdout_ratio     0     0.30
#> 8 special_values     1     -999
#>                                                                     description
#> 1                                             Tightness of the selection funnel
#> 2 Convention: target=1 is an undesirable (risk) or desirable (propensity) event
#> 3                                                     Seed of everything random
#> 4                          Parallel workers (binning by column, bootstrap, CSI)
#> 5                                                             Progress messages
#> 6                                            Date column of the out-of-time cut
#> 7                                                      Target hold-out fraction
#> 8                                                            Business sentinels
scr_config_keys(stage = 5)
#>             key stage             default
#> 1    base_score     5                 600
#> 2     base_odds     5                  50
#> 3           pdo     5                  20
#> 4     direction     5                NULL
#> 5  align_method     5          regression
#> 6   align_bands     5                  10
#> 7  points_style     5 base_plus_deviation
#> 8  points_round     5                TRUE
#> 9    challenger     5                NULL
#> 10 max_abs_coef     5                  15
#> 11       n_boot     5                 200
#> 12     ci_level     5                0.95
#> 13 score_groups     5                  10
#>                                                      description
#> 1                                   Reference score of the scale
#> 2  Odds at the reference score (in the orientation of direction)
#> 3                                      Points to double the odds
#> 4                Scale direction; NULL derives it from objective
#> 5                  regression (bands + ln(odds) ~ raw) or direct
#> 6                              Bands of the alignment regression
#> 7             Points: base + deviation, or distributed intercept
#> 8                                           Round points per bin
#> 9             Tree challenger (xgboost/lightgbm), without points
#> 10                    Maximum absolute glm coefficient tolerated
#> 11                      Bootstrap CI resamples (always computed)
#> 12                                                      CI level
#> 13                                      Bands of the score gains
```
