# LGD pools from the predicted LGD

Cuts the training predictions into `n_pools` quantile bands, merges the
bands with fewer than `min_defaults` defaults into the neighbour with
the closer long-run average, then merges adjacent bands whose long-run
averages break the increasing order (pool-adjacent violators), so that
the pools are ordered both in predicted and in realised LGD. Per pool:
the default-weighted long-run average (the regulatory estimate), the
exposure-weighted one, the standard error, the category-C margin of
conservatism (one-sided 95% t interval on the mean) and their sum.

## Usage

``` r
scr_lgd_pools(x, n_pools = NULL, min_defaults = NULL)
```

## Arguments

- x:

  An
  [`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md)
  object.

- n_pools:

  Target number of pools; `NULL` uses `lgd_n_pools`.

- min_defaults:

  Minimum defaults per pool; `NULL` uses `lgd_min_defaults_bin`.

## Value

A `data.table` with one row per pool: `pool`, `pred_lo`, `pred_hi`,
`pred_mean`, `n`, `share`, `ead`, `lra`, `lra_ew`, `sd`, `se`, `moc_c`,
`lra_moc`, `merged_from`.

## See also

Other irb-lgd:
[`scr_elbe()`](https://evandeilton.github.io/scorecraft/reference/scr_elbe.md),
[`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md),
[`scr_lgd_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_downturn.md),
[`scr_lgd_floor()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_floor.md),
[`scr_lgd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_validate.md),
[`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, n_boot = 20)
wo <- scr_workout(scr_demo_lgd, scr_demo_lgd_cashflows, rates = scr_demo_rates, config = cfg)
m <- scr_lgd(wo, drivers = c("product", "ltv", "prior_dpd_max"), config = cfg)
scr_lgd_pools(m, n_pools = 4)
#>     pool   pred_lo   pred_hi pred_mean     n     share      ead       lra
#>    <int>     <num>     <num>     <num> <int>     <num>    <num>     <num>
#> 1:     1      -Inf 0.3216997 0.2518886   188 0.3032258 24831790 0.2498970
#> 2:     2 0.3216997 0.4098194 0.3850771   165 0.2661290  8375662 0.3508759
#> 3:     3 0.4098194 0.4535521 0.4364856   146 0.2354839  6628595 0.4529029
#> 4:     4 0.4535521       Inf 0.5683979   121 0.1951613  2652442 0.6336688
#>       lra_ew        sd         se      moc_c   lra_moc merged_from
#>        <num>     <num>      <num>      <num>     <num>      <char>
#> 1: 0.2201267 0.2096992 0.01529388 0.02528145 0.2751785           1
#> 2: 0.3281958 0.2780163 0.02164354 0.03580269 0.3866786           2
#> 3: 0.3971602 0.3053699 0.02527259 0.04183702 0.4947399           3
#> 4: 0.4107764 0.3518117 0.03198288 0.05301645 0.6866853           4
```
