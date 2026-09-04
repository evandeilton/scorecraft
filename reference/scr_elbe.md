# ELBE and in-default LGD on a grid of months since default

For every pool and every reference age `tau` of the grid, the expected
loss best estimate is the mean realised LGD of the training defaults of
the pool that were still in workout at `tau` (so that at `tau = 0` it
equals the pool's long-run average), and the in-default LGD adds the
unexpected-loss increment \$\$\Delta^{UL}(\tau) = (\mathrm{LGD}^{DT} -
\mathrm{LRA})\\\frac{\rho(T\_{\max}) - \rho(\tau)}{\rho(T\_{\max})}\$\$
read from the recovery profile of the pool's product mix: the downturn
uplift shrinks as the recoveries come in. The consistency table checks
that `lgd_in_default` at `tau = 0` reproduces the pool's `lgd_dt`.

## Usage

``` r
scr_elbe(x, grid = NULL)
```

## Arguments

- x:

  An
  [`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md)
  object.

- grid:

  Months since default; `NULL` uses `lgd_elbe_grid`.

## Value

An object of class `scr_elbe`: `table` (`months_since_default`, `pool`,
`n_open`, `share_open`, `recovered_share`, `elbe`, `delta_ul`,
`lgd_in_default`), `consistency` (per pool at `tau = 0`), `grid`,
`t_max`.

## See also

Other irb-lgd:
[`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md),
[`scr_lgd_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_downturn.md),
[`scr_lgd_floor()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_floor.md),
[`scr_lgd_pools()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_pools.md),
[`scr_lgd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_validate.md),
[`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, n_boot = 20)
wo <- scr_workout(scr_demo_lgd, scr_demo_lgd_cashflows, rates = scr_demo_rates, config = cfg)
m <- scr_lgd(wo, drivers = c("product", "ltv", "prior_dpd_max"), config = cfg)
e <- scr_elbe(m)
e
#> <scr_elbe> 4 pools x 5 reference ages (months since default: 0, 6, 12, 24, 36) | t_max 60
#>   consistency at tau = 0: ELBE equals the LRA and the in-default LGD equals the downturn LGD
#>   in-default LGD by pool and age
#>   pool       m0      m6     m12     m24     m36
#>   1       42.5%   59.1%   55.3%   47.8%   44.7%
#>   2       53.7%   72.9%   70.5%   64.4%   64.8%
#>   3       67.7%   75.5%   71.6%   69.8%   69.7%
#>   4       77.0%   92.7%   92.2%   83.5%   84.3%
```
