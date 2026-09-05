# Pipeline configuration

Builds the configuration object that crosses every stage, from
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md)
to
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md).
A preset sets the tightness of the selection funnel; any individual key
can be overridden through `...`.

## Usage

``` r
scr_config(preset = c("moderate", "aggressive", "lazy"), ...)
```

## Arguments

- preset:

  One of `"moderate"` (default), `"aggressive"` or `"lazy"`.

- ...:

  Overrides of any configuration key, by name. `NULL` means "keep the
  preset value", not "delete the key". An unknown name is an error, on
  purpose: a silent override leaves dead configuration in the file.

## Value

An object of class `scr_config`: a named list with every key resolved.

## Presets

A preset touches four keys and nothing else: `target_max`, `min_votes`,
`corr_cutoff` and `iv_min`.

|                |                      |             |               |          |
|----------------|----------------------|-------------|---------------|----------|
| preset         | variables at the end | `min_votes` | `corr_cutoff` | `iv_min` |
| `"aggressive"` | 10 to 15             | 3           | 0.60          | 0.03     |
| `"moderate"`   | 10 to 25             | 2           | 0.70          | 0.02     |
| `"lazy"`       | 10 to 40             | 1           | 0.80          | 0.02     |

Use
[`scr_presets()`](https://evandeilton.github.io/scorecraft/reference/scr_presets.md)
to see the resolved table and
[`scr_config_keys()`](https://evandeilton.github.io/scorecraft/reference/scr_config_keys.md)
for the full key dictionary.

## Risk or propensity (`objective`)

The two literatures use the same mathematics with opposite conventions.
In credit and fraud, `target = 1` is the **bad** case and the scorecard
is built so that more points mean less risk. In propensity, `target = 1`
is the **good** case and the campaign list needs more points to mean a
higher chance of engaging.

|                     |                     |                           |
|---------------------|---------------------|---------------------------|
|                     | `"risk"` (default)  | `"propensity"`            |
| `target = 1` means  | undesirable event   | desirable event           |
| Points scale        | more points = safer | more points = more likely |
| Derived `direction` | `"higher_is_safer"` | `"higher_is_riskier"`     |
| `odds_orientation`  | `safe:event`        | `event:safe`              |

**`objective` does not touch the selection.** It does not change the
modelled target, the cut points, the IV or the shortlist; it acts on the
direction of the points scale, on the odds orientation of the alignment
and on the vocabulary of the reports. To model the other class as the
event, the argument is `event_level` in
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md)
and
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md),
and that one, unlike this, rewrites everything.

## Binning algorithm (`algorithm`)

`"jedi"` is the default and stays exposed side by side with the
alternatives, never hidden behind an `"auto"`. Choices with distinct
properties: `"ivb"`, `"dp"` and `"sblp"` are provably optimal for
categoricals; `"cm"` (ChiMerge) and `"fetb"` have a principled stopping
rule; `"ir"` (isotonic) guarantees monotone WOE; `"fast_mdlp"` is the
faithful Fayyad-Irani. The full list is in
[`OptimalBinningWoE::obwoe_algorithms()`](https://evandeilton.github.io/OptimalBinningWoE/reference/obwoe_algorithms.html).
A numeric-only or categorical-only algorithm applies where it is valid
and the other type falls back to `"jedi"`.

## The Information Value gate

- `iv_min`:

  Admission floor. Fails with `IV_BELOW_MIN`.

- `iv_max`:

  Admission ceiling. Fails with `IV_SUSPICIOUS`. `1.00` (default)
  tolerates a legitimately strong predictor and cuts the absurd; `0.50`
  is the engine default, calibrated for credit default.

- `iv_suspect`:

  Only the threshold of the report warning. Fails nothing.

The real leakage detector is `allow_degenerate = FALSE`: a bin with no
events or no non-events is the symptom that has no innocent explanation.

## Scorecard scale

`base_score`, `base_odds` and `pdo` are one statement: *at `base_score`
points the odds are `base_odds`, and every `pdo` points they double*.
`base_odds` is always expressed in the orientation `direction` implies
(non-event:event under `higher_is_safer`; event:non-event under
`higher_is_riskier`), and the alignment object records
`odds_orientation` so this is never implicit. The classic 600/50/20 is
Siddiqi's (2006) textbook example, not a parameter published by any
bureau. `align_method = "regression"` (default) takes the raw score to
that scale by regressing empirical log-odds on score bands, which
absorbs reweighting, miscalibration and prior shift; `"direct"` assumes
the model is calibrated and uses the logit as is.

## References

Siddiqi, N. (2006). *Credit Risk Scorecards: Developing and Implementing
Intelligent Credit Scoring*. Wiley.

## See also

[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
to use the configuration,
[`scr_presets()`](https://evandeilton.github.io/scorecraft/reference/scr_presets.md)
to compare presets,
[`scr_config_keys()`](https://evandeilton.github.io/scorecraft/reference/scr_config_keys.md)
for the key dictionary.

Other configuration:
[`scr_config_keys()`](https://evandeilton.github.io/scorecraft/reference/scr_config_keys.md),
[`scr_presets()`](https://evandeilton.github.io/scorecraft/reference/scr_presets.md),
[`scr_verbose()`](https://evandeilton.github.io/scorecraft/reference/scr_verbose.md)

## Examples

``` r
cfg <- scr_config()
cfg
#> <scr_config> preset "moderate" | objective "risk" | seed 2203 | threads 2
#> 
#> Convention
#>   target = 1             target = 1 is the BAD case
#>   points scale           more points = lower probability of the event (safer) [higher_is_safer]
#> 
#> Funnel
#>   variables at the end   10 to 25
#>   minimum votes          2
#>   admissible IV          [0.02, 1)  warning at 0.5
#>   correlation            0.7 (spearman)
#> 
#> Binning
#>   bins                   3 to 7, algorithm "jedi"
#>   monotonicity           numeric (weak)
#>   smallest bin           2.0%
#> 
#> Scorecard
#>   scale                  600 points at odds 50:1, PDO 20
#>   alignment              regression (10 bands)
#>   challenger             none
#>   bootstrap CI           200 resamples, 95%
#> 
#> Data
#>   sentinels              -999
#>   derived at the end     no (diagnostic only)
#>   hold-out               30.0%
#> 
#> Models
#>   enabled                glmnet, xgboost, ranger, lightgbm
#>   row cap                200,000

# propensity: more points = more likely to have the event
scr_config(objective = "propensity")$objective
#> [1] "propensity"

# NULL keeps the preset value (here, iv_min = 0.03 from aggressive)
scr_config("aggressive", iv_min = NULL)$iv_min
#> [1] 0.03

# a wrong name fails loudly instead of becoming dead configuration
try(scr_config(iv_maximum = 1))
#> Error : scr_config(): unknown key(s): iv_maximum. Fix the name - a silent override hides dead configuration.
```
