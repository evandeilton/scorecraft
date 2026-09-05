# Coarse classing lab: manual binning and manual variable choice

Opens a lab on an
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
result. Inside it the analyst inspects the optimal bins of any binned
variable
([`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md)),
proposes new breaks or groupings
([`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md)),
reads the comparison against the optimal bins, accepts or discards each
proposal with a mandatory reason
([`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
[`scr_classing_discard()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md)),
chooses the final variable list
([`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md))
and commits everything to a new `scr_result`
([`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md))
that the rest of the pipeline consumes unchanged:
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md),
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md).

## Usage

``` r
scr_coarse_classing(
  x,
  features = NULL,
  laplace = 0,
  max_iv_loss = NULL,
  author = Sys.info()[["user"]]
)
```

## Arguments

- x:

  An object from
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md).

- features:

  Variables the lab covers. Default: every variable that reached binning
  (`names(x$fit$results)`), so a variable failed by screening can be
  rebinned and forced in with a reason.

- laplace:

  Smoothing added to the bin counts when recomputing WOE. `0` (default)
  is exactly the engine's formula.

- max_iv_loss:

  Advisory threshold: a manual bin whose hold-out IV falls more than
  this fraction below the optimal one raises `IV_LOSS_VS_OPTIMAL`.
  `NULL` uses `config$lab_max_iv_loss`.

- author:

  Free text recorded in the ledger.

## Value

An `scr_classing` object (the lab), with a print method that summarises
the session: variables touched, before/after IV, verdicts, reasons,
pending proposals and the final choice.

## Contract of a manual bin

A manual bin is recomputed **on the training rows only** (hold-out rows
can never define a bin), with the engine's own WOE formula
(`ln(%event / %non-event)`, event-oriented, so glm coefficients stay
positive), then revalidated on the hold-out with the bins frozen (IV,
PSI with both thresholds, unbinned share) and screened with the eight
engine rules, so the lab and the pipeline can never disagree. Numeric
intervals are right-closed, `(a, b]`, exactly as the engine and its SQL.
Re-declaring the optimal cut points of a numeric reproduces the engine's
WOE exactly; for a categorical the engine applies a small internal
smoothing of its own, so the raw log-ratio of the lab differs from it in
the third decimal.

## What is never allowed silently

An empty bin, a degenerate bin (no events or no non-events, unless
`laplace > 0`), a bin below `lab_min_bin_pct_hard`, a manual IV crossing
`iv_max` (the lab must not manufacture leakage), a category left
unassigned, a missing reason. Those block the proposal (`BLOCKED`);
accepting one needs `override = TRUE`, and the override is itself a
ledger row.

## See also

Other classing:
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md),
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
[`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md),
[`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md),
[`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md),
[`scr_decisions()`](https://evandeilton.github.io/scorecraft/reference/scr_decisions.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
lab <- scr_coarse_classing(res)
lab
#> <scr_classing> target "default" | opened 2026-09-05 03:33 by runner | 37 variables | 0 proposals: 0 accepted, 0 discarded
#>   final choice: 12 variables | consensus 12 | force: (none) | drop: (none)
scr_classing_view(lab, "ds_regiao")
#> <scr_classing> ds_regiao (categorical) | current: optimal (jedi) | 5 bins | train IV 0.0846, hold-out IV 0.0971 (ratio 1.14)
#>   monotone: yes | min bin 7.9% | PSI 0.0064 (stable) | KS 0.114 | degenerate bins: 0 | verdict: ACCEPTABLE
#>    id  bin                                  n      %  events   rate      WOE      IV |  n.hold      %    rate WOE.hold
#>     1  MG                                 539  19.2%      57  10.6%   -0.341   0.020 |     301  21.5%   13.0%   -0.130
#>     2  SP                               1,139  40.7%     144  12.6%   -0.139   0.008 |     551  39.4%   13.8%   -0.058
#>     3  RJ                                 582  20.8%      82  14.1%   -0.014   0.000 |     269  19.2%   10.0%   -0.419
#>     4  BA                                 318  11.4%      66  20.8%    0.453   0.027 |     178  12.7%   23.6%    0.599
#>     5  RS                                 222   7.9%      50  22.5%    0.557   0.030 |     101   7.2%   18.8%    0.312
#>   event rate by bin (train | hold-out)
#>     1  ########            10.6% | ##########          13.0%
#>     2  ##########          12.6% | ###########         13.8%
#>     3  ###########         14.1% | ########            10.0%
#>     4  ################    20.8% | ##################  23.6%
#>     5  #################   22.5% | ##############      18.8%
p <- scr_classing_propose(lab, "ds_regiao",
                          groups = list(south = c("BA", "RS"),
                                        north = c("SP", "RJ", "MG")))
p
#> <scr_classing_proposal> P001 ds_regiao | groups = list(south = c("BA", "RS"), north = c("SP", "RJ", "MG")) | 2026-09-05 03:33
#>                         optimal     manual      delta
#>   n_bins                      5          2         -3
#>   iv_train               0.0846     0.0739    -0.0107
#>   iv_holdout             0.0971     0.0786    -0.0186
#>   iv_ratio               1.1432     1.0568    -0.0864
#>   ks                     0.1141     0.1141     0.0000
#>   psi                    0.0064     0.0003    -0.0061
#>   min_bin_pct            0.0793     0.1929     0.1136
#>   largest_bin_pct        0.4068     0.8071     0.4004
#>   n_degenerate                0          0          0
#>   monotonic                   1          1          0
#>   manual bins (train | hold-out)
#>     1  BA | RS                            540  19.3%  21.5%   0.499 |     279  19.9%  21.9%   0.501
#>     2  SP | RJ | MG                     2,260  80.7%  12.5%  -0.149 |   1,121  80.1%  12.7%  -0.156
#>   Warnings
#>     - IV_LOSS_VS_OPTIMAL
#>   Verdict: REVIEW - advisory warnings only; accept with a reason or discard.
lab <- scr_classing_accept(lab, p, reason = "north/south is what pricing uses")
#>   ds_regiao: P001 accepted (REVIEW) - 2 bins, hold-out IV 0.0786
lab <- scr_classing_choose(lab, drop = "vl_score_10",
                           reason = "not available at decision time")
lab
#> <scr_classing> target "default" | opened 2026-09-05 03:33 by runner | 37 variables | 1 proposals: 1 accepted, 0 discarded
#>   variable                   action      bins          IV train       IV hold-out verdict     reason
#>   ds_regiao                  accepted  5->2     0.0846->0.0739     0.0971->0.0786   REVIEW      north/south is what pricing uses
#>   final choice: 11 variables | consensus 12 | force: (none) | drop: vl_score_10
res2 <- scr_classing_apply(lab)
scr_selected(res2)
#>  [1] "vl_score_01" "vl_score_02" "vl_score_04" "ds_faixa"    "vl_tardio"  
#>  [6] "ds_regiao"   "vl_score_06" "vl_score_07" "vl_score_05" "ds_canal"   
#> [11] "vl_hist_04" 
scr_selected(res2, which = "consensus")
#>  [1] "vl_score_01" "vl_score_02" "vl_score_04" "ds_faixa"    "vl_tardio"  
#>  [6] "ds_regiao"   "vl_score_06" "vl_score_07" "vl_score_05" "ds_canal"   
#> [11] "vl_score_10" "vl_hist_04" 
sc <- scr_scorecard(res2)
sc$model_card$binning_algorithm
#> [1] "jedi, manual"
```
