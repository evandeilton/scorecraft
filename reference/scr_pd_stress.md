# Stressed PD of the one-factor model

The conditional PD at confidence `q`:
`N((G(pd) + sqrt(rho) G(q)) / sqrt(1 - rho))`. With `q = 0.999` and the
regulatory correlation it is the PD inside the risk-weight function, so
that the capital requirement of a retail exposure is
`lgd * (scr_pd_stress(pd, r, 0.999) - pd)`. Used by the sensitivity grid
of
[`scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_capital.md)
and by the scenario engine of
[`scr_ecl()`](https://evandeilton.github.io/scorecraft/reference/scr_ecl.md).
Arguments are recycled.

## Usage

``` r
scr_pd_stress(pd, rho, q)
```

## Arguments

- pd:

  Numeric vector of unconditional PDs.

- rho:

  Asset correlation in `[0, 1)`.

- q:

  Confidence level in `(0, 1)`; `0.5` returns the median-year PD.

## Value

A numeric vector of conditional PDs.

## References

Vasicek, O. (2002). The distribution of loan portfolio value. *Risk*,
December, 160-162. Gordy, M. B. (2003). A risk-factor model foundation
for ratings-based bank capital rules. *Journal of Financial
Intermediation*, 12(3), 199-232.

## See also

Other irb-capital:
[`scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_capital.md),
[`scr_ecl()`](https://evandeilton.github.io/scorecraft/reference/scr_ecl.md),
[`scr_el()`](https://evandeilton.github.io/scorecraft/reference/scr_el.md),
[`scr_irb_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_rw.md),
[`scr_sa_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_sa_rw.md)

## Examples

``` r
scr_pd_stress(0.02, rho = 0.15, q = c(0.5, 0.95, 0.99, 0.999))
#> [1] 0.01295348 0.06219237 0.10558734 0.17632894
```
