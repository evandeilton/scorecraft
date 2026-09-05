# Input floor on the downturn LGD per pool

Applies the LGD input floor of the framework's parameter table, blended
between the unsecured and the collateralised floor with the secured
share of the exposure: \$\$\mathrm{floor} = \mathrm{floor}\_U\\(1 - s) +
\mathrm{floor}\_S\\s,\qquad \mathrm{LGD}^{\mathrm{final}} =
\max(\mathrm{LGD}^{DT}, \mathrm{floor})\$\$ A missing unsecured floor
(residential mortgages, whose floor applies to the whole exposure) uses
the collateral floor throughout; an asset class with no floor at all
yields a floor of zero.

## Usage

``` r
scr_lgd_floor(
  x,
  params = NULL,
  asset_class = NULL,
  secured_share = NULL,
  collateral = c("real_estate", "financial", "receivables", "other_physical")
)
```

## Arguments

- x:

  An
  [`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md)
  object.

- params:

  An
  [`scr_irb_params()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_params.md)
  object; `NULL` uses the configured framework. Edits are detected and
  recorded in the ledger.

- asset_class:

  Row of `params$lgd_floor`; `NULL` uses `asset_class` of the
  configuration.

- secured_share:

  Secured share of the exposure in `[0, 1]`: one value or one per pool.
  `NULL` means unsecured.

- collateral:

  Column of `params$lgd_floor` for the secured part: `"real_estate"`,
  `"financial"`, `"receivables"` or `"other_physical"`.

## Value

The `scr_lgd` object with `floors` (`table` per pool with `lgd_dt`,
`floor_unsecured`, `floor_secured`, `secured_share`, `floor`,
`lgd_final`, `binding`; `asset_class`, `collateral`, `framework`,
`params_modified`, `binding_share`) and the pool columns `floor` and
`lgd_final` updated.

## See also

Other irb-lgd:
[`scr_elbe()`](https://evandeilton.github.io/scorecraft/reference/scr_elbe.md),
[`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md),
[`scr_lgd_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_downturn.md),
[`scr_lgd_pools()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_pools.md),
[`scr_lgd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_validate.md),
[`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, n_boot = 20)
wo <- scr_workout(scr_demo_lgd, scr_demo_lgd_cashflows, rates = scr_demo_rates, config = cfg)
m <- scr_lgd(wo, drivers = c("product", "ltv", "prior_dpd_max"), config = cfg)
m <- scr_lgd_floor(m, asset_class = "retail_other", secured_share = 0.4)
m$floors$table
#>     pool     n    lgd_dt floor_unsecured floor_secured secured_share floor
#>    <int> <int>     <num>           <num>         <num>         <num> <num>
#> 1:     1   188 0.4251785             0.3           0.1           0.4  0.22
#> 2:     2   165 0.5366786             0.3           0.1           0.4  0.22
#> 3:     3   107 0.6767146             0.3           0.1           0.4  0.22
#> 4:     4   160 0.7699414             0.3           0.1           0.4  0.22
#>    lgd_final binding
#>        <num>  <lgcl>
#> 1: 0.4251785   FALSE
#> 2: 0.5366786   FALSE
#> 3: 0.6767146   FALSE
#> 4: 0.7699414   FALSE
```
