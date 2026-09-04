# IRB risk weight of one or many exposures

The asymptotic single risk factor function, vectorised over exposures:
PD floors by asset class, LGD input floors for own estimates
(`approach = "airb"`; the unsecured column of `params$lgd_floor` unless
`collateral` names another column, blended with `secured_share`), the
asset correlation of the class (with the firm-size adjustment of
`corporate_sme` from `sales` and the multiplier for large or unregulated
financial institutions when `fi` is `TRUE`), the maturity adjustment for
wholesale classes only (`m` clipped to `params$m_range`,
`params$m_default` when missing or under the foundation approach) and

## Usage

``` r
scr_irb_rw(
  pd,
  lgd,
  ead = 1,
  m = NULL,
  asset_class,
  sales = NULL,
  fi = FALSE,
  defaulted = NULL,
  elbe = NULL,
  params = scr_irb_params("bcb"),
  approach = c("airb", "firb"),
  apply_floors = TRUE,
  collateral = NULL,
  secured_share = NULL
)
```

## Arguments

- pd, lgd, ead:

  Numeric vectors: probability of default, loss given default (decimals)
  and exposure at default (currency).

- m:

  Effective maturity in years (wholesale classes only; `NULL` or `NA`
  uses `params$m_default`).

- asset_class:

  One of `"corporate"`, `"corporate_sme"`, `"bank"`, `"sovereign"`,
  `"hvcre"`, `"retail_mortgage"`, `"qrre_revolver"`,
  `"qrre_transactor"`, `"retail_other"`; a scalar or a vector.

- sales:

  Annual sales of `corporate_sme` obligors, in the unit of
  `params$correlation$sme` (missing values take the lower bound, the
  largest adjustment).

- fi:

  Logical: regulated financial institution above the size threshold, or
  unregulated one (correlation multiplier).

- defaulted:

  Optional 0/1 or logical vector.

- elbe:

  Optional vector with the best estimate of expected loss of the
  defaulted rows (decimal of `ead`); ignored on performing rows.

- params:

  An
  [`scr_irb_params()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_params.md)
  object.

- approach:

  `"airb"` (own LGD, floored) or `"firb"` (supervisory LGD supplied by
  the caller, no LGD floor, maturity fixed).

- apply_floors:

  `TRUE` (all input floors), `FALSE` (none) or a subset of
  `c("pd", "lgd", "m")`.

- collateral:

  Optional column of `params$lgd_floor` naming the collateral type of
  each exposure (`"financial"`, `"receivables"`, `"real_estate"`,
  `"other_physical"`); `NULL` means unsecured.

- secured_share:

  Optional secured share in `[0, 1]` blending the unsecured and the
  collateral floors.

## Value

A `data.table` with one row per exposure: `pd_used`, `lgd_used` (after
floors; PD one on defaulted rows), `m` (after clipping), `r`, `b`, `ma`,
`k`, `rw`, `rwa`; attribute `floors_hit` counts the rows where each
floor was binding.

## Details

\$\$K = \left\[LGD \cdot N\left(\frac{G(PD) +
\sqrt{R}\\G(0.999)}{\sqrt{1-R}}\right) - PD \cdot LGD\right\] \cdot MA
\cdot s\$\$

with `s = params$scaling_factor`. Defaulted rows carry
`K = max(0, LGD - ELBE)` under `"airb"` and zero under `"firb"`; a
missing `elbe` is taken equal to `lgd`. `RW = 12.5 K` and
`RWA = RW * ead`.

## References

Basel Committee on Banking Supervision (2023). *The Basel Framework*,
CRE31 (IRB approach: risk-weight functions) and CRE32 (risk components).
BCBS (2005). *An explanatory note on the Basel II IRB risk weight
functions*.

## See also

Other irb-capital:
[`scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_capital.md),
[`scr_ecl()`](https://evandeilton.github.io/scorecraft/reference/scr_ecl.md),
[`scr_el()`](https://evandeilton.github.io/scorecraft/reference/scr_el.md),
[`scr_pd_stress()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_stress.md),
[`scr_sa_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_sa_rw.md)

## Examples

``` r
scr_irb_rw(0.01, 0.45, m = 2.5, asset_class = "corporate")
#>    pd_used lgd_used     m         r         b      ma          k       rw
#>      <num>    <num> <num>     <num>     <num>   <num>      <num>    <num>
#> 1:    0.01     0.45   2.5 0.1927837 0.1374861 1.25981 0.07385344 0.923168
#>         rwa
#>       <num>
#> 1: 0.923168
scr_irb_rw(c(0.01, 0.02), c(0.20, 0.80), asset_class = c("retail_mortgage", "qrre_revolver"))
#>    pd_used lgd_used     m     r     b    ma          k        rw       rwa
#>      <num>    <num> <num> <num> <num> <num>      <num>     <num>     <num>
#> 1:    0.01      0.2    NA  0.15    NA     1 0.02005295 0.2506619 0.2506619
#> 2:    0.02      0.8    NA  0.04    NA     1 0.04113480 0.5141850 0.5141850
r <- scr_irb_rw(1e-4, 0.5, asset_class = "retail_other")
attr(r, "floors_hit")
#>        floor     n
#>       <char> <int>
#> 1:  pd_floor     1
#> 2: lgd_floor     0
#> 3:   m_floor     0
#> 4:     m_cap     0
```
