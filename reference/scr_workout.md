# Workout LGD: the reference data set from default events and cash flows

Builds the reference data set (RDS) of realised loss given default, one
row per default event, from a table of default events and the long table
of their post-default cash flows. Every cash flow is discounted to the
default date at the reference rate in force at that date plus
`lgd_discount_add_on`, with monthly compounding over whole months:
\$\$\mathrm{PV} = \frac{A}{(1 + r/12)^{t}}\$\$ where `t` is the number
of whole months between the default date and the cash-flow date. The
realised LGD is the economic loss \$\$\mathrm{LGD} = \frac{E -
\mathrm{PV}(R) + \mathrm{PV}(C) + \mathrm{PV}(D) +
C^{\mathrm{ind}}}{E}\$\$ with `E` the exposure at default, `R`
recoveries, `C` direct costs, `D` drawings after default and `C^ind` the
indirect costs allocated by `lgd_cost_allocation`.

## Usage

``` r
scr_workout(
  defaults,
  cashflows,
  rates = NULL,
  config = scr_config(),
  indirect_costs = 0,
  obs_date = NULL,
  keep_rows = FALSE
)
```

## Arguments

- defaults:

  A `data.frame` or `data.table` with one row per default event:
  `default_id`, `facility_id`, `default_date`, `ead`, `product`,
  `status` (`"closed"`, `"cured"` or `"open"`), optionally `close_date`,
  plus any driver columns, which are carried into the RDS.

- cashflows:

  Long table: `default_id`, `date`, `amount`, `type` (`"recovery"`,
  `"direct_cost"` or `"drawing"`).

- rates:

  Optional table `(date, rate)` of the annual reference rate; the rate
  in force at the default date is used. `NULL` uses the flat
  `lgd_discount_rate` of the configuration.

- config:

  A
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md);
  keys `lgd_*`.

- indirect_costs:

  Total indirect workout cost to allocate: a single number, or a table
  `(product, amount)` allocated within product.

- obs_date:

  Observation date; `NULL` uses the latest date seen.

- keep_rows:

  Keep the cash-flow table with its present values.

## Value

An object of class `scr_workout`: `rds` (one row per default event:
identifiers, `default_date`, `ead`, `product`, drivers, `status`,
`months_in_default`, `discount_rate`, `pv_recovery`, `pv_cost`,
`pv_drawing`, `cost_indirect`, `recovery_extrapolated`, `lgd_raw`,
`lgd_real`, `is_cure`, `is_incomplete`, `merged_n`), `recovery_profile`
(product x month: `cum_recovery`), `extrapolation` (per open event),
`funnel` (rule, n, action), `summary` (`n`, `cure_rate`,
`lra_default_weighted`, `lra_exposure_weighted`, `share_incomplete`,
`discount_rate_mean`, `by_product`, `by_year`), `ledger`, `config`,
`obs_date`, and `cashflows` with `keep_rows`.

## Rules

- **Cures.** An event with `status == "cured"` returns to performing:
  the balance outstanding at the cure date (`ead` net of the cash
  recovered) enters as an artificial recovery on the cure date, so the
  cure carries its costs and the discount effect, never a zero loss by
  decree.

- **Multiple defaults.** Two defaults of one facility separated by fewer
  than `lgd_cure_window` months (from the close of the first to the
  start of the second), or a new default while the first is still open,
  are one event: the first default date and exposure are kept, the cash
  flows of both spells are pooled and the status of the last spell
  rules.

- **Incomplete workouts.** An open event younger than `lgd_t_max` months
  receives the expected further recovery read from the recovery profile
  of the closed defaults of the same product (cumulative discounted
  recovery rate by month in default); an open event at or beyond
  `lgd_t_max` is treated as closed with no further recovery.

- **Bounds.** With `lgd_floor_at_zero` the realised LGD used in the
  averages is floored at zero and with `lgd_cap_at_one` capped at one;
  `lgd_raw` always keeps the unbounded value.

The long-run average is reported default-weighted (the arithmetic mean
over events) and exposure-weighted, overall, by product and by calendar
year of default.

## See also

Other irb-lgd:
[`scr_elbe()`](https://evandeilton.github.io/scorecraft/reference/scr_elbe.md),
[`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md),
[`scr_lgd_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_downturn.md),
[`scr_lgd_floor()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_floor.md),
[`scr_lgd_pools()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_pools.md),
[`scr_lgd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_validate.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE)
wo <- scr_workout(scr_demo_lgd, scr_demo_lgd_cashflows, rates = scr_demo_rates, config = cfg)
wo
#> <scr_workout> 885 default events | 8 calendar years | observation date 2026-06-28
#>   cure rate 37.5% | incomplete 18.1% | mean discount rate 14.37%
#>   long-run average LGD: 40.5% default-weighted | 29.9% exposure-weighted | raw mean 40.5%
#>   auto         n 203   cure 36.5%   LRA 34.4%   (ew 35.9%)
#>   mortgage     n 237   cure 46.8%   LRA 26.3%   (ew 26.7%)
#>   unsecured    n 445   cure 33.0%   LRA 50.8%   (ew 51.3%)
#>   funnel MULTIPLE_DEFAULT_MERGED      15
#>   funnel OPEN_BEYOND_T_MAX_CLOSED     2
#>   funnel INCOMPLETE_EXTRAPOLATED      160
#>   funnel LGD_ABOVE_ONE                3
wo$funnel
#>                        rule     n
#>                      <char> <int>
#> 1:             NOT_IN_SCOPE     0
#> 2:  MULTIPLE_DEFAULT_MERGED    15
#> 3: CASHFLOW_WITHOUT_DEFAULT     0
#> 4: OPEN_BEYOND_T_MAX_CLOSED     2
#> 5:  INCOMPLETE_EXTRAPOLATED   160
#> 6:     NEGATIVE_LGD_FLOORED     0
#> 7:            LGD_ABOVE_ONE     3
#>                                                                                        action
#>                                                                                        <char>
#> 1:             excluded: EAD <= 0, missing default date or default after the observation date
#> 2:                          merged into the earlier default of the facility (window 9 months)
#> 3:                                          cash-flow rows dropped: no default event in scope
#> 4:                                open for 60 months or more: closed with no further recovery
#> 5: open workouts younger than t_max: expected further recovery added from the product profile
#> 6:                                                  floored at 0 in lgd_real (raw value kept)
#> 7:                                                      kept above 1 (lgd_cap_at_one = FALSE)
#>     kept
#>    <int>
#> 1:   885
#> 2:   885
#> 3:   885
#> 4:   885
#> 5:   885
#> 6:   885
#> 7:   885
head(wo$rds[, c("default_id", "product", "status", "lgd_raw", "lgd_real", "is_cure")])
#>    default_id   product status    lgd_raw   lgd_real is_cure
#>        <char>    <char> <char>      <num>      <num>  <lgcl>
#> 1:      D0660 unsecured  cured 0.03306260 0.03306260    TRUE
#> 2:      D0262 unsecured  cured 0.03609899 0.03609899    TRUE
#> 3:      D0506      auto  cured 0.05858313 0.05858313    TRUE
#> 4:      D0610  mortgage  cured 0.04705677 0.04705677    TRUE
#> 5:      D0516 unsecured closed 0.43716568 0.43716568   FALSE
#> 6:      D0560      auto closed 0.61276545 0.61276545   FALSE
```
