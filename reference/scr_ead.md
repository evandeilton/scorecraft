# Estimate CCF pools from the reference data set

Splits the reference data set by reference date (the most recent cohorts
form the hold-out), bins every driver against the realised CCF with the
continuous binner
([`scr_bin_continuous()`](https://evandeilton.github.io/scorecraft/reference/scr_bin_continuous.md))
on the training rows, revalidates the frozen bins on the hold-out and
admits a driver when it passes the named rules `TOO_FEW_DEFAULTS`,
`NO_SEPARATION`, `NOT_MONOTONIC` and `UNSTABLE_HOLDOUT`. The cells of
the cross of the admitted drivers are ordered by their predicted CCF and
merged, adjacent cells first, down to `config$ccf_n_pools` pools with at
least `config$ccf_min_defaults` defaults each. Rows in the limit-factor
measure form their own pool `LF`.

## Usage

``` r
scr_ead(x, drivers, config = scr_config(), holdout = 0.3, params = NULL)
```

## Arguments

- x:

  An
  [`scr_ead_data()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_data.md)
  object.

- drivers:

  Column names of the candidate drivers (columns of `x$rds`).

- config:

  A
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md).

- holdout:

  Hold-out share, by whole reference dates.

- params:

  An
  [`scr_irb_params()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_params.md)
  object; `NULL` uses the preset of `config$framework`.

## Value

An object of class `scr_ead`: `pools` (the pool table), `cells` (every
cell of the cross with its pool), `bins` (the `obwoe`-shaped fit of the
admitted drivers), `bins_all` (the fit of every driver), `drivers`
(admission table), `holdout` (frozen bins on the hold-out), `rds` (the
reference rows with `sample` and `pool`), `metrics` (per sample: `rmse`,
`mae`, `gauc` with a bootstrap interval, `spearman`, `ead_rmse`,
`ead_mae`, `adequacy`, `cear`), `split`, `funnel`, `data_summary`,
`downturn`, `ledger`, `model_card`, `params`, `config`, `meta`.

## Details

Per pool the estimate is the long-run (default-weighted) average of the
realised values on the training rows, `lra`; `moc_est` is the one-sided
normal estimation-error margin at `config$ccf_moc_alpha`; `ccf_dt` is
the downturn value (equal to `lra` until
[`scr_ead_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_downturn.md)
is run); `ccf_final = max(lra, ccf_dt) + moc_est`;
`ccf_floor = params$ccf_floor_fraction * config$ccf_sa_ccf`; and
`ccf_applied = max(ccf_final, ccf_floor)`. For the `LF` pool the floor
depends on the utilisation and is applied per row by
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md).

## See also

Other irb-ead:
[`scr_bin_continuous()`](https://evandeilton.github.io/scorecraft/reference/scr_bin_continuous.md),
[`scr_ead_data()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_data.md),
[`scr_ead_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_downturn.md),
[`scr_ead_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_validate.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, n_boot = 20, nthread = 1)
ed <- scr_ead_data(scr_demo_ead, facility_id = "facility_id", date_col = "ref_date",
                   limit = "limit", drawn = "drawn", defaulted = "defaulted",
                   drivers = c("product", "months_on_book", "dpd"), config = cfg)
m <- scr_ead(ed, drivers = c("utilisation_ref", "product", "months_on_book"), config = cfg)
m
#> <scr_ead> 2 pool(s) + LF from 135 reference rows | fixed horizon (12 months) | measure auto
#>   split by reference date: train 93 | hold-out 42 (from 2023-12-01) | drivers admitted: product
#>   floor 0.2000 (= 0.5 x SA-CCF 0.4) | MoC alpha 0.05 | downturn none
#>   pool  meas       n      lra   lra_ew      moc   ccf_dt    final    floor  applied
#>   P1    ulf       41   0.3401   0.2691   0.0977   0.3401   0.4377   0.2000   0.4377
#>   P2    ulf       45   0.5349   0.5420   0.0897   0.5349   0.6245   0.2000   0.6245
#>   LF    lf         7   0.8727   0.8623   0.1235   0.8727   0.9962      row   0.9962
#>   train    n    93 | RMSE 0.3683 | MAE 0.2818 | gAUC 0.5953 [0.5374, 0.6471] | EAD adequacy 0.8330 | CEAR -0.1294
#>   holdout  n    42 | RMSE 0.4432 | MAE 0.2671 | gAUC 0.6248 [0.5159, 0.6777] | EAD adequacy 0.9733 | CEAR -0.2516
m$pools
#>      pool measure     n       lra    lra_ew         se    moc_est    ccf_dt
#>    <char>  <char> <int>     <num>     <num>      <num>      <num>     <num>
#> 1:     P1     ulf    41 0.3400611 0.2690775 0.05936758 0.09765098 0.3400611
#> 2:     P2     ulf    45 0.5348808 0.5420090 0.05450656 0.08965532 0.5348808
#> 3:     LF      lf     7 0.8726786 0.8623423 0.07510078 0.12352978 0.8726786
#>    downturn ccf_final ccf_floor ccf_applied floor_binding   ccf_min  ccf_max
#>      <char>     <num>     <num>       <num>        <lgcl>     <num>    <num>
#> 1:     none 0.4377121       0.2   0.4377121         FALSE 0.0000000 1.216255
#> 2:     none 0.6245361       0.2   0.6245361         FALSE 0.0000000 1.603448
#> 3:     none 0.9962084        NA   0.9962084         FALSE 0.6266667 1.045500
#>    share_above_one
#>              <num>
#> 1:       0.1463415
#> 2:       0.1111111
#> 3:       0.5714286
m$drivers
#> Index: <admitted>
#>            feature        type n_bins         eta2       direction    p_anova
#>             <char>      <char>  <int>        <num>          <char>      <num>
#> 1: utilisation_ref   numerical      1 2.123977e-32      decreasing         NA
#> 2:         product categorical      2 6.526113e-02 ordered_by_mean 0.01759988
#> 3:  months_on_book   numerical      1 2.123977e-32      decreasing         NA
#>    eta2_holdout          psi psi_flag admitted        reason
#>           <num>        <num>   <char>   <lgcl>        <char>
#> 1: 1.539257e-32 0.0000000000   stable    FALSE NO_SEPARATION
#> 2: 3.298059e-02 0.0004899915   stable     TRUE            OK
#> 3: 1.539257e-32 0.0000000000   stable    FALSE NO_SEPARATION
```
