# Stage 6: strategy table per band, with marginal expected profit

Score bands (by default the deciles frozen on train) with volume, event
rate, decision and the expected result per account: \$\$EP = (1 -
p)\\\mathrm{revenue\\good} - p\\\mathrm{loss\\bad},\$\$ which makes
visible the band that is profitable **at the margin** even with a high
event rate. The break-even event rate, where `EP = 0`, is
`revenue_good / (revenue_good + loss_bad)`.

## Usage

``` r
scr_strategy(
  x,
  breaks = NULL,
  decisions = NULL,
  revenue_good = 1,
  loss_bad = 1,
  sample = "holdout"
)
```

## Arguments

- x:

  An object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

- breaks:

  Band cut points. `NULL` uses the deciles frozen on train.

- decisions:

  Vector of decisions, one per band (from the safest to the riskiest).
  `NULL` derives them from break-even.

- revenue_good:

  Expected revenue per account without the event (default `1`).

- loss_bad:

  Expected loss per account with the event (default `1`; with both
  defaults the break-even event rate is 50%).

- sample:

  `"holdout"` (default) or `"train"`.

## Value

An `scr_strategy` object with `table`, `breakeven` and the parameters.

## Details

The automatic decision approves a band whose rate is below break-even,
sends to review a band up to 25% above it and declines the rest; pass
`decisions` to fix the policy.

## See also

Other stages:
[`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md),
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md),
[`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md),
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md),
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
sc <- scr_scorecard(res)
scr_strategy(sc, revenue_good = 1080, loss_bad = 4500)
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
```
