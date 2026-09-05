# Standardised risk weight of an exposure

Lookup in `params$sa_rw`: regulatory retail (`"retail_other"`,
`"qrre_*"`: 75 %, or the transactor weight), residential mortgages by
loan-to-value band (a missing LTV takes the highest band), corporates by
external rating bucket (`"AAA"` to `"AA-"`, `"A"`, `"BBB"`, `"BB"`,
below; `NA` is unrated; `"IG"` marks an unrated investment-grade obligor
where ratings are not used) or the SME weight, banks and sovereigns
through the corporate rating rows, and defaulted exposures by the
specific provision ratio (or the mortgage row). Arguments are recycled.

## Usage

``` r
scr_sa_rw(
  asset_class,
  ltv = NULL,
  rating = NULL,
  transactor = NULL,
  defaulted = NULL,
  provision_ratio = NULL,
  sme = NULL,
  granular = TRUE,
  params = scr_irb_params("bcb")
)
```

## Arguments

- asset_class:

  One of `"corporate"`, `"corporate_sme"`, `"bank"`, `"sovereign"`,
  `"hvcre"`, `"retail_mortgage"`, `"qrre_revolver"`,
  `"qrre_transactor"`, `"retail_other"`; a scalar or a vector.

- ltv:

  Loan-to-value at origination, decimal (mortgages).

- rating:

  External rating string (corporates), `NA` when unrated.

- transactor:

  Logical: revolving facility repaid in full every month.

- defaulted:

  Optional 0/1 or logical vector.

- provision_ratio:

  Specific provisions over the outstanding amount (defaulted rows).

- sme:

  Logical: corporate small or medium enterprise (also implied by
  `asset_class = "corporate_sme"`).

- granular:

  Logical (scalar or per exposure): whether the retail exposure belongs
  to a granular regulatory retail pool; `FALSE` applies the non-granular
  retail weight.

- params:

  An
  [`scr_irb_params()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_params.md)
  object.

## Value

A numeric vector of standardised risk weights (decimals).

## References

Basel Committee on Banking Supervision (2023). *The Basel Framework*,
CRE20 (standardised approach: individual exposures).

## See also

Other irb-capital:
[`scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_capital.md),
[`scr_ecl()`](https://evandeilton.github.io/scorecraft/reference/scr_ecl.md),
[`scr_el()`](https://evandeilton.github.io/scorecraft/reference/scr_el.md),
[`scr_irb_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_rw.md),
[`scr_pd_stress()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_stress.md)

## Examples

``` r
scr_sa_rw(c("retail_other", "retail_mortgage", "corporate"), ltv = c(NA, 0.55, NA),
          rating = c(NA, NA, "A+"))
#> [1] 0.75 0.25 0.50
scr_sa_rw("retail_other", defaulted = TRUE, provision_ratio = c(0.1, 0.3))
#> [1] 1.5 1.0
```
