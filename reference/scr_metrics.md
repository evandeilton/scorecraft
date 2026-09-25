# AUC, KS and Gini of a score, with a bootstrap confidence interval

AUC through the Mann-Whitney U statistic with tie correction, computed
on the table of counts per unique score: a WOE score is constant within
the bin, so ties are the rule. Everything in `double` on purpose: with
integer counts, `n1 * n0` overflows `2^31` from about 46 thousand
observations per class and returns `NA`.

## Usage

``` r
scr_metrics(
  score,
  y,
  higher_is_event = TRUE,
  ci = TRUE,
  n_boot = 200L,
  level = 0.95,
  seed = NULL,
  nthread = 1L
)
```

## Arguments

- score:

  Numeric vector with the score.

- y:

  0/1 outcome vector, same length as `score`.

- higher_is_event:

  If `TRUE` (default), a higher score means a higher probability of the
  event (logit, probability, propensity score). Pass `FALSE` for a
  credit points score (`higher_is_safer`), and the AUC is reported above
  0.5 when the score ranks correctly.

- ci:

  Compute the confidence interval. `FALSE` returns point estimates only.

- n_boot:

  Number of bootstrap resamples.

- level:

  Confidence level.

- seed:

  Bootstrap seed; `NULL` leaves it unset.

- nthread:

  Parallel workers for the resamples.

## Value

A list of class `scr_metrics` with `auc`, `ks`, `gini`, the bounds
`auc_lo`/`auc_hi`, `ks_lo`/`ks_hi`, `gini_lo`/`gini_hi` (`NA` when
`ci = FALSE`), `n`, `events`, `n_boot` and `level`. Everything is
`NA_real_` when only one class is present or no valid case exists.

DeLong's analytic variance is not used: the interval is a stratified
percentile bootstrap, which also covers KS.

## Details

The confidence interval is **always** computed by default: a bootstrap
stratified by outcome, percentile method, with `n_boot` resamples. Gini
is derived from AUC (`2 * AUC - 1`) inside each resample, never
bootstrapped separately. The cost is absorbed by `nthread` (parallelism
by resample).

## References

DeLong, E. R., DeLong, D. M. and Clarke-Pearson, D. L. (1988). Comparing
the areas under two or more correlated receiver operating characteristic
curves. *Biometrics*, 44(3), 837-845.

## See also

Other metrics:
[`scr_iv()`](https://evandeilton.github.io/scorecraft/reference/scr_iv.md),
[`scr_psi()`](https://evandeilton.github.io/scorecraft/reference/scr_psi.md)

## Examples

``` r
set.seed(1)
y <- rep(0:1, each = 500)
s <- stats::rnorm(1000) + 0.8 * y
m <- scr_metrics(s, y, n_boot = 50, seed = 1)
m
#> <scr_metrics> n = 1,000 | events = 500 | 95% bootstrap CI (50 resamples)
#>   AUC  0.6935 [0.6596, 0.7167]
#>   KS   0.2900 [0.2505, 0.3491]
#>   Gini 0.3870 [0.3192, 0.4334]
as.data.frame(m)
#>      n events      auc    auc_lo   auc_hi   ks   ks_lo  ks_hi     gini
#> 1 1000    500 0.693524 0.6596233 0.716709 0.29 0.25045 0.3491 0.387048
#>     gini_lo  gini_hi n_boot level
#> 1 0.3192466 0.433418     50  0.95
```
