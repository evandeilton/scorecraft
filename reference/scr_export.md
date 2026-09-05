# Write the deliverables

For an `scr_result`: the selection workbook (`selection_<target>.xlsx`:
funnel, gains, screening, hold-out, models, votes, consensus, ledger,
redundancy), the WOE SQL and the executive summary in Markdown. For an
`scr_scorecard`: three workbooks, as separate files, plus the score SQL:

## Usage

``` r
scr_export(x, dir, stamp = TRUE, ...)

# S3 method for class 'scr_capital'
scr_export(x, dir, stamp = TRUE, ...)

# S3 method for class 'scr_classing'
scr_export(x, dir, stamp = TRUE, ...)

# S3 method for class 'scr_ead'
scr_export(x, dir, stamp = TRUE, validation = NULL, tag = "ccf", ...)

# S3 method for class 'scr_result'
scr_export(x, dir, stamp = TRUE, ...)

# S3 method for class 'scr_scorecard'
scr_export(x, dir, stamp = TRUE, ...)

# S3 method for class 'scr_lgd'
scr_export(
  x,
  dir,
  stamp = TRUE,
  validation = NULL,
  elbe = NULL,
  tag = "model",
  ...
)

# S3 method for class 'scr_pd'
scr_export(x, dir, stamp = TRUE, validation = NULL, ...)
```

## Arguments

- x:

  An object from
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md),
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
  [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md),
  [`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md),
  [`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md),
  [`scr_ead()`](https://evandeilton.github.io/scorecraft/reference/scr_ead.md)
  or
  [`scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_capital.md).

- dir:

  Output directory. Created if it does not exist.

- stamp:

  If `TRUE` (default), writes to a timestamped subdirectory, preserving
  earlier runs.

- ...:

  For `scr_scorecard`: precomputed `cutoff`, `strategy`, `reject` and
  `monitor` objects, and `revenue_good`/`loss_bad` for the default
  strategy table.

- validation:

  For the IRB models (`scr_pd`, `scr_lgd`, `scr_ead`): the matching
  validation object
  ([`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md),
  [`scr_lgd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_validate.md),
  [`scr_ead_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_validate.md));
  `NULL` runs it on the hold-out where possible.

- tag:

  For `scr_lgd` and `scr_ead`: the file tag (`lgd_<tag>.xlsx`,
  `ead_<tag>.xlsx`). `scr_pd` names its files after the target
  (`pd_<target>.xlsx`) and `scr_capital` after the framework
  (`capital_<framework>.xlsx`).

- elbe:

  For `scr_lgd`: an
  [`scr_elbe()`](https://evandeilton.github.io/scorecraft/reference/scr_elbe.md)
  object; `NULL` computes it.

## Value

The object `x`, with `$files` filled, invisibly.

## Details

- `scorecard_<target>.xlsx`:

  `Score_Summary` (with `odds_orientation`), `Final_Scorecard`,
  `Coefficients`, `Sign_Check`, `Alignment`, `Alignment_Bands`,
  `Model_Card`, `Challenger` and `Swap_Set` (when a challenger exists),
  `Coarse_Classing` and `Decision_Ledger` (after a lab commit).

- `validation_<target>.xlsx`:

  `Score_Gains_Frozen`, `Variable_Gains_IV`, `Discrimination_CI`,
  `Stability_PSI_Timeline`, `Stability_CSI_Timeline`,
  `Stability_Variables`, `Calibration`, `Calibration_Bands`,
  `Performance_By_Vintage`, `Rank_Order_Diagnostics`.

- `strategy_<target>.xlsx`:

  `Population_Scope`, `Band_Coverage`, `Cutoff_Sweep`, `Strategy_Bands`,
  `Reject_Sensitivity`, `Monitoring_Plan`.

For an `scr_classing` lab: one workbook (`classing_<target>.xlsx`) with
the specification, the bins, the checks and the decision ledger. The IRB
models write one workbook and one SQL file each (`pd_<target>.xlsx`,
`lgd_<tag>.xlsx`, `ead_<tag>.xlsx`, `capital_<framework>.xlsx`), with
the validation, the ledger and the model card as sheets.

The timeline and vintage sheets need the date column of the split; when
it is absent they carry an availability row instead of a fabricated
number.

## See also

Other production:
[`predict.scr_align()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_align.md),
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md),
[`scr_monitoring_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_monitoring_plan.md),
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
#>   /tmp/RtmphiLgQt/scorecraft-example/selection_default.xlsx
#>   /tmp/RtmphiLgQt/scorecraft-example/sql_woe_default.sql
#>   /tmp/RtmphiLgQt/scorecraft-example/summary_default.md
basename(unlist(res$files))
#> [1] "selection_default.xlsx" "sql_woe_default.sql"    "summary_default.md"    
sc <- scr_export(scr_scorecard(res), out, stamp = FALSE)
#>   /tmp/RtmphiLgQt/scorecraft-example/scorecard_default.xlsx
#>   /tmp/RtmphiLgQt/scorecraft-example/validation_default.xlsx
#>   /tmp/RtmphiLgQt/scorecraft-example/strategy_default.xlsx
#>   /tmp/RtmphiLgQt/scorecraft-example/sql_score_default.sql
#>   /tmp/RtmphiLgQt/scorecraft-example/sql_woe_default.sql
basename(unlist(sc$files))
#> [1] "scorecard_default.xlsx"  "validation_default.xlsx"
#> [3] "strategy_default.xlsx"   "sql_score_default.sql"  
#> [5] "sql_woe_default.sql"    
```
