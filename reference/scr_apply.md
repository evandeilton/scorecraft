# Apply the WOE transformation or the scorecard to new data

Materialises in R exactly what the production SQL does: the frozen Stage
1 pre-processing (training median, special-population flags,
`"MISSING"`) followed by the frozen Stage 2 binning and, for a
scorecard, by the points. Nothing is refitted. The two paths, R and SQL,
produce the same numbers, and a test guarantees it.

## Usage

``` r
scr_apply(x, newdata, ...)

# S3 method for class 'scr_result'
scr_apply(
  x,
  newdata,
  features = scr_selected(x),
  what = c("woe", "bin", "both"),
  ...
)

# S3 method for class 'scr_scorecard'
scr_apply(x, newdata, what = c("score", "points", "woe", "all"), ...)
```

## Arguments

- x:

  An object from
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
  (returns WOE/bin of the approved variables) or from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
  (returns score and points).

- newdata:

  New table with the source columns of the requested variables. The
  target column is not needed.

- ...:

  Passed on to the methods.

- features:

  For `scr_result`: which variables to transform. Defaults to the
  approved ones.

- what:

  For `scr_result`: `"woe"`, `"bin"` or `"both"`. For `scr_scorecard`:
  `"score"`, `"points"`, `"woe"` or `"all"`.

## Value

A `data.table` with one row per row of `newdata`.

## Method arguments

For `scr_result`: `features` (default: the approved ones) and `what`
(`"woe"`, `"bin"` or `"both"`). For `scr_scorecard`: `what` (`"score"`,
`"points"`, `"woe"` or `"all"`). The score output carries `link`
(logit), `prob` (model probability), `score` (exact, `a + b * logit`)
and `score_points` (the sum of the whole points per bin plus the base).

## See also

Other production:
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md),
[`scr_reasons()`](https://evandeilton.github.io/scorecraft/reference/scr_reasons.md),
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
new <- head(scr_demo, 50)
str(scr_apply(res, new)[, 1:3])
#> Classes ‘data.table’ and 'data.frame':   50 obs. of  3 variables:
#>  $ vl_score_01_woe: num  0.7039 -0.6581 0.0398 0.0398 0.0398 ...
#>  $ vl_score_02_woe: num  0.572 -0.77 -0.824 0.382 0.572 ...
#>  $ vl_score_04_woe: num  -0.8932 0.304 -0.0558 -0.0558 -0.0558 ...
#>  - attr(*, ".internal.selfref")=<pointer: 0x55621d5f1730> 
sc <- scr_scorecard(res)
head(scr_apply(sc, new))
#>         link       prob    score score_points
#>        <num>      <num>    <num>        <num>
#> 1: -2.102534 0.10885077 546.5330          546
#> 2: -2.702712 0.06281350 562.3290          562
#> 3: -2.634040 0.06697956 560.5217          559
#> 4: -0.602874 0.35368644 507.0636          507
#> 5: -1.731277 0.15042432 536.7619          536
#> 6: -4.297105 0.01342521 604.2917          604
head(scr_apply(sc, new, what = "points"))
#>       score score_points vl_score_01_points vl_score_02_points
#>       <num>        <num>              <num>              <num>
#> 1: 546.5330          546                -21                -16
#> 2: 562.3290          562                 20                 21
#> 3: 560.5217          559                 -1                 22
#> 4: 507.0636          507                 -1                -10
#> 5: 536.7619          536                 -1                -16
#> 6: 604.2917          604                 16                  6
#>    vl_score_04_points ds_faixa_points vl_tardio_points ds_regiao_points
#>                 <num>           <num>            <num>            <num>
#> 1:                 24               2                5                4
#> 2:                 -8               0               -5                0
#> 3:                  1               2              -13               10
#> 4:                  1             -11               -5              -13
#> 5:                  1               0                5                0
#> 6:                  9              13                5                4
#>    vl_score_06_points vl_score_07_points vl_score_05_points ds_canal_points
#>                 <num>              <num>              <num>           <num>
#> 1:                 -3                 14                 -9               9
#> 2:                  4                  1                 -3              -5
#> 3:                  4                 -7                 -3              -5
#> 4:                 -3                  6                 -3               9
#> 5:                  9                  6                 -9               4
#> 6:                -15                 14                  6               9
#>    vl_score_10_points vl_hist_04_points
#>                 <num>             <num>
#> 1:                  2                -3
#> 2:                  2                -3
#> 3:                  2                 9
#> 4:                  2                -3
#> 5:                  2                -3
#> 6:                  2                -3
```
