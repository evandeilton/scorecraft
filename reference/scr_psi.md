# Population stability index, with the fixed and the sample-size-adjusted threshold

`PSI = sum((p - q) * ln(p / q))` over bins frozen on the base. Reports
both thresholds side by side: the traditional fixed one (`< 0.10`
`"stable"`, `0.10-0.25` `"moderate"`, `>= 0.25` `"shift"`) and the
sample-size-adjusted critical value of Yurdakul and Naranjo (2020),
under which the PSI is asymptotically
`(1/n + 1/m) * chi-squared(B - 1)`. With `n = m = 1000` and ten bins the
5% critical value is 0.034, not 0.10; on a monthly base of a hundred
thousand rows, `PSI = 0.01` is already significant. The fixed threshold
remains what the market knows; the adjusted one is what the statistics
support.

## Usage

``` r
scr_psi(
  base,
  compare,
  levels = NULL,
  breaks = NULL,
  n_groups = 10L,
  alpha = 0.05,
  thresholds = c(0.1, 0.25)
)
```

## Arguments

- base:

  Reference vector (the "development" distribution).

- compare:

  Vector to compare.

- levels:

  For categorical vectors: the levels to consider. `NULL` uses the union
  of the observed ones.

- breaks:

  For numeric vectors: frozen cut points. `NULL` derives `n_groups`
  quantiles of `base`.

- n_groups:

  Number of bands when `breaks = NULL`.

- alpha:

  Significance level of the adjusted threshold.

- thresholds:

  The two fixed thresholds: below the first the flag is `"stable"`,
  below the second `"moderate"`, otherwise `"shift"`.

## Value

A list of class `scr_psi` with `psi`, `flag_fixed`, `critical` (adjusted
critical value), `flag_adjusted` (`"stable"` or `"shift"`), `n_base`,
`n_compare`, `n_bins` and `table` (per band: `pct_base`, `pct_compare`,
`psi_band`). The `thresholds` and `alpha` used are stored and printed.

## References

Yurdakul, B. and Naranjo, J. (2020). Statistical properties of the
population stability index. *Journal of Risk Model Validation*, 14(4),
89-100.

## See also

Other metrics:
[`scr_iv()`](https://evandeilton.github.io/scorecraft/reference/scr_iv.md),
[`scr_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_metrics.md)

## Examples

``` r
set.seed(2)
base <- stats::rnorm(5000)
new  <- stats::rnorm(5000, mean = 0.15)
p <- scr_psi(base, new)
p
#> <scr_psi> PSI = 0.0143 | bands = 10 | n = 5,000 vs 5,000
#>   fixed threshold (0.1/0.25):       stable
#>   n-adjusted threshold (0.0068):     shift  [Yurdakul & Naranjo, alpha = 0.05]
p$table
#>               band n_base n_compare pct_base pct_compare     psi_band
#> 1     [-Inf,-1.25]    500       421      0.1      0.0842 2.717209e-03
#> 2   (-1.25,-0.822]    500       427      0.1      0.0854 2.304232e-03
#> 3  (-0.822,-0.495]    500       474      0.1      0.0948 2.776840e-04
#> 4  (-0.495,-0.214]    500       474      0.1      0.0948 2.776840e-04
#> 5  (-0.214,0.0465]    500       513      0.1      0.1026 6.673614e-05
#> 6   (0.0465,0.304]    500       509      0.1      0.1018 3.211185e-05
#> 7    (0.304,0.551]    500       444      0.1      0.0888 1.330376e-03
#> 8    (0.551,0.871]    500       575      0.1      0.1150 2.096429e-03
#> 9     (0.871,1.32]    500       603      0.1      0.1206 3.858567e-03
#> 10     (1.32, Inf]    500       560      0.1      0.1120 1.359944e-03
```
