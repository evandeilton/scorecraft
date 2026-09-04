# Score gains per frozen band

How the score behaves in each band: count, event rate, KS, lift,
cumulative capture and the score interval of the band, which is what
lets a cut-off be read straight from the table. The bands are the
deciles of the score on **train**, applied frozen to the other samples.

## Usage

``` r
scr_score_gains(x, sample = NULL)
```

## Arguments

- x:

  An object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

- sample:

  `NULL` (all), `"train"` or `"holdout"`.

## Value

A `data.table` with one row per sample and band, from the riskiest band
to the safest.

## See also

Other accessors:
[`scr_funnel()`](https://evandeilton.github.io/scorecraft/reference/scr_funnel.md),
[`scr_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_gains.md),
[`scr_leakage()`](https://evandeilton.github.io/scorecraft/reference/scr_leakage.md),
[`scr_result`](https://evandeilton.github.io/scorecraft/reference/scr_result.md),
[`scr_score_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_score_metrics.md),
[`scr_selected()`](https://evandeilton.github.io/scorecraft/reference/scr_selected.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
sc <- scr_scorecard(res)
scr_score_gains(sc, "holdout")[, .(band, n, event_rate, min_score, max_score, ks)]
#>           band     n event_rate min_score max_score        ks
#>         <char> <int>      <num>     <num>     <num>     <num>
#>  1: [-Inf,510]   127 0.35433071  452.9460  509.8567 0.1531703
#>  2:  (510,524]   128 0.27343750  510.0702  523.3842 0.2478898
#>  3:  (524,533]   139 0.26618705  523.6932  533.3423 0.3449428
#>  4:  (533,542]   149 0.17449664  533.4699  542.0327 0.3702647
#>  5:  (542,550]   151 0.11258278  542.1594  550.2070 0.3420621
#>  6:  (550,558]   148 0.12162162  550.3653  557.7466 0.3221272
#>  7:  (558,567]   149 0.07382550  557.7815  566.4153 0.2610261
#>  8:  (567,577]   128 0.03906250  566.5926  576.4365 0.1828998
#>  9:  (577,590]   124 0.03225806  576.6784  590.2077 0.1023536
#> 10: (590, Inf]   157 0.03184713  590.3197  652.3243 0.0000000
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
