# Build the realised-CCF reference data set from facility snapshots

One row per default event (or per event and reference date under the
variable-horizon comparison), with the facility as it stood at the
reference date and the realised exposure at default (EAD) at the default
date, from which the realised credit conversion factor (CCF) follows.
The reference date follows `config$ccf_horizon`: `"fixed"` takes the
snapshot `ccf_horizon_months` before the default month (the nearest
earlier snapshot when that month is missing; the first snapshot for a
facility younger than the horizon, flagged `FAST_DEFAULT`); `"cohort"`
takes the start of the calendar cohort window in which the default
falls; `"variable"` takes every snapshot in the horizon before the
default, for comparison only.

## Usage

``` r
scr_ead_data(
  snapshots,
  facility_id,
  obligor_id = NULL,
  date_col,
  limit,
  drawn,
  default_date = NULL,
  defaulted = NULL,
  drivers = NULL,
  config = scr_config(),
  keep_rows = FALSE
)
```

## Arguments

- snapshots:

  A `data.frame` or `data.table` with one row per facility and month.

- facility_id, date_col, limit, drawn:

  Column names of the facility identifier, the snapshot month, the limit
  and the drawn amount.

- obligor_id:

  Column name of the obligor, optional. With
  `config$default_level = "obligor"` a default of any facility of the
  obligor is a default of all its facilities observed at that date.

- default_date:

  Either the name of a column of `snapshots` holding the default date of
  the facility (`NA` when it never defaults) or a `data.frame` with the
  facility identifier column (same name as `facility_id`) and a
  `default_date` column, one row per event.

- defaulted:

  Column name of a 0/1 default flag per snapshot, alternative to
  `default_date`: every run of ones opens an event at its first month.

- drivers:

  Column names measured at the reference date and carried into the data
  set (candidate drivers of the pools). `utilisation_ref`, `limit_ref`,
  `drawn_ref` and `horizon_months` are always available.

- config:

  A
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md);
  keys `ccf_*`, `post_default_drawings_in`, `default_level`.

- keep_rows:

  If `TRUE`, keeps every candidate event with its exclusion rule in
  `rows`.

## Value

An object of class `scr_ead_data`: `rds` (one row per event: `event_id`,
`facility_id`, `obligor_id`, `ref_date`, `default_date`, `cohort`,
`horizon_months`, `fast_default`, `limit_ref`, `drawn_ref`,
`undrawn_ref`, `utilisation_ref`, `limit_default`, `limit_change`,
`ead_realised`, `measure`, `ccf_raw`, `ccf`, `rule`, drivers), `funnel`
(`rule`, `action`, `n`, `share`), `summary` (simple and
exposure-weighted averages by cohort and measure, with a total row),
`lra` (long-run averages and shares), `meta`, `ledger`, `config` and
`rows` (with `keep_rows = TRUE`).

## Details

The realised measure per row follows `config$ccf_measure`: under
`"auto"` the undrawn-limit factor (CCF) when the utilisation at the
reference date is below `ccf_u_star` and the limit factor (LF) at or
above it; rows with nothing undrawn or over the limit at the reference
date are always routed to the limit factor (`ZERO_UNDRAWN`,
`OVER_LIMIT_AT_REF`), never dropped. The raw realised value is kept in
`ccf_raw`; `ccf` carries the value after the optional floor
(`ccf_floor_realised`) and cap (`ccf_cap_realised`), both logged in the
funnel (`NEGATIVE_CCF_FLOORED`, `CCF_ABOVE_ONE`). The realised EAD is
the drawn amount at the default date, uncapped; with
`post_default_drawings_in = "ccf"` it is the maximum drawn amount over
the default event when `defaulted` is given.

## References

Basel Committee on Banking Supervision (2023). *The Basel Framework*,
CRE32 and CRE36. Moral, G. (2006). EAD estimates for facilities with
explicit limits. In Engelmann, B. and Rauhmeier, R. (eds), *The Basel II
Risk Parameters*. Springer.

## See also

Other irb-ead:
[`scr_bin_continuous()`](https://evandeilton.github.io/scorecraft/reference/scr_bin_continuous.md),
[`scr_ead()`](https://evandeilton.github.io/scorecraft/reference/scr_ead.md),
[`scr_ead_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_downturn.md),
[`scr_ead_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_validate.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE)
ed <- scr_ead_data(scr_demo_ead, facility_id = "facility_id", obligor_id = "obligor_id",
                   date_col = "ref_date", limit = "limit", drawn = "drawn",
                   defaulted = "defaulted",
                   drivers = c("product", "months_on_book", "dpd"), config = cfg)
ed
#> <scr_ead_data> 197 rows from 197 default events | 1,200 facilities x 34,811 snapshots
#>   horizon: fixed (12 months) | measure: auto (u* = 0.95) | reference dates 2023-01-01 to 2024-06-01 (1.4 years)
#>   ULF: LRA simple 0.3248 | exposure-weighted 0.2889 | n = 189
#>   LF rows 4.1% | above one 7.4% | negative (raw) 23.8% | fast defaults 19.8%
#>   funnel:
#>     FAST_DEFAULT             kept              25 (12.7%)
#>     OVER_LIMIT_AT_REF        routed_to_lf       7 (3.6%)
#>     NEGATIVE_CCF_FLOORED     floored           45 (22.8%)
#>     CCF_ABOVE_ONE            kept              14 (7.1%)
#>     OK                       kept             106 (53.8%)
#>   note: fewer than five years of reference dates; the average is not a long-run one yet
ed$funnel
#>                    rule       action     n      share
#>                  <char>       <char> <int>      <num>
#> 1:         FAST_DEFAULT         kept    25 0.12690355
#> 2:    OVER_LIMIT_AT_REF routed_to_lf     7 0.03553299
#> 3: NEGATIVE_CCF_FLOORED      floored    45 0.22842640
#> 4:        CCF_ABOVE_ONE         kept    14 0.07106599
#> 5:                   OK         kept   106 0.53807107
head(ed$rds[, c("facility_id", "ref_date", "default_date", "utilisation_ref", "measure", "ccf")])
#>    facility_id   ref_date default_date utilisation_ref measure       ccf
#>         <char>     <Date>       <Date>           <num>  <char>     <num>
#> 1:       F0031 2023-01-01   2023-08-01          0.5200     ulf 0.0000000
#> 2:       F0062 2023-01-01   2023-11-01          0.4600     ulf 0.0000000
#> 3:       F0093 2023-01-01   2023-07-01          0.6485     ulf 0.1493599
#> 4:       F0103 2023-01-01   2023-12-01          0.3400     ulf 0.0000000
#> 5:       F0108 2023-01-01   2024-01-01          0.1300     ulf 0.2643678
#> 6:       F0109 2023-01-01   2023-08-01          0.3650     ulf 0.4645669
```
