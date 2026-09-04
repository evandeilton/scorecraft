# Stages 3 and 4: multi-strategy selection and consensus

Trains the classifiers enabled in the configuration on the WOE columns
of the eligible pool, measures each on the hold-out (AUC/KS/Gini with a
bootstrap CI) and combines the votes:

## Usage

``` r
scr_model(bins, config = scr_config())
```

## Arguments

- bins:

  An object from
  [`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md).

- config:

  An object from
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md).

## Value

An `scr_models` object with `votes` (one row per model and feature),
`metrics` (one row per model, with CI), `consensus` (`table`,
`selected`, `meta`) and the originating `bins`.

## Details


    consensus_score = mean of the importance rank percentiles, weighted by the
                      hold-out Gini of each model
    votes           = how many models elected the feature (top-K, or non-zero
                      coefficient in the elastic net)

The final cut respects `[target_min, target_max]`. If the strict
consensus does not reach `target_min`, relaxation happens in **named**,
recorded steps (`min_votes` reduced; completed by score), never
resurrecting a feature failed by an earlier gate.

## See also

Other stages:
[`predict.scr_align()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_align.md),
[`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md),
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
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
sp <- scr_split(scr_demo, "default", date_col = "ref_date", drop = "id")
#>   OOT: 4 period(s) in train, 2 in hold-out (hold-out starts at 2026-05-01, 33.3% of rows)
md <- scr_model(scr_bin(scr_triage(sp, cfg), cfg), cfg)
md
#> <scr_models> 3 model(s) | pool 12 | approved 12 | relaxation: none
#>   glmnet    AUC 0.7345 [0.7028, 0.7723]  KS 0.3842  votes 12
#>   xgboost   AUC 0.7375 [0.7065, 0.7762]  KS 0.3695  votes 12
#>   lightgbm  AUC 0.7236 [0.6922, 0.7608]  KS 0.3641  votes 12
md$consensus$selected
#>  [1] "vl_score_01" "vl_score_02" "vl_score_04" "ds_faixa"    "vl_tardio"  
#>  [6] "ds_regiao"   "vl_score_06" "vl_score_07" "vl_score_05" "ds_canal"   
#> [11] "vl_score_10" "vl_hist_04" 
```
