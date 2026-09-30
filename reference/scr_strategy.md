# Stage 6: strategy table per band, with marginal expected profit

Score bands (by default the deciles frozen on train) with volume, event
rate, the event and non-event distributions, decision and the expected
result per account. The good case is the non-event under
`objective = "risk"` (credit, fraud) and the event under `"propensity"`;
the bad case is the other one. With \\p\\ the rate of the bad case in
the band (the event rate under risk, one minus it under propensity):
\$\$EP = (1 - p)\\\mathrm{revenue\\good} - p\\\mathrm{loss\\bad},\$\$
which makes visible the band that is profitable **at the margin** even
with a high rate of the bad case. `EP = 0` at the break-even rate of the
bad case, `revenue_good / (revenue_good + loss_bad)`. The object stores
it as an event rate (`breakeven`): the same value under risk, and
`loss_bad / (revenue_good + loss_bad)` under propensity, where a band is
targeted at or above it.

## Usage

``` r
scr_strategy(
  x,
  breaks = NULL,
  decisions = NULL,
  revenue_good = 1,
  loss_bad = 1,
  sample = "holdout",
  rule = c("breakeven", "crossing")
)
```

## Arguments

- x:

  An object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

- breaks:

  Band cut points. `NULL` uses the deciles frozen on train.

- decisions:

  Vector of decisions, one per band (from the first row of the table to
  the last). `NULL` derives them from `rule`; when given, it overrides
  `rule`.

- revenue_good:

  Expected revenue per account of the good case (the non-event under
  risk, the event under propensity; default `1`).

- loss_bad:

  Expected loss per account of the bad case (default `1`; with both
  defaults the break-even is 50%). `revenue_good` and `loss_bad` cannot
  both be 0.

- sample:

  `"holdout"` (default) or `"train"`.

- rule:

  `"breakeven"` (default) or `"crossing"`; see the section Decision
  rules.

## Value

An `scr_strategy` object with

- `table`:

  One row per band: `id`, `band`, `min_score`, `max_score`, `n`, `pct`,
  `events`, `event_rate`, `pct_event`, `pct_nonevent`, `odds_event`,
  `log_odds`, `decision`, `ep_per_account`, `band_profit`, `cum_pct`,
  `cum_event_rate` and `cum_profit`.

- `breakeven`:

  The break-even event rate.

- `crossing`:

  A list: `cut`, the score boundary of the crossing rule; `ks`, the
  distance \\D_k\\ at it; `after_band`, the last band on the good side;
  `single_crossing`, whether `log_odds` changes sign exactly once along
  the table. All `NA` when undefined; only `cut` is `NA` when `breaks`
  is a single number (a count of intervals, whose edges are not kept).

- `objective`, `rule`:

  The objective of the scorecard and the rule used.

- `revenue_good`, `loss_bad`, `sample`, `direction`, `target`:

  The parameters and the scorecard's direction and target.

## Details

The table runs from the band richest in the good case to the poorest:
the safest band first under risk, the most likely first under
propensity.

## Event and non-event distributions

