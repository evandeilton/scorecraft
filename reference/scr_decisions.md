# Decision ledger of a lab, a result or a scorecard

Returns the append-only ledger of manual decisions: every proposal
accepted, discarded or superseded, every forced or dropped variable and
every override, each with its reason.

## Usage

``` r
scr_decisions(x)
```

## Arguments

- x:

  An `scr_classing` lab, an `scr_result` from
  [`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md)
  or an `scr_scorecard` fitted on one.

## Value

A `data.table`, one row per decision (append-only), or an empty one when
no manual decision exists.

## See also

[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
for a complete session, from lab to scorecard.

Other classing:
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md),
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
[`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md),
[`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md),
[`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md),
[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)

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
scr_decisions(lab)
#>      seq                  at author  variable action proposal_id
#>    <int>              <POSc> <char>    <char> <char>      <char>
#> 1:     1 2026-09-25 20:44:59 runner ds_region accept        P001
#>                                                                      instruction
#>                                                                           <char>
#> 1: groups = list(edge = c("NORTH", "SOUTH"), core = c("EAST", "WEST", "CENTRE"))
#>    n_bins_before n_bins_after iv_train_before iv_train_after iv_holdout_before
#>            <int>        <int>           <num>          <num>             <num>
#> 1:             5            2      0.08464808     0.07392963        0.09714339
#>    iv_holdout_after    psi_after verdict           warnings
#>               <num>        <num>  <char>             <char>
#> 1:       0.07858917 0.0002621977  REVIEW IV_LOSS_VS_OPTIMAL
#>                            reason
#>                            <char>
#> 1: edge/core is what pricing uses
scr_decisions(scr_classing_apply(lab))
#>      seq                  at author  variable action proposal_id
#>    <int>              <POSc> <char>    <char> <char>      <char>
#> 1:     1 2026-09-25 20:44:59 runner ds_region accept        P001
#>                                                                      instruction
#>                                                                           <char>
#> 1: groups = list(edge = c("NORTH", "SOUTH"), core = c("EAST", "WEST", "CENTRE"))
#>    n_bins_before n_bins_after iv_train_before iv_train_after iv_holdout_before
#>            <int>        <int>           <num>          <num>             <num>
#> 1:             5            2      0.08464808     0.07392963        0.09714339
#>    iv_holdout_after    psi_after verdict           warnings
#>               <num>        <num>  <char>             <char>
#> 1:       0.07858917 0.0002621977  REVIEW IV_LOSS_VS_OPTIMAL
#>                            reason
#>                            <char>
#> 1: edge/core is what pricing uses
scr_decisions(res)   # no manual decision: an empty ledger
#> Empty data.table (0 rows and 17 cols): seq,at,author,variable,action,proposal_id...
```
