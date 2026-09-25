# Variables that cross several targets

Which variables were approved on how many targets. A stable core across
targets is the best argument in favour of a variable.

## Usage

``` r
scr_core(x, min_targets = 2L)
```

## Arguments

- x:

  An object from
  [`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md),
  or a named list of `scr_result`.

- min_targets:

  Minimum number of targets to enter the result.

## Value

A `data.table` with `feature`, `n_targets`, `targets` and `mean_rank`.

## See also

Other portfolio:
[`scr_compare()`](https://evandeilton.github.io/scorecraft/reference/scr_compare.md),
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
