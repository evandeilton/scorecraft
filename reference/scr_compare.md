# Compare runs across targets

One row per target, with the funnel, the hold-out performance of the
best model (with CI) and the warning signs.

## Usage

``` r
scr_compare(x)
```

## Arguments

- x:

  An object from
  [`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md),
  or a named list of `scr_result`.

## Value

A `data.table` with one row per successful target.

## See also

Other portfolio:
[`scr_core()`](https://evandeilton.github.io/scorecraft/reference/scr_core.md),
[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md),
[`scr_runset`](https://evandeilton.github.io/scorecraft/reference/scr_runset.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
r1 <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                 date_col = "ref_date")
r2 <- scr_select(scr_demo, "churn", config = cfg, drop = c("id", "default"),
                 date_col = "ref_date")
scr_compare(list(default = r1, churn = r2))
#>     target  rows train holdout event_rate candidates triage screening
#>     <char> <int> <int>   <int>      <num>      <int>  <int>     <int>
#> 1: default  4200  2800    1400     0.1425         37     37        20
#> 2:   churn  4200  2800    1400     0.2846         37     34        13
#>    holdout_ok  pool approved max_iv_approved n_iv_suspect best_model    auc
#>         <int> <int>    <int>           <num>        <int>     <char>  <num>
#> 1:         16    12       12           0.346            0    xgboost 0.7375
#> 2:         11     9        9           0.325            0     glmnet 0.7262
#>    auc_lo auc_hi     ks seconds             relaxation
#>     <num>  <num>  <num>   <num>                 <char>
#> 1: 0.7065 0.7762 0.3695       1                   none
#> 2: 0.7086 0.7544 0.3288       1 min_votes reduced to 1
scr_core(list(default = r1, churn = r2), min_targets = 2)
#>        feature n_targets mean_rank        targets
#>         <char>     <int>     <num>         <char>
#> 1: vl_score_02         2       2.0 churn, default
#> 2: vl_score_04         2       3.5 churn, default
#> 3:   ds_region         2       6.0 churn, default
#> 4: vl_score_06         2       6.0 churn, default
#> 5: vl_score_05         2       6.0 churn, default
#> 6: vl_score_07         2       7.5 churn, default
#> 7:  vl_hist_04         2      10.5 churn, default
```