With \\e_k\\ events and \\m_k\\ non-events in band \\k\\, and \\E\\ and
\\M\\ their totals over the sample: \$\$\mathrm{pct\\event}\_k = e_k /
E, \qquad \mathrm{pct\\nonevent}\_k = m_k / M,\$\$
\$\$\mathrm{odds\\event}\_k = \mathrm{pct\\event}\_k /
\mathrm{pct\\nonevent}\_k, \qquad \mathrm{log\\odds}\_k = \ln
\mathrm{odds\\event}\_k.\$\$ `log_odds` is the WOE of the band,
event-oriented like the WOE of the variables: `log_odds > 0` if and only
if the band event rate is above the overall event rate, that is, the
lift of the band is above 1 (exact when every band has both classes;
under the smoothing below, a band at the overall rate can fall on either
side). When a band has no events or no non-events, 0.5 is added to the
counts of every band for `odds_event` and `log_odds`; the shares stay
exact. With a single class in the sample, the shares of the missing
class and every ratio are `NA`. This `log_odds` is the `woe` column of
[`scr_score_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_score_gains.md),
not its `log_odds`, which is the log of the band odds in the orientation
of the scale.

## Decision rules

`rule = "breakeven"` (default) gives the good label (`"approve"` under
risk, `"target"` under propensity) to a band whose rate of the bad case
is at or below break-even, `"review"` to one up to 25% above it, and the
bad label (`"decline"` or `"skip"`) to the rest.

`rule = "crossing"` cuts where the event and non-event distributions are
furthest apart. With \$\$D_k = \left\|\sum\_{j \le k}
\mathrm{pct\\event}\_j - \sum\_{j \le k}
\mathrm{pct\\nonevent}\_j\right\|\$\$ over the first \\k\\ rows of the
table, the first maximum of \\D_k\\ over the boundaries between rows is
the KS of the table; the rows up to it get the good label and the rest
the bad label, with no review band. When `log_odds` is monotone along
the table this is where it changes sign, the band event rate crossing
the overall rate; when it is not, the cut still gives a contiguous set
of bands. The boundary is always computed and stored in `crossing`. It
is undefined with fewer than two bands or a single class in the sample,
and `rule = "crossing"` is then an error. Scores outside `breaks` form a
last row with a missing `band`, which gets no decision (`NA`) under the
crossing rule; the shares, and hence `ks`, stay relative to the whole
sample, that row included.

`decisions`, when given, overrides either rule.

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
#> <scr_strategy> target "default" | objective risk | rule breakeven | sample holdout
#>   break-even event rate: 19.35% (revenue 1080, loss 4500)
#>   band                       vol%    event log_odds decision     EP/acct       profit
#>   (590, Inf]                11.2%    3.18%   -1.640 approve       902.29       141660
#>   (577,590]                  8.9%    3.23%   -1.627 approve       900.00       111600
#>   (567,577]                  9.1%    3.91%   -1.428 approve       862.03       110340
#>   (558,567]                 10.6%    7.38%   -0.755 approve       668.05        99540
#>   (550,558]                 10.6%   12.16%   -0.203 approve       401.35        59400
#>   (542,550]                 10.8%   11.26%   -0.290 approve       451.79        68220
#>   (533,542]                 10.6%   17.45%    0.220 approve       106.31        15840
#>   (524,533]                  9.9%   26.62%    0.760 decline      -405.32       -56340
#>   (510,524]                  9.1%   27.34%    0.797 decline      -445.78       -57060
#>   [-Inf,510]                 9.1%   35.43%    1.174 decline      -897.17      -113940
#>   event and non-event distributions cross at score 542.1 (KS 0.370)
# approve down to where the event and non-event distributions cross
st <- scr_strategy(sc, rule = "crossing")
st$crossing
#> $cut
#> [1] 542.0954
#> 
#> $ks
#> [1] 0.3702647
#> 
#> $after_band
#> [1] "(542,550]"
#> 
#> $single_crossing
#> [1] TRUE
#> 
st$table[, .(band, event_rate, log_odds, decision)]
#>           band event_rate   log_odds decision
#>         <char>      <num>      <num>   <char>
#>  1: (590, Inf] 0.03184713 -1.6400749  approve
#>  2:  (577,590] 0.03225806 -1.6268297  approve
#>  3:  (567,577] 0.03906250 -1.4283787  approve
#>  4:  (558,567] 0.07382550 -0.7549907  approve
#>  5:  (550,558] 0.12162162 -0.2027950  approve
#>  6:  (542,550] 0.11258278 -0.2902587  approve
#>  7:  (533,542] 0.17449664  0.2202799  decline
#>  8:  (524,533] 0.26618705  0.7603128  decline
#>  9:  (510,524] 0.27343750  0.7971163  decline
#> 10: [-Inf,510] 0.35433071  1.1743110  decline
```
