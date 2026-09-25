# Commit the lab into a new selection result

Returns a new `scr_result` in which the accepted manual entries replace
the optimal ones inside `fit` (the automatic fit is frozen as
`fit_auto`), the screening and hold-out rows of those variables are
recomputed with the very same pipeline functions, the final shortlist is
the one implied by
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
and the funnel, gains, SQL and summary are rebuilt with a `provenance`
column.
[`scr_selected()`](https://evandeilton.github.io/scorecraft/reference/scr_selected.md)
on the result returns the final list (`which = "consensus"` still gives
the automatic one). The ledger travels with the result and into
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
and
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md).
The input result is not modified.

## Usage

``` r
scr_classing_apply(lab)
```

## Arguments

- lab:

  An object from
  [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md).

## Value

An `scr_result` with a `lab` component (`ledger`, `spec`, `shortlist`,
`source`).

## See also

[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
for a complete session, from lab to scorecard.

Other classing:
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
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
res2 <- scr_classing_apply(lab)
scr_selected(res2)
#> [1] "vl_score_01" "vl_score_02" "ds_band"     "ds_region"   "vl_score_05"
#> [6] "vl_score_10"
scr_decisions(res2)
#>      seq                  at author  variable action proposal_id
#>    <int>              <POSc> <char>    <char> <char>      <char>
#> 1:     1 2026-09-25 21:56:01 runner ds_region accept        P001
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
```
