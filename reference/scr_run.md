# Run the selection for several targets straight from the database

For each target: fetches the table, runs
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
and writes the deliverables. A failure on one target is recorded and the
loop continues.

## Usage

``` r
scr_run(
  con,
  table,
  targets,
  config = scr_config(),
  drop = character(),
  date_col = config$oot_date_col,
  event_level = NULL,
  sample_frac = 1,
  max_rows = NULL,
  export = NULL
)
```

## Arguments

- con:

  A DBI connection, from
  [`scr_connect()`](https://evandeilton.github.io/scorecraft/reference/scr_connect.md).

- table:

  Table name, with an optional `{target}`.

- targets:

  Vector with the names of the target columns.

- config:

  An object from
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md),
  used for every target.

- drop:

  Columns that are never candidates.

- date_col:

  Date column of the out-of-time split, passed on to
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md).
  Defaults to `config$oot_date_col`; an explicit `NULL` forces a random
  stratified split.

- event_level:

  Passed on to
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md).

- sample_frac:

  Sampling fraction. A scalar or a list named by target.

- max_rows:

  Row cap per target. `NULL` switches it off.

- export:

  Root output directory; each target writes to a subdirectory.

## Value

An `scr_runset` object: a named list of `scr_result` (or, for the
targets that failed, a list with `error`).

## Table convention

`table` accepts the `{target}` placeholder, replaced by the lower-case
target name. Without the placeholder, the same table is used for every
target.

## See also

[`scr_compare()`](https://evandeilton.github.io/scorecraft/reference/scr_compare.md)
and
[`scr_core()`](https://evandeilton.github.io/scorecraft/reference/scr_core.md)
to read the run set.

Other portfolio:
[`scr_compare()`](https://evandeilton.github.io/scorecraft/reference/scr_compare.md),
[`scr_core()`](https://evandeilton.github.io/scorecraft/reference/scr_core.md),
[`scr_runset`](https://evandeilton.github.io/scorecraft/reference/scr_runset.md)

## Examples

``` r
con <- scr_connect(driver = RSQLite::SQLite(), dbname = ":memory:")
d <- scr_demo; d$ref_date <- as.character(d$ref_date)   # SQLite has no Date type
DBI::dbWriteTable(con, "dtm", d)
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
rs <- scr_run(con, "dtm", targets = c("default", "churn"), config = cfg,
              drop = c("id", "ref_date", "default", "churn"))
rs
#> <scr_runset> 2 target(s): 2 succeeded, 0 failed
#> 
#>   target           rows approved      AUC       KS
#>   default         4,200       13   0.7523   0.3891
#>   churn           4,200        8   0.7046   0.3048
scr_compare(rs)
#>     target  rows train holdout event_rate candidates triage screening
#>     <char> <int> <int>   <int>      <num>      <int>  <int>     <int>
#> 1: default  4200  2939    1261     0.1432         37     38        22
#> 2:   churn  4200  2939    1261     0.2906         37     35        13
#>    holdout_ok  pool approved max_iv_approved n_iv_suspect best_model    auc
#>         <int> <int>    <int>           <num>        <int>     <char>  <num>
#> 1:         17    13       13           0.332            0     glmnet 0.7523
#> 2:         10     8        8           0.378            0     glmnet 0.7046
#>    auc_lo auc_hi     ks seconds             relaxation
#>     <num>  <num>  <num>   <num>                 <char>
#> 1: 0.7218 0.7852 0.3891       1                   none
#> 2: 0.6710 0.7259 0.3048       1 min_votes reduced to 1
DBI::dbDisconnect(con)
```
