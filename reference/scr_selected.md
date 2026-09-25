# Variables approved for the scorecard

The final shortlist, in consensus order (the first is the strongest). It
is exactly the list
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
covers and
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
fits.

## Usage

``` r
scr_selected(x, which = c("final", "consensus", "manual"))
```

## Arguments

- x:

  An object from
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md).

- which:

  `"final"` (default), `"consensus"` or `"manual"` (`NULL` when no
  manual choice was made).

## Value

A character vector of column names.

## Details

After
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md)
the result carries two lists: the automatic consensus and the analyst's
final choice; `which` picks one, and the default is the final one so
that every downstream function follows the analyst's decision.

## See also

Other accessors:
[`scr_funnel()`](https://evandeilton.github.io/scorecraft/reference/scr_funnel.md),
[`scr_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_gains.md),
[`scr_leakage()`](https://evandeilton.github.io/scorecraft/reference/scr_leakage.md),
[`scr_result`](https://evandeilton.github.io/scorecraft/reference/scr_result.md),
[`scr_score_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_score_gains.md),
[`scr_score_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_score_metrics.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
scr_selected(res)
#>  [1] "vl_score_01" "vl_score_02" "vl_score_04" "ds_band"     "vl_late"    
#>  [6] "ds_region"   "vl_score_06" "vl_score_07" "vl_score_05" "ds_channel" 
#> [11] "vl_score_10" "vl_hist_04" 
```
