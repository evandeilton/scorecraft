# Downturn LGD per pool

Quantifies the downturn per pool from user-supplied downturn periods.
`method = "type1"` (observed impact): the default-weighted realised LGD
of the defaults whose default date falls inside the periods; a pool with
fewer than ten such defaults falls back to type 3. `method = "type3"`:
the long-run average plus `add_on`. `method = "none"`: the long-run
average. The reference value (a challenger, not a bound) is the mean of
the two worst calendar years of the pool. The downturn LGD used for
capital is \$\$\mathrm{LGD}^{DT} = \min\\\big(1,\\ \max(\mathrm{LRA} +
\mathrm{MoC},\\ \mathrm{DT} + \mathrm{MoC})\big)\$\$ and the impact
`LGD^DT - min(1, LRA + MoC)` is reported per pool.

## Usage

``` r
scr_lgd_downturn(
  x,
  periods = NULL,
  method = NULL,
  add_on = NULL,
  reason = NULL
)
```

## Arguments

- x:

  An
  [`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md)
  object.

- periods:

  A table with `start` and `end` dates of the downturn periods. Required
  for `"type1"`.

- method:

  `"type1"`, `"type3"` or `"none"`; `NULL` uses `lgd_downturn`.

- add_on:

  Type-3 add-on; `NULL` uses `lgd_downturn_add_on`.

- reason:

  Free text recorded in the ledger. Mandatory when `method` or `add_on`
  differ from the configuration.

## Value

The `scr_lgd` object with `downturn` (`table` per pool: `lra`, `moc_c`,
`dt_observed`, `n_downturn`, `dt_type3`, `reference_value`,
`method_used`, `dt`, `lgd_dt`, `impact`, `below_reference`; `periods`,
`method`, `add_on`, `status`, `reason`) and the pool columns `lgd_dt`
and `lgd_final` updated.

## See also

Other irb-lgd:
[`scr_elbe()`](https://evandeilton.github.io/scorecraft/reference/scr_elbe.md),
[`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md),
[`scr_lgd_floor()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_floor.md),
[`scr_lgd_pools()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_pools.md),
[`scr_lgd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_validate.md),
[`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, n_boot = 20)
wo <- scr_workout(scr_demo_lgd, scr_demo_lgd_cashflows, rates = scr_demo_rates, config = cfg)
m <- scr_lgd(wo, drivers = c("product", "ltv", "prior_dpd_max"), config = cfg)
m <- scr_lgd_downturn(m, periods = data.frame(start = as.Date("2022-01-01"),
                                               end = as.Date("2023-12-31")))
m$downturn$table
#>     pool     n       lra      moc_c reference_value  dt_type3 dt_observed
#>    <int> <int>     <num>      <num>           <num>     <num>       <num>
#> 1:     1   188 0.2498970 0.02528145       0.2812681 0.3998970   0.2480498
#> 2:     2   165 0.3508759 0.03580269       0.4668095 0.5008759   0.4306490
#> 3:     3   107 0.4747053 0.05200935       0.5556376 0.6247053   0.4912879
#> 4:     4   160 0.5750268 0.04491468       0.6789895 0.7250268   0.6253841
#>    n_downturn method_used        dt    lgd_dt     impact below_reference
#>         <int>      <char>     <num>     <num>      <num>          <lgcl>
#> 1:         80       type1 0.2480498 0.2751785 0.00000000            TRUE
#> 2:         70       type1 0.4306490 0.4664517 0.07977312            TRUE
#> 3:         46       type1 0.4912879 0.5432972 0.01658261            TRUE
#> 4:         73       type1 0.6253841 0.6702988 0.05035731            TRUE
```
