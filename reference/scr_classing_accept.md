# Accept or discard a proposal

`reason` is mandatory. Accepting replaces the variable's current bins;
the previous accepted proposal is marked `superseded`. A `BLOCKED`
proposal needs `override = TRUE`, and the override is itself a ledger
row.

## Usage

``` r
scr_classing_accept(lab, proposal, reason, override = FALSE)

scr_classing_discard(lab, proposal, reason)
```

## Arguments

- lab:

  An object from
  [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md).

- proposal:

  An object from
  [`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md).

- reason:

  Free text, at least 5 characters.

- override:

  Accept a `BLOCKED` proposal.

## Value

The updated lab, invisibly.

## See also

[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
for a complete session, from lab to scorecard.

Other classing:
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md),
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
[`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md),
[`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md),
[`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md),
[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md),
[`scr_decisions()`](https://evandeilton.github.io/scorecraft/reference/scr_decisions.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 40, n_boot = 10)
d <- scr_demo[, c("default", "ref_date", "ds_region", "ds_band", "vl_score_01",
                  "vl_score_02", "vl_score_05", "vl_score_10", "vl_hist_01")]
res <- scr_select(d, "default", config = cfg, date_col = "ref_date")
lab <- scr_coarse_classing(res)
p <- scr_classing_propose(lab, "ds_region",
                          groups = list(edge = c("NORTH", "SOUTH"),
                                        core = c("EAST", "WEST", "CENTRE")))
lab <- scr_classing_accept(lab, p, reason = "edge/core is what pricing uses")
#>   ds_region: P001 accepted (REVIEW) - 2 bins, hold-out IV 0.0786
scr_classing_view(lab, "ds_region")
#> <scr_classing> ds_region (categorical) | current: manual | 2 bins | train IV 0.0739, hold-out IV 0.0786 (ratio 1.06)
#>   monotone: yes | min bin 19.3% | PSI 0.0003 (stable) | KS 0.114 | degenerate bins: 0 | verdict: REVIEW [IV_LOSS_VS_OPTIMAL]
#>    id  bin                                  n      %  events   rate      WOE      IV |  n.hold      %    rate WOE.hold
#>     1  NORTH | SOUTH                      540  19.3%     116  21.5%    0.499   0.057 |     279  19.9%   21.9%    0.501
#>     2  EAST | WEST | CENTRE             2,260  80.7%     283  12.5%   -0.149   0.017 |   1,121  80.1%   12.7%   -0.156
#>   event rate by bin (train | hold-out)
#>     1  ##################  21.5% | ##################  21.9%
#>     2  ##########          12.5% | ##########          12.7%
# a second proposal on the same variable, rejected with its reason
p2 <- scr_classing_propose(lab, "ds_region",
                           groups = list(c("NORTH", "SOUTH", "EAST"), c("WEST", "CENTRE")))
lab <- scr_classing_discard(lab, p2, reason = "no business rationale for this grouping")
scr_decisions(lab)
#>      seq                  at author  variable  action proposal_id
#>    <int>              <POSc> <char>    <char>  <char>      <char>
#> 1:     1 2026-09-25 21:56:00 runner ds_region  accept        P001
#> 2:     2 2026-09-25 21:56:00 runner ds_region discard        P002
#>                                                                      instruction
#>                                                                           <char>
#> 1: groups = list(edge = c("NORTH", "SOUTH"), core = c("EAST", "WEST", "CENTRE"))
#> 2:               groups = list(c("NORTH", "SOUTH", "EAST"), c("WEST", "CENTRE"))
#>    n_bins_before n_bins_after iv_train_before iv_train_after iv_holdout_before
#>            <int>        <int>           <num>          <num>             <num>
#> 1:             5            2      0.08464808     0.07392963        0.09714339
#> 2:            NA            2              NA     0.01564687                NA
#>    iv_holdout_after    psi_after verdict                        warnings
#>               <num>        <num>  <char>                          <char>
#> 1:       0.07858917 0.0002621977  REVIEW              IV_LOSS_VS_OPTIMAL
#> 2:       0.03883906 0.0001912750  REVIEW IV_BELOW_MIN;IV_LOSS_VS_OPTIMAL
#>                                     reason
#>                                     <char>
#> 1:          edge/core is what pricing uses
#> 2: no business rationale for this grouping
```
