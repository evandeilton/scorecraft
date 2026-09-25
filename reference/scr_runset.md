# Set of runs, one per target

Object returned by
[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md):
a named list of `scr_result`, plus the errors of the targets that
failed. Use
[`scr_compare()`](https://evandeilton.github.io/scorecraft/reference/scr_compare.md)
for the comparison table and
[`scr_core()`](https://evandeilton.github.io/scorecraft/reference/scr_core.md)
for the variables that cross several targets.

## Usage

``` r
# S3 method for class 'scr_runset'
print(x, ...)
```

## Arguments

- x:

  An `scr_runset` object.

- ...:

  Ignored.

## Value

`x`, invisibly.

## See also

Other portfolio:
[`scr_compare()`](https://evandeilton.github.io/scorecraft/reference/scr_compare.md),
[`scr_core()`](https://evandeilton.github.io/scorecraft/reference/scr_core.md),
[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md)

## Examples

``` r
con <- scr_connect(driver = RSQLite::SQLite(), dbname = ":memory:")
d <- scr_demo[, c("default", "ds_region", "ds_band", "vl_score_01",
                  "vl_score_02", "vl_score_05", "vl_hist_01")]
DBI::dbWriteTable(con, "dtm", d)
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 40, n_boot = 10)
rs <- scr_run(con, "dtm", targets = "default", config = cfg)
rs
#> <scr_runset> 1 target(s): 1 succeeded, 0 failed
#> 
#>   target           rows approved      AUC       KS
#>   default         4,200        5   0.7115   0.3376
names(rs)
#> [1] "default"
DBI::dbDisconnect(con)
```
