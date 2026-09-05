# Stage 6: cut-off sweep with frozen cuts

For each candidate cut, what happens in each sample: the fraction of the
population on the safe side (approval), the event rate on both sides,
the events avoided (share of events falling on the risky side), the
non-events lost and the KS at the cut. The candidate cuts are quantiles
of the score **on train**, applied frozen to the hold-out: both samples
answer on the same numbers, and the comparison between them measures the
stability of the decision, not a sample difference.

## Usage

``` r
scr_cutoff(x, n_cuts = NULL, cuts = NULL)
```

## Arguments

- x:

  An object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

- n_cuts:

  Number of candidate cuts. `NULL` uses `config$cutoff_n`.

- cuts:

  Explicit vector of cuts; overrides `n_cuts`.

## Value

An `scr_cutoff` object with `table` (one row per sample and cut) and
`direction`.

## Details

The "safe side" is the high-score side under `higher_is_safer` (credit)
and the low-score side under `higher_is_riskier` (fraud, propensity).

## See also

Other stages:
[`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md),
[`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md),
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md),
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
sc <- scr_scorecard(res)
ct <- scr_cutoff(sc, n_cuts = 10)
ct
#> <scr_cutoff> target "default" | 10 cuts frozen on train | safe side: high score
#>        cut     %safe    ev.safe   ev.risky   ev.avoid       KS
#>      508.2     91.7%     12.54%     36.21%      20.7%    0.145
#>      521.5     83.8%     10.91%     33.04%      36.9%    0.242
#>      530.7     74.9%      9.06%     30.68%      53.2%    0.328
#>      539.0     64.6%      7.29%     27.68%      67.5%    0.376
#>      546.9     54.6%      6.41%     24.21%      75.9%    0.356
#>      553.3     46.2%      5.41%     22.31%      82.8%    0.339
#>      561.1     36.1%      3.56%     20.67%      91.1%    0.318
#>      568.8     26.6%      3.49%     18.48%      93.6%    0.236
#>      578.2     19.3%      2.96%     17.26%      96.1%    0.179
#>      592.8     10.0%      2.86%     15.79%      98.0%    0.094
st <- scr_strategy(sc, revenue_good = 1080, loss_bad = 4500)
st
#> <scr_strategy> target "default" | sample holdout | break-even event rate: 19.35% (revenue 1080, loss 4500)
#>   band                       vol%    event decision     EP/acct       profit
#>   (590, Inf]                11.2%    3.18% approve       902.29       141660
#>   (577,590]                  8.9%    3.23% approve       900.00       111600
#>   (567,577]                  9.1%    3.91% approve       862.03       110340
#>   (558,567]                 10.6%    7.38% approve       668.05        99540
#>   (550,558]                 10.6%   12.16% approve       401.35        59400
#>   (542,550]                 10.8%   11.26% approve       451.79        68220
#>   (533,542]                 10.6%   17.45% approve       106.31        15840
#>   (524,533]                  9.9%   26.62% decline      -405.32       -56340
#>   (510,524]                  9.1%   27.34% decline      -445.78       -57060
#>   [-Inf,510]                 9.1%   35.43% decline      -897.17      -113940
rj <- scr_reject(sc)
rj
#> <scr_reject> target "default" | multipliers 2x, 4x, 8x
#>   The scorecard describes the population WITH an observed outcome. No extrapolation to rejects was made; the sensitivity band shows the effect of declared assumptions, not an inferred number.
#>   observed event rate: 14.50%
#>   implied rate if the population without outcome is 2x worse: 14.50%
#>   implied rate if the population without outcome is 4x worse: 14.50%
#>   implied rate if the population without outcome is 8x worse: 14.50%
#>   bands with weak coverage: (590, Inf] (few_events), (577,590] (few_events), (567,577] (few_events), (558,567] (few_events), (550,558] (few_events), (542,550] (few_events), (533,542] (few_events)
```
