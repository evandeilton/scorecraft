# Downturn CCF per pool

Quantifies the downturn component of the CCF from user-supplied downturn
periods. `"type1"` (observed impact) takes, per pool, the
default-weighted average of the realised values of the events whose
default date falls in the periods and sets
`ccf_dt = max(lra, observed)`; `"type3"` (reference value plus add-on)
sets `ccf_dt = lra + add_on`; `"none"` resets `ccf_dt = lra`. The pool
table is recomputed (`ccf_final`, `ccf_applied`) and the ledger records
the periods, the method and the reason.

## Usage

``` r
scr_ead_downturn(
  x,
  periods = NULL,
  method = NULL,
  add_on = 0.15,
  reason = NULL
)
```

## Arguments

- x:

  An
  [`scr_ead()`](https://evandeilton.github.io/scorecraft/reference/scr_ead.md)
  object.

- periods:

  A `data.frame` with `start` and `end` dates of the downturn periods
  (needed for `"type1"`).

- method:

  `"type1"`, `"type3"` or `"none"`; `NULL` uses `config$ccf_downturn`.

- add_on:

  Add-on of the `"type3"` method, in CCF units.

- reason:

  Text justifying the periods and the method; mandatory.

## Value

The `scr_ead` object with `downturn` (a list with `method`, `periods`,
`add_on` and the per-pool `table`: `pool`, `lra`, `n_downturn`,
`dt_observed`, `dt_type3`, `ccf_dt`), the updated `pools` and a new
ledger row.

## See also

Other irb-ead:
[`scr_bin_continuous()`](https://evandeilton.github.io/scorecraft/reference/scr_bin_continuous.md),
[`scr_ead()`](https://evandeilton.github.io/scorecraft/reference/scr_ead.md),
[`scr_ead_data()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_data.md),
[`scr_ead_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_validate.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, n_boot = 20, nthread = 1)
ed <- scr_ead_data(scr_demo_ead, facility_id = "facility_id", date_col = "ref_date",
                   limit = "limit", drawn = "drawn", defaulted = "defaulted",
                   drivers = c("product", "months_on_book"), config = cfg)
m <- scr_ead(ed, drivers = c("utilisation_ref", "product"), config = cfg)
m2 <- scr_ead_downturn(m, periods = data.frame(start = as.Date("2024-01-01"),
                                               end = as.Date("2024-12-01")),
                       reason = "2024 chosen as the stress year of the demo panel")
m2$downturn$table
#>      pool       lra n_downturn dt_observed  dt_type3    ccf_dt ccf_final
#>    <char>     <num>      <int>       <num>     <num>     <num>     <num>
#> 1:     P1 0.3400611         29   0.3717872 0.4900611 0.3717872 0.4694382
#> 2:     P2 0.5348808         45   0.5588773 0.6848808 0.5588773 0.6485326
#> 3:     LF 0.8726786          7   0.8726786 1.0226786 0.8726786 0.9962084
#>    ccf_applied
#>          <num>
#> 1:   0.4694382
#> 2:   0.6485326
#> 3:   0.9962084
```
