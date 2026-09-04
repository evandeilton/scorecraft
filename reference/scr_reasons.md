# Reason codes: the variables that took the most points from each row

For each row of `newdata`, the `k` variables whose contribution in
points fell furthest below the reference. The reference is the mean
points of the variable on the training population (`"mean"`, the
Regulation B safe harbour referenced to the average) or the maximum
points of the variable (`"max"`). Only applies to the additive
scorecard; a tree challenger has no reason codes.

## Usage

``` r
scr_reasons(x, newdata, k = 4L, reference = c("mean", "max"))
```

## Arguments

- x:

  An object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

- newdata:

  New table.

- k:

  Number of reasons per row.

- reference:

  `"mean"` (default) or `"max"`.

## Value

A `data.table` with `reason_1` ... `reason_k` (variable names) and
`shortfall_1` ... `shortfall_k` (points below the reference).

## References

12 CFR 1002.9 (Regulation B), official commentary to paragraph 9(b)(2).

## See also

Other production:
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
[`scr_export.scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md),
[`scr_sql.scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
sc <- scr_scorecard(res)
scr_reasons(sc, head(scr_demo, 5), k = 3)
#>       reason_1 shortfall_1    reason_2 shortfall_2    reason_3 shortfall_3
#>         <char>       <num>      <char>       <num>      <char>       <num>
#> 1: vl_score_01   25.197857 vl_score_02   17.828571 vl_score_05    9.054286
#> 2: vl_score_04    9.052857   vl_tardio    5.716071    ds_canal    5.387857
#> 3:   vl_tardio   13.716071 vl_score_07    7.605357    ds_canal    5.387857
#> 4:   ds_regiao   13.807143    ds_faixa   11.932500 vl_score_02   11.828571
#> 5: vl_score_02   17.828571 vl_score_05    9.054286 vl_score_01    5.197857
```
