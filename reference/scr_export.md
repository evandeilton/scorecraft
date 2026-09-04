# Write the deliverables

For an `scr_result`: the selection workbook (`selection_<target>.xlsx`:
funnel, gains, screening, hold-out, models, votes, consensus, ledger,
redundancy), the WOE SQL and the executive summary in Markdown. For an
`scr_scorecard`: three workbooks (the detailing decision of SPEC section
7 resolved as separate files) plus the score SQL:

## Usage

``` r
scr_export(x, dir, stamp = TRUE, ...)

# S3 method for class 'scr_result'
scr_export(x, dir, stamp = TRUE, ...)

# S3 method for class 'scr_scorecard'
scr_export(x, dir, stamp = TRUE, ...)
```

## Arguments

- x:

  An object from
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
  or
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

- dir:

  Output directory. Created if it does not exist.

- stamp:

  If `TRUE` (default), writes to a timestamped subdirectory, preserving
  earlier runs.

- ...:

  For `scr_scorecard`: precomputed `cutoff`, `strategy`, `reject` and
  `monitor` objects, and `revenue_good`/`loss_bad` for the default
  strategy table.

## Value

The object `x`, with `$files` filled, invisibly.

## Details

- `scorecard_<target>.xlsx`:

  `Score_Summary` (with `odds_orientation`), `Final_Scorecard`,
  `Coefficients`, `Sign_Check`, `Alignment`, `Model_Card`, `Challenger`
  and `Swap_Set` (when a challenger exists).

- `validation_<target>.xlsx`:

  `Score_Gains_Frozen`, `Variable_Gains_IV`, `Discrimination_CI`,
  `Stability_PSI_Timeline`, `Stability_CSI_Timeline`, `Calibration`,
  `Performance_By_Vintage`, `Rank_Order_Diagnostics`.

- `strategy_<target>.xlsx`:

  `Population_Scope`, `Cutoff_Sweep`, `Strategy_Bands`,
  `Reject_Sensitivity`, `Monitoring_Plan`.

The timeline and vintage sheets need the date column of the split; when
it is absent they carry an availability row instead of a fabricated
number.

## See also

Other production:
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
[`scr_reasons()`](https://evandeilton.github.io/scorecraft/reference/scr_reasons.md),
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
out <- file.path(tempdir(), "scorecraft-example")
res <- scr_export(res, out, stamp = FALSE)
#>   /tmp/Rtmp3pm6x3/scorecraft-example/selection_default.xlsx
#>   /tmp/Rtmp3pm6x3/scorecraft-example/sql_woe_default.sql
#>   /tmp/Rtmp3pm6x3/scorecraft-example/summary_default.md
basename(unlist(res$files))
#> [1] "selection_default.xlsx" "sql_woe_default.sql"    "summary_default.md"    
sc <- scr_export(scr_scorecard(res), out, stamp = FALSE)
#>   /tmp/Rtmp3pm6x3/scorecraft-example/scorecard_default.xlsx
#>   /tmp/Rtmp3pm6x3/scorecraft-example/validation_default.xlsx
#>   /tmp/Rtmp3pm6x3/scorecraft-example/strategy_default.xlsx
#>   /tmp/Rtmp3pm6x3/scorecraft-example/sql_score_default.sql
#>   /tmp/Rtmp3pm6x3/scorecraft-example/sql_woe_default.sql
basename(unlist(sc$files))
#> [1] "scorecard_default.xlsx"  "validation_default.xlsx"
#> [3] "strategy_default.xlsx"   "sql_score_default.sql"  
#> [5] "sql_woe_default.sql"    
```
