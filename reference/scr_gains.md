# Gains table, at bin level

One row per variable and bin, with counts, event rate, WOE, IV, lift,
cumulative KS, precision and recall, plus the hold-out IV and the PSI of
the variable.

## Usage

``` r
scr_gains(x, only_selected = TRUE)
```

## Arguments

- x:

  An object from
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md).

- only_selected:

  If `TRUE` (default), only the approved variables.

## Value

A `data.table` at bin level.

## See also

Other accessors:
[`scr_funnel()`](https://evandeilton.github.io/scorecraft/reference/scr_funnel.md),
[`scr_leakage()`](https://evandeilton.github.io/scorecraft/reference/scr_leakage.md),
[`scr_result`](https://evandeilton.github.io/scorecraft/reference/scr_result.md),
[`scr_score_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_score_gains.md),
[`scr_score_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_score_metrics.md),
[`scr_selected()`](https://evandeilton.github.io/scorecraft/reference/scr_selected.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
g <- scr_gains(res)
g[feature == scr_selected(res)[1], .(bin, count, pos_rate, woe, iv)]
#>                      bin count   pos_rate         woe           iv
#>                   <char> <num>      <num>       <num>        <num>
#> 1:      (-Inf;33.360000]   145 0.02068966 -2.06253559 0.1064747433
#> 2: (33.360000;38.150000]   162 0.07407407 -0.73104946 0.0236851117
#> 3: (38.150000;44.240000]   366 0.07923497 -0.65810792 0.0445384274
#> 4: (44.240000;48.060000]   301 0.08970100 -0.52261206 0.0242753010
#> 5: (48.060000;63.940000]  1343 0.14743112  0.03978629 0.0007701023
#> 6: (63.940000;72.610000]   338 0.25147929  0.70394095 0.0757861557
#> 7:      (72.610000;+Inf]   145 0.31034483  0.99617148 0.0708603096
```
