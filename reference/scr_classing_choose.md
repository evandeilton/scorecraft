# Choose the final variable list manually

The final list is `(consensus shortlist + force) - drop`, then
intersected with `keep` when given. `force` is allowed only for
variables that reached binning; a variable failed for `IV_SUSPICIOUS`
(the leakage ceiling) and a derived `__sp` flag under
`allow_derived_final = FALSE` are refused unless `override = TRUE`.
`reason` is one string for every variable named, or a character vector
named by variable.

## Usage

``` r
scr_classing_choose(
  lab,
  keep = NULL,
  drop = NULL,
  force = NULL,
  reason = NULL,
  override = FALSE
)
```

## Arguments

- lab:

  An object from
  [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md).

- keep:

  Variables to keep (restricts the final list).

- drop:

  Variables to remove from the final list.

- force:

  Variables to add to the final list.

- reason:

  Mandatory when `drop` or `force` is given.

- override:

  Allow a refused `force`.

## Value

The updated lab, invisibly.

## See also

[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
for a complete session, from lab to scorecard.

Other classing:
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md),
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
lab <- scr_classing_choose(lab, drop = "vl_score_10",
                           reason = "not available at decision time")
lab
#> <scr_classing> target "default" | opened 2026-09-25 20:58 by runner | 8 variables | 0 proposals: 0 accepted, 0 discarded
#>   final choice: 5 variables | consensus 6 | force: (none) | drop: vl_score_10
```
