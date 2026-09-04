# Expected loss per exposure

The primitive every other function of the module uses: `pd * lgd * ead`
for performing exposures and `elbe * ead` for defaulted ones, `elbe`
being the best estimate of expected loss. A defaulted exposure without
`elbe` uses `lgd` (PD equal to one). Arguments are recycled to a common
length.

## Usage

``` r
scr_el(pd, lgd, ead, defaulted = NULL, elbe = NULL)
```

## Arguments

- pd, lgd, ead:

  Numeric vectors: probability of default, loss given default (decimals)
  and exposure at default (currency).

- defaulted:

  Optional 0/1 or logical vector.

- elbe:

  Optional vector with the best estimate of expected loss of the
  defaulted rows (decimal of `ead`); ignored on performing rows.

## Value

A numeric vector with the expected loss in currency.

## See also

Other irb-capital:
[`scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_capital.md),
[`scr_ecl()`](https://evandeilton.github.io/scorecraft/reference/scr_ecl.md),
[`scr_irb_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_rw.md),
[`scr_pd_stress()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_stress.md),
[`scr_sa_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_sa_rw.md)

## Examples

``` r
scr_el(c(0.01, 0.02), 0.45, c(1000, 2000))
#> [1]  4.5 18.0
scr_el(0.02, 0.45, 1000, defaulted = TRUE, elbe = 0.6)
#> [1] 600
```
