# Bin drivers against a continuous target (LGD, CCF)

Supervised binning for a bounded continuous target, with the result in
the shape of an `obwoe` object, so that the
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
and
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
machinery
([`OptimalBinningWoE::obwoe_apply()`](https://evandeilton.github.io/OptimalBinningWoE/reference/obwoe_apply.html)
and
[`OptimalBinningWoE::obwoe_sql()`](https://evandeilton.github.io/OptimalBinningWoE/reference/obwoe_sql.html))
reproduces the bin statistic unchanged. The `woe` slot of every bin
carries the target mean of the bin (or its logit with
`scale = "logit"`); `iv` carries the bin's share of the between-bin sum
of squares, so `total_iv` is the eta-squared of the driver, in `[0, 1]`.

## Usage

``` r
scr_bin_continuous(
  data,
  target,
  features,
  train_idx = NULL,
  holdout_idx = NULL,
  min_bins = 2L,
  max_bins = 6L,
  min_share = 0.05,
  min_n = 30L,
  monotone = c("auto", "increasing", "decreasing", "none"),
  scale = c("mean", "logit"),
  nthread = 1L,
  alpha = 0.05
)
```

## Arguments

- data:

  A `data.frame` or `data.table`.

- target:

  Column name of the continuous target.

- features:

  Column names of the drivers.

- train_idx, holdout_idx:

  Row indices; `NULL` uses every row for training and skips the
  revalidation.

- min_bins, max_bins:

  Target range of bins per driver.

- min_share:

  Minimum share of training rows per bin.

- min_n:

  Minimum number of training rows per bin.

- monotone:

  `"auto"` (direction from the Spearman sign), `"increasing"`,
  `"decreasing"` or `"none"`.

- scale:

  `"mean"` (bin mean in the `woe` slot) or `"logit"`.

- nthread:

  Parallel workers by driver, through the package backend.

- alpha:

  Alpha of the PSI critical value in the revalidation.

## Value

An object of class `scr_cbins`: `fit` (the `obwoe`-shaped object),
`summary` (one row per driver: `feature`, `type`, `n_bins`, `eta2`,
`direction`, `converged`, and after revalidation `eta2_holdout`, `psi`,
`psi_flag`, `holdout_ok`, `holdout_reason`), `holdout` (bin table per
driver with train and hold-out means), `scale` and `target`. `summary`
keeps the engine columns (`algorithm`, `total_iv`, `iterations`,
`error`) and, after revalidation, `psi_critical`, `psi_flag_adjusted`
and `pct_unbinned`.

## Details

Numeric drivers must not contain missing values: run
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)
(or impute) first, exactly as the scorecard pipeline does. Categorical
missing values become the level `"NA"`, as in the engine. When a
`holdout_idx` is given, the frozen bins are revalidated: the hold-out
bin means are recomputed, the PSI of the bin shares is reported with the
sample-size-adjusted critical value, and a driver whose hold-out means
break the training order is flagged `UNSTABLE_HOLDOUT`.

## See also

Other irb-ead:
[`scr_ead()`](https://evandeilton.github.io/scorecraft/reference/scr_ead.md),
[`scr_ead_data()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_data.md),
[`scr_ead_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_downturn.md),
[`scr_ead_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_validate.md)

## Examples

``` r
set.seed(1)
d <- data.frame(x = runif(600), g = sample(c("a", "b", "c", "d"), 600, TRUE))
d$y <- pmin(1, pmax(0, 0.2 + 0.6 * d$x + (d$g == "d") * 0.2 + rnorm(600, 0, 0.1)))
cb <- scr_bin_continuous(d, "y", c("x", "g"), train_idx = 1:400, holdout_idx = 401:600)
cb
#> <scr_cbins> 2 driver(s) binned against 'y' (bin statistic: mean)
#>   x                        numerical   6 bins | eta2 0.578 | increasing | hold-out eta2 0.544, PSI 0.030 (stable)
#>   g                        categorical 4 bins | eta2 0.116 | ordered_by_mean | hold-out eta2 0.141, PSI 0.010 (stable) - UNSTABLE_HOLDOUT
cb$fit$results$x$bin
#> [1] "(-Inf;0.247727]"     "(0.247727;0.373063]" "(0.373063;0.486149]"
#> [4] "(0.486149;0.644316]" "(0.644316;0.847882]" "(0.847882;+Inf]"    
cb$fit$results$x$woe    # bin means of y
#> [1] 0.3399106 0.4612338 0.5029509 0.5907939 0.6592490 0.7884400
```
