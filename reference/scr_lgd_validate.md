# Validation battery of an LGD model

Runs the three blocks of the usual LGD validation on the hold-out sample
(or on `newdata`) against the training reference:

## Usage

``` r
scr_lgd_validate(x, newdata = NULL)
```

## Arguments

- x:

  An
  [`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md)
  object.

- newdata:

  `NULL` (the hold-out), an
  [`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md)
  object or a table with the drivers, `lgd_real`, `ead` and the default
  date.

## Value

An object of class `scr_lgd_validation`: `calibration` (per pool),
`portfolio`, `discrimination`, `stability` (`pools`, `drivers`),
`homogeneity`, `heterogeneity`, `summary` (test, statistic, p, light),
`sample`, `n`.

## Details

- **Calibration.** Per pool and for the portfolio, the one-sided t-test
  of realised against estimated LGD (the pool long-run average), where
  under-estimation is the failure: `p = 1 - Phi(t)`; the loss shortfall
  `1 - sum(LGD_real E) / sum(LGD_pred E)`; the coverage of the realised
  mean by the downturn LGD; the regression of realised on predicted.

- **Discrimination.** Somers' D / generalised AUC of the prediction with
  its bootstrap interval, compared with the training value through
  `S = (gAUC_init - gAUC_curr) / sigma_curr`; Spearman rho; the loss
  capture ratio; R-squared.

- **Stability.** PSI of the pool distribution and of the bins of every
  driver of both stages, with the fixed and the n-adjusted threshold.

- **Pools.** Homogeneity within a pool (Welch test between the halves of
  the pool split at its median prediction; a small p-value means a pool
  that still discriminates) and heterogeneity between adjacent pools
  (Welch test; a large p-value means pools that do not differ).

Traffic lights use the p-value thresholds of `pd_lights` (red below the
first, amber below the second) and the fixed PSI thresholds.

## See also

Other irb-lgd:
[`scr_elbe()`](https://evandeilton.github.io/scorecraft/reference/scr_elbe.md),
[`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md),
[`scr_lgd_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_downturn.md),
[`scr_lgd_floor()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_floor.md),
[`scr_lgd_pools()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_pools.md),
[`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, n_boot = 20)
wo <- scr_workout(scr_demo_lgd, scr_demo_lgd_cashflows, rates = scr_demo_rates, config = cfg)
m <- scr_lgd(wo, drivers = c("product", "ltv", "prior_dpd_max"), config = cfg)
v <- scr_lgd_validate(m)
v
#> <scr_lgd_validation> sample holdout | n 265
#>   calibration: realised 41.7% vs estimate 39.7% | t 1.03 p 0.152 [green] | loss shortfall -0.9% | downturn covers: TRUE
#>   discrimination: gAUC 0.686 [0.647, 0.726] vs initial 0.655 (S -1.53, p 0.937) [green] | Spearman 0.530 | LCR 0.473
#>   stability: pool PSI 0.0014 (stable; adjusted stable) | drivers: prior_dpd_max_cure 0.009, product_sev 0.001, prior_dpd_max_sev 0.001
#>   calibration_portfolio_t        green  
#>   calibration_pools_t            red    
#>   loss_shortfall                 amber  
#>   downturn_coverage              green  
#>   gauc_vs_initial                green  
#>   psi_pools                      green  
#>   psi_drivers                    green  
#>   homogeneity_within_pools       red    
#>   heterogeneity_between_pools    red    
v$calibration
#>     pool     n       ead   lgd_est    lgd_dt real_mean   real_ew   real_lo
#>    <int> <int>     <num>     <num>     <num>     <num>     <num>     <num>
#> 1:     1    81 8865610.8 0.2498970 0.4251785 0.2349736 0.2399839 0.1867959
#> 2:     2    74 4280608.7 0.3508759 0.5366786 0.3765230 0.4105957 0.3118399
#> 3:     3    43  531740.4 0.4747053 0.6767146 0.4580201 0.5250093 0.3565899
#> 4:     4    67 3007941.1 0.5750268 0.7699414 0.6535475 0.5271459 0.5909326
#>      real_hi          t           p dt_covers  light
#>        <num>      <num>       <num>    <lgcl> <char>
#> 1: 0.2831513 -0.6071256 0.728116210      TRUE  green
#> 2: 0.4412062  0.7771488 0.218535493      TRUE  green
#> 3: 0.5594504 -0.3224176 0.626431831      TRUE  green
#> 4: 0.7161625  2.4578895 0.006987808      TRUE    red
```
