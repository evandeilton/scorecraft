# Production SQL

Code ready to run in the database, covering **exactly** the approved
variables (or those of the scorecard), in blocks in this order:

## Usage

``` r
scr_sql(x, table = NULL, dialect = NULL, file = NULL, ...)

# S3 method for class 'scr_capital'
scr_sql(
  x,
  table = NULL,
  dialect = NULL,
  file = NULL,
  level = c("exposure", "portfolio"),
  ...
)

# S3 method for class 'scr_ead'
scr_sql(x, table = NULL, dialect = NULL, file = NULL, ...)

# S3 method for class 'scr_lgd'
scr_sql(x, table = NULL, dialect = NULL, file = NULL, ...)

# S3 method for class 'scr_pd'
scr_sql(x, table = NULL, dialect = NULL, file = NULL, ...)

# S3 method for class 'scr_result'
scr_sql(x, table = NULL, dialect = NULL, file = NULL, output = NULL, ...)

# S3 method for class 'scr_scorecard'
scr_sql(
  x,
  table = NULL,
  dialect = NULL,
  file = NULL,
  what = c("score", "woe", "all"),
  keep_columns = NULL,
  ...
)
```

## Arguments

- x:

  An object from
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md),
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
  [`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md),
  [`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md),
  [`scr_ead()`](https://evandeilton.github.io/scorecraft/reference/scr_ead.md)
  or
  [`scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_capital.md).

- table:

  Source table name. `NULL` uses `config$sql_table`.

- dialect:

  Dialect (`"ansi"`, `"databricks"`, `"spark"`, `"hive"`, `"mysql"`,
  `"mariadb"`, `"sqlserver"`, `"bigquery"`, `"postgres"`, `"oracle"`,
  `"snowflake"`, `"redshift"`, `"duckdb"`, `"sqlite"`). `NULL` uses
  `config$sql_dialect`.

- file:

  Path to write to. `NULL` (default) returns the lines.

- ...:

  Passed on to the methods.

- level:

  For `scr_capital`: `"exposure"` (default, one row per exposure with
  `el`, `k`, `rw`, `rwa`) or `"portfolio"` (the aggregate by segment).

- output:

  For `scr_result`: `"woe"`, `"bin"` or `"both"`. `NULL` uses
  `config$sql_output`.

- what:

  For `scr_scorecard`: `"score"` (default: the three blocks, with the
  points per variable, the exact score and the whole-points score),
  `"woe"` (the WOE/BIN SQL of the scorecard variables only) or `"all"`
  (the three blocks plus, for every variable, its bin label, WOE and
  points side by side: the deployment layout that reports the band of
  each variable next to the score).

- keep_columns:

  For `scr_scorecard`: key columns carried untransformed into the output
  (for example the customer identifier and the reference date); `NULL`
  uses `config$sql_keep_columns`.

## Value

A character vector with the SQL (invisibly, when `file` is given).

## Details

1.  CTE `base_scr`: reproduces the Stage 1 pre-processing - imputation
    of missing and sentinel by the **training** median,
    special-population flags, `COALESCE` of the categorical missing.

2.  The WOE/BIN transformation, emitted by
    [`OptimalBinningWoE::obwoe_sql()`](https://evandeilton.github.io/OptimalBinningWoE/reference/obwoe_sql.html)
    from the authoritative cut points with full precision.

3.  (Scorecard) CTE `woe_scr` with WOE and bin index, followed by the
    final `SELECT` with `score` (exact, `a + b * logit`), `<f>_points`
    per variable and `score_points` (whole points).

The order matters: without the first block, the WOE would be applied to
data different from what was binned. The score computed by the SQL
matches
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
numerically, by an automated test that runs both paths.

## IRB models

`scr_pd` wraps the scorecard SQL in a common table expression and adds a
`CASE` on the score cut points that yields `grade` and `pd_final`.
`scr_lgd` chains the driver bins of both stages, the logits, the pool
`CASE` and the floored result. `scr_ead` computes the utilisation and
the undrawn amount, assigns the pool from the frozen cut points and
applies the greatest of the model, the drawn amount and the standardised
floor. `scr_capital` carries the constants of every pool (PD, LGD, `k`,
risk weight) in a `pool_params` table joined on segment and grade, so no
normal quantile is evaluated at run time; `level` chooses the exposure
or the portfolio output.

## See also

Other production:
[`predict.scr_align()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_align.md),
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md),
[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md),
[`scr_monitoring_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_monitoring_plan.md),
[`scr_reasons()`](https://evandeilton.github.io/scorecraft/reference/scr_reasons.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
cat(head(scr_sql(res, table = "prd.customers", dialect = "databricks"), 20), sep = "\n")
#> -- =============================================================
#> -- scorecraft | target: default | 12 approved variables | dialect: databricks
#> -- Generated on 2026-09-05 18:07:02
#> -- Block 1 (CTE base_scr): Stage 1 pre-processing - imputation of missing
#> --   and sentinel values by the TRAINING median, special-population flags.
#> -- Block 2: WOE/BIN transformation emitted by OptimalBinningWoE::obwoe_sql().
#> -- =============================================================
#> 
#> WITH base_scr AS (
#>   SELECT
#>     CASE WHEN vl_score_01 IS NULL OR vl_score_01 IN (-999) THEN 52.75 ELSE vl_score_01 END AS vl_score_01,
#>     CASE WHEN vl_score_02 IS NULL OR vl_score_02 IN (-999) THEN 55.98 ELSE vl_score_02 END AS vl_score_02,
#>     CASE WHEN vl_score_04 IS NULL OR vl_score_04 IN (-999) THEN 61.835 ELSE vl_score_04 END AS vl_score_04,
#>     COALESCE(ds_band, 'MISSING') AS ds_band,
#>     CASE WHEN vl_late IS NULL OR vl_late IN (-999) THEN 0.0065000000000000006 ELSE vl_late END AS vl_late,
#>     COALESCE(ds_region, 'MISSING') AS ds_region,
#>     CASE WHEN vl_score_06 IS NULL OR vl_score_06 IN (-999) THEN 67.815 ELSE vl_score_06 END AS vl_score_06,
#>     CASE WHEN vl_score_07 IS NULL OR vl_score_07 IN (-999) THEN 71.16 ELSE vl_score_07 END AS vl_score_07,
#>     CASE WHEN vl_score_05 IS NULL OR vl_score_05 IN (-999) THEN 65.425000000000011 ELSE vl_score_05 END AS vl_score_05,
#>     COALESCE(ds_channel, 'MISSING') AS ds_channel,
sc <- scr_scorecard(res)
cat(tail(scr_sql(sc), 12), sep = "\n")
#>       CASE vl_score_04_idx WHEN 1 THEN 28 WHEN 2 THEN 24 WHEN 3 THEN 9 WHEN 4 THEN 1 WHEN 5 THEN -6 WHEN 6 THEN -8 WHEN 7 THEN -15 ELSE 0 END AS vl_score_04_points,
#>       CASE ds_band_idx WHEN 1 THEN 13 WHEN 2 THEN 2 WHEN 3 THEN 0 WHEN 4 THEN -11 ELSE 0 END AS ds_band_points,
#>       CASE vl_late_idx WHEN 1 THEN 16 WHEN 2 THEN 7 WHEN 3 THEN 6 WHEN 4 THEN 5 WHEN 5 THEN -5 WHEN 6 THEN -8 WHEN 7 THEN -13 ELSE 0 END AS vl_late_points,
#>       CASE ds_region_idx WHEN 1 THEN 10 WHEN 2 THEN 4 WHEN 3 THEN 0 WHEN 4 THEN -13 WHEN 5 THEN -16 ELSE 0 END AS ds_region_points,
#>       CASE vl_score_06_idx WHEN 1 THEN 9 WHEN 2 THEN 4 WHEN 3 THEN -3 WHEN 4 THEN -4 WHEN 5 THEN -5 WHEN 6 THEN -10 WHEN 7 THEN -15 ELSE 0 END AS vl_score_06_points,
#>       CASE vl_score_07_idx WHEN 1 THEN 14 WHEN 2 THEN 6 WHEN 3 THEN 6 WHEN 4 THEN 1 WHEN 5 THEN -2 WHEN 6 THEN -7 ELSE 0 END AS vl_score_07_points,
#>       CASE vl_score_05_idx WHEN 1 THEN 6 WHEN 2 THEN -3 WHEN 3 THEN -9 WHEN 4 THEN -9 WHEN 5 THEN -14 ELSE 0 END AS vl_score_05_points,
#>       CASE ds_channel_idx WHEN 1 THEN 9 WHEN 2 THEN 4 WHEN 3 THEN -5 ELSE 0 END AS ds_channel_points,
#>       CASE vl_score_10_idx WHEN 1 THEN 2 WHEN 2 THEN -6 WHEN 3 THEN -21 ELSE 0 END AS vl_score_10_points,
#>       CASE vl_hist_04_idx WHEN 1 THEN 19 WHEN 2 THEN 9 WHEN 3 THEN -3 ELSE 0 END AS vl_hist_04_points
#>   FROM woe_scr
#> ) pts;
```
