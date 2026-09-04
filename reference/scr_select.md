# Select variables for the scorecard

Shortcut that chains
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md)
and
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md)
on a table and a binary target, and returns an object with the
shortlist, the complete audit funnel, the gains table and the production
SQL of the approved variables. Every stage remains callable on its own
for whoever wants more control (hybrid interface, decision D13).

## Usage

``` r
scr_select(
  data,
  target,
  config = scr_config(),
  drop = character(),
  date_col = config$oot_date_col,
  event_level = NULL,
  export = NULL,
  copy = TRUE
)
```

## Arguments

- data:

  A `data.frame` or `data.table` with the target, the candidates and, if
  any, the date column of the out-of-time cut.

- target:

  Name of the target column (0/1, logical, or a two-level
  factor/character).

- config:

  An object from
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md).

- drop:

  Columns that are never candidates. They stay in the funnel as
  `00.config`.

- date_col:

  Date column of the out-of-time cut. Defaults to `config$oot_date_col`.

- event_level:

  Which target value counts as the event; see
  [`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md).

- export:

  Directory to write the deliverables to. `NULL` (default) writes
  nothing; use
  [`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
  later.

- copy:

  If `TRUE` (default), works on a copy of `data`.

## Value

An object of class `scr_result`. Read it with
[`scr_selected()`](https://evandeilton.github.io/scorecraft/reference/scr_selected.md),
[`scr_funnel()`](https://evandeilton.github.io/scorecraft/reference/scr_funnel.md),
[`scr_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_gains.md),
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md),
[`scr_leakage()`](https://evandeilton.github.io/scorecraft/reference/scr_leakage.md)
and [`summary()`](https://rdrr.io/r/base/summary.html); continue with
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md);
write it with
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md).

## Reproducibility

With the same `data`, the same `target` and the same `config$seed`, the
result is identical with one or several `nthread`: the seed governs the
random split, the cross-validation, the classifier subsample, the trees
and the bootstrap, and the binning is deterministic per column.

## See also

[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md)
for several targets straight from the database,
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
for the next step.

Other stages:
[`predict.scr_align()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_align.md),
[`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md),
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md),
[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md),
[`scr_monitoring_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_monitoring_plan.md),
[`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md),
[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md),
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
res
#> <scr_result> target "default"
#>   4,200 rows (train 2,800 / hold-out 1,400) | split out-of-time at 2026-05-01
#>   event: 14.25% on train, 14.50% on hold-out | 1.5s
#>   convention: risk (target=1 is the bad case)
#> 
#> Funnel
#>   candidates        38 ############################
#>   1. triage         37 ###########################
#>   2. binning        37 ###########################
#>   3. screening      20 ###############
#>   4. hold-out       16 ############
#>   5. correlation    12 #########
#>   6. consensus      12 #########
#> 
#> Approved: 12
#>    1. vl_score_01                                  IV  0.346  KS 0.198
#>    2. vl_score_02                                  IV  0.172  KS 0.156
#>    3. vl_score_04                                  IV  0.124  KS 0.120
#>    4. ds_faixa                                     IV  0.081  KS 0.110
#>    5. vl_tardio                                    IV  0.071  KS 0.120
#>   ... (+7) - scr_selected() for the list
#> 
#> Models (hold-out)
#>   glmnet    AUC 0.7345 [0.7028, 0.7723]  KS 0.3842
#>   xgboost   AUC 0.7375 [0.7065, 0.7762]  KS 0.3695
#>   lightgbm  AUC 0.7236 [0.6922, 0.7608]  KS 0.3641
#> 
#> Warnings
#>   - 3 derived flag(s) outside the deliverable by policy (allow_derived_final)
scr_selected(res)
#>  [1] "vl_score_01" "vl_score_02" "vl_score_04" "ds_faixa"    "vl_tardio"  
#>  [6] "ds_regiao"   "vl_score_06" "vl_score_07" "vl_score_05" "ds_canal"   
#> [11] "vl_score_10" "vl_hist_04" 
head(scr_funnel(res, only_selected = TRUE))
#>        feature derived_from        type approved  exit_stage consensus_rank
#>         <char>       <char>      <char>   <lgcl>      <char>          <int>
#> 1: vl_score_01         <NA>     numeric     TRUE 07.approved              1
#> 2: vl_score_02         <NA>     numeric     TRUE 07.approved              2
#> 3: vl_score_04         <NA>     numeric     TRUE 07.approved              3
#> 4:    ds_faixa         <NA> categorical     TRUE 07.approved              4
#> 5:   vl_tardio         <NA>     numeric     TRUE 07.approved              5
#> 6:   ds_regiao         <NA> categorical     TRUE 07.approved              6
#>    consensus_score votes n_bins   total_iv iv_holdout        ks         psi
#>              <num> <int>  <int>      <num>      <num>     <num>       <num>
#> 1:       1.0000000     3      7 0.34639015 0.28772640 0.1981484 0.006635574
#> 2:       0.9090909     3      7 0.17206972 0.12336796 0.1564626 0.005346830
#> 3:       0.8181818     3      7 0.12430307 0.11773607 0.1199427 0.003216554
#> 4:       0.6377928     3      4 0.08054551 0.07804157 0.1100565 0.001317467
#> 5:       0.6367525     3      7 0.07109472 0.06384879 0.1201400 0.104196466
#> 6:       0.6345456     3      5 0.08464808 0.09714339 0.1141337 0.006365199
#>    psi_flag_adjusted iv_suspect triage_reason screen_reason holdout_reason
#>               <char>     <lgcl>        <char>        <char>         <char>
#> 1:            stable      FALSE            OK            OK             OK
#> 2:            stable      FALSE            OK            OK             OK
#> 3:            stable      FALSE            OK            OK             OK
#> 4:            stable      FALSE            OK            OK             OK
#> 5:             shift      FALSE            OK            OK             OK
#> 6:            stable      FALSE            OK            OK             OK
#>    prune_corr_with
#>             <char>
#> 1:            <NA>
#> 2:            <NA>
#> 3:            <NA>
#> 4:            <NA>
#> 5:            <NA>
#> 6:            <NA>
```
