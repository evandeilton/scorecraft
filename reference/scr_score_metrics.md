# Score metrics per sample, with CI

`n`, events, AUC, KS and Gini of the scorecard score on train and
hold-out, with a bootstrap confidence interval and the direction used:
the AUC is always reported above 0.5 when the score ranks correctly in
its own direction.

## Usage

``` r
scr_score_metrics(x)
```

## Arguments

- x:

  An object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

## Value

A `data.table` with one row per sample.

## See also

Other accessors:
[`scr_funnel()`](https://evandeilton.github.io/scorecraft/reference/scr_funnel.md),
[`scr_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_gains.md),
[`scr_leakage()`](https://evandeilton.github.io/scorecraft/reference/scr_leakage.md),
[`scr_result`](https://evandeilton.github.io/scorecraft/reference/scr_result.md),
[`scr_score_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_score_gains.md),
[`scr_selected()`](https://evandeilton.github.io/scorecraft/reference/scr_selected.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
sc <- scr_scorecard(res)
scr_score_metrics(sc)
#> Index: <sample>
#>     sample       direction     n events       auc    auc_lo    auc_hi        ks
#>     <char>          <char> <int>  <int>     <num>     <num>     <num>     <num>
#> 1:   train higher_is_safer  2800    399 0.7856428 0.7662170 0.8069608 0.4411466
#> 2: holdout higher_is_safer  1400    203 0.7394060 0.7066284 0.7770357 0.3889033
#>        ks_lo     ks_hi      gini   gini_lo   gini_hi n_boot level
#>        <num>     <num>     <num>     <num>     <num>  <int> <num>
#> 1: 0.4145334 0.4875854 0.5712856 0.5324341 0.6139216     20  0.95
#> 2: 0.3381932 0.4654704 0.4788120 0.4132569 0.5540713     20  0.95
```
