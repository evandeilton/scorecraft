# Two-stage LGD model and pools on the reference data set

Fits the standard two-stage structure on the RDS of
[`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md):
\$\$\mathrm{LGD} = P(\mathrm{cure}\mid
x)\\\mathrm{LGD}^{\mathrm{cure}} + \big(1 - P(\mathrm{cure}\mid
x)\big)\\\mathrm{E}\[\mathrm{LGD}\mid \mathrm{no\\ cure}, x\]\$\$ The
**cure stage** is a binary model on `is_cure` with the scorecard
machinery: optimal binning of the drivers on the training cohorts, WOE,
hold-out revalidation with frozen bins and a logistic regression on the
WOE columns with the sign check (every coefficient positive). The
**severity stage** bins the same drivers against the realised LGD of the
non-cures with
[`scr_bin_continuous()`](https://evandeilton.github.io/scorecraft/reference/scr_bin_continuous.md)
(bin means, monotone, at least `lgd_min_defaults_bin` defaults per bin,
hold-out revalidated) and fits a fractional logit (`glm` with a
quasi-binomial family on the bin means) or, with
`lgd_severity = "beta"`, a beta regression through the `betareg`
package. `LGD^cure` is the mean realised LGD of the cures on train
(costs and the discount effect, never zero by decree).

## Usage

``` r
scr_lgd(
  x,
  drivers,
  config = scr_config(),
  holdout = 0.3,
  date_col = "default_date"
)
```

## Arguments

- x:

  An
  [`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md)
  object.

- drivers:

  Column names of the RDS to use as drivers.

- config:

  A
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md);
  keys `lgd_*`, the binning and hold-out keys of stage 2,
  `max_abs_coef`, `n_boot`, `ci_level`, `seed`, `nthread`.

- holdout:

  Share of the cohorts held out (by default date).

- date_col:

  Column of the RDS with the default date.

## Value

An object of class `scr_lgd`: `split`, `drivers`, `cure` (fit, features,
coef, sign_check, bins, holdout), `severity` (fit, features, coef,
engine, sign_check, bins), `lgd_cure`, `has_cures`, `scored` (one row
per default: `sample`, `p_cure`, `severity`, `lgd_pred`, `pool`,
`lgd_real`), `bins_idx`, `samples` (predicted vs realised by decile of
the prediction), `metrics`, `pools`, `downturn`, `floors`, `workout`
(the profile and summary of the RDS), `model_card`, `ledger`, `config`.

## Details

The split is by cohort of default: the last `holdout` share of the
default dates is the hold-out. Metrics on both samples: RMSE, MAE,
R-squared, Spearman rho, Somers' D of the prediction with respect to the
realised LGD (generalised AUC `(D + 1) / 2`) with a bootstrap confidence
interval, and the loss capture ratio. Pools come from
[`scr_lgd_pools()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_pools.md).
The object carries a provisional downturn (type 3 add-on, or none, by
configuration) and no floor until
[`scr_lgd_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_downturn.md)
and
[`scr_lgd_floor()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_floor.md)
run.

## See also

Other irb-lgd:
[`scr_elbe()`](https://evandeilton.github.io/scorecraft/reference/scr_elbe.md),
[`scr_lgd_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_downturn.md),
[`scr_lgd_floor()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_floor.md),
[`scr_lgd_pools()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_pools.md),
[`scr_lgd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_validate.md),
[`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, n_boot = 20)
wo <- scr_workout(scr_demo_lgd, scr_demo_lgd_cashflows, rates = scr_demo_rates, config = cfg)
m <- scr_lgd(wo, drivers = c("product", "ltv", "prior_dpd_max", "months_on_book", "region"),
             config = cfg)
m
#> <scr_lgd> 885 defaults | train 620 / hold-out 265 (cohort split after 2024-01-01) | cure rate 37.5%
#>   cure stage: prior_dpd_max, months_on_book, region | severity stage (fractional_logit): product, prior_dpd_max, months_on_book | LGD of a cure 4.5%
#>   train    n 620   RMSE 0.2731  R2 0.241  Spearman 0.473  gAUC 0.672 [0.657, 0.686]  LCR 0.403
#>   holdout  n 265   RMSE 0.2655  R2 0.275  Spearman 0.536  gAUC 0.693 [0.644, 0.725]  LCR 0.460
#>   pools 3 | downturn type1 (provisional) | floor not applied
#>   pool   n     pred        LRA     LRA ew   MoC C    LGD DT   floor    final
#>   1    274    0.276     27.5%     23.1%   0.023     44.8%   0.000     44.8%
#>   2    170    0.415     40.0%     38.0%   0.038     58.8%   0.000     58.8%
#>   3    176    0.554     59.3%     42.8%   0.043     78.6%   0.000     78.6%
m$pools[, c("pool", "n", "lra", "lra_ew", "moc_c", "lgd_dt")]
#>     pool     n       lra    lra_ew      moc_c    lgd_dt
#>    <int> <int>     <num>     <num>      <num>     <num>
#> 1:     1   274 0.2749072 0.2306159 0.02281440 0.4477216
#> 2:     2   170 0.4002597 0.3802176 0.03786551 0.5881253
#> 3:     3   176 0.5926373 0.4275209 0.04292232 0.7855596
m$metrics
#> Index: <sample>
#>     sample     n      rmse       mae        r2  spearman  somers_d      gauc
#>     <char> <int>     <num>     <num>     <num>     <num>     <num>     <num>
#> 1:   train   620 0.2730699 0.2445794 0.2411368 0.4725775 0.3442493 0.6721247
#> 2: holdout   265 0.2655118 0.2350532 0.2751904 0.5359311 0.3850772 0.6925386
#>          lcr somers_lo somers_hi   gauc_lo   gauc_hi    lcr_lo    lcr_hi n_boot
#>        <num>     <num>     <num>     <num>     <num>     <num>     <num>  <int>
#> 1: 0.4030191 0.3132275 0.3713491 0.6566138 0.6856745 0.3177067 0.5074543     20
#> 2: 0.4603287 0.2875191 0.4506452 0.6437596 0.7253226 0.3627325 0.5483924     20
#>    level
#>    <num>
#> 1:  0.95
#> 2:  0.95
```
