# Classing specification as a long table, with its file round trip

One row per bin of every variable in the lab, optimal and manual, with
the authoritative columns a reviewer may edit (`lower`/`upper` for
numerics, `categories`/`is_other` for categoricals, `reason`) and
context columns that are regenerated on read. Open ends are written as
`NA`. `scr_classing_read()` validates a file back into a spec and
`scr_classing_import()` turns every variable whose bins differ from the
lab's current ones into a proposal, so a spreadsheet edit never enters
silently.

## Usage

``` r
scr_classing_spec(lab, file = NULL)

scr_classing_read(file, sep = "%;%")

scr_classing_import(lab, file)
```

## Arguments

- lab:

  An object from
  [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md),
  or an `scr_result` returned by
  [`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md).

- file:

  For `scr_classing_spec()`, an optional `.csv` or `.xlsx` path to write
  the table to. For `scr_classing_read()`, the path to read. For
  `scr_classing_import()`, a path or an `scr_classing_spec` object.

- sep:

  Bin separator of the `categories` column (the configuration's
  `bin_separator`). It is validated (no empty category, no category in
  two bins) and recorded on the spec, so that `scr_classing_import()`
  refuses a spec read with a different separator.

## Value

A `data.frame` of class `scr_classing_spec`.

`scr_classing_import()` returns a named list of proposals (one per
variable whose bins differ from the lab's current ones), each to be
accepted or discarded.

## See also

[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
for a complete session, from lab to scorecard.

Other classing:
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md),
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
[`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md),
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
sp <- scr_classing_spec(lab)
sp
#> <scr_classing_spec> 33 bins | 8 variables (1 manual)
#>     variable        type bin_id             bin_label lower upper
#>    ds_region categorical      1         NORTH%;%SOUTH    NA    NA
#>    ds_region categorical      2  EAST%;%WEST%;%CENTRE    NA    NA
#>      ds_band categorical      1                     D    NA    NA
#>      ds_band categorical      2                     C    NA    NA
#>      ds_band categorical      3                     B    NA    NA
#>      ds_band categorical      4                     A    NA    NA
#>  vl_score_01     numeric      1      (-Inf;33.360000]    NA 33.36
#>  vl_score_01     numeric      2 (33.360000;38.150000] 33.36 38.15
#>  vl_score_01     numeric      3 (38.150000;44.240000] 38.15 44.24
#>  vl_score_01     numeric      4 (44.240000;48.060000] 44.24 48.06
#>  vl_score_01     numeric      5 (48.060000;63.940000] 48.06 63.94
#>  vl_score_01     numeric      6 (63.940000;72.610000] 63.94 72.61
#>            categories is_other  source                         reason
#>         NORTH%;%SOUTH    FALSE  manual edge/core is what pricing uses
#>  EAST%;%WEST%;%CENTRE    FALSE  manual edge/core is what pricing uses
#>                     D    FALSE optimal                           <NA>
#>                     C    FALSE optimal                           <NA>
#>                     B    FALSE optimal                           <NA>
#>                     A    FALSE optimal                           <NA>
#>                  <NA>    FALSE optimal                           <NA>
#>                  <NA>    FALSE optimal                           <NA>
#>                  <NA>    FALSE optimal                           <NA>
#>                  <NA>    FALSE optimal                           <NA>
#>                  <NA>    FALSE optimal                           <NA>
#>                  <NA>    FALSE optimal                           <NA>
#>   ... (+21 rows)
# round trip through a file: a fresh lab receives the manual bins as proposals
f <- tempfile(fileext = ".csv")
scr_classing_spec(lab, file = f)
#> classing spec written to /tmp/Rtmpe0rh5o/file18cd34cd50d0.csv
props <- scr_classing_import(scr_coarse_classing(res), scr_classing_read(f))
names(props)
#> [1] "ds_region"
unlink(f)
```
