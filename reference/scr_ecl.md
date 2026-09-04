# Expected credit loss with stage allocation

Discrete-time expected credit loss of every exposure:

## Usage

``` r
scr_ecl(
  pd_term,
  lgd,
  ead,
  eir = 0,
  stage = NULL,
  dpd = NULL,
  pd_orig = NULL,
  scenarios = NULL,
  weights = NULL,
  prepay = NULL,
  rho = 0.15,
  t_max = NULL,
  segment = NULL,
  id = NULL,
  config = scr_config(),
  keep_rows = FALSE
)
```

## Arguments

- pd_term:

  Marginal monthly PDs: a matrix `n x T`, or a vector of length `n` (a
  flat hazard recycled over `t_max` months), or a single number.

- lgd, ead:

  Vectors of length `n` (or one) or matrices `n x T`.

- eir:

  Annual effective interest rate, vector of length `n` or one.

- stage:

  Optional stage vector (1, 2, 3); `NULL` applies the rule.

- dpd:

  Days past due (the rule); optional.

- pd_orig:

  12-month PD at origination (the rule); optional.

- scenarios:

  Named list of scenario shocks (see Details); `NULL` runs the base case
  only.

- weights:

  Scenario weights; equal when `NULL`.

- prepay:

  Monthly prepayment hazard: `NULL`, a vector or an `n x T` matrix.

- rho:

  Asset correlation used by scenario shocks with `z`.

- t_max:

  Term in months when `pd_term` is a vector (default
  `config$ecl_horizon_months`).

- segment:

  Optional character vector of length `n` for a segment summary.

- id:

  Optional identifier vector of length `n`.

- config:

  An
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md)
  object (`ecl_*` keys, `verbose`).

- keep_rows:

  Keep the per-exposure table.

## Value

An object of class `scr_ecl`: a list with `exposures` (only with
`keep_rows = TRUE`: `id`, `segment`, `stage`, `ead`, `pd_12m`,
`pd_life`, `ecl_12m`, `ecl_life`, `ecl`), `stages` (`stage`, `n`, `ead`,
`ecl_12m`, `ecl_life`, `ecl`, `coverage`), `segments` (when a segment is
given), `scenarios` (`scenario`, `weight`, `ecl_12m`, `ecl_life`,
`ecl`), `totals` (`n`, `ead`, `ecl_12m`, `ecl_life`, `ecl`, `coverage`,
`share_stage2`, `share_stage3`), `horizon`, `t_max`, `discount`,
`stage_rule`, `ledger` and `config`.

## Details

\$\$ECL_H = \sum\_{t=1}^{H} S(t-1)\\ h_t\\ LGD_t\\ EAD_t\\
(1+r)^{-t/12}, \qquad S(t) = \prod\_{s \le t}(1 - h_s - p_s)\$\$

with `h_t` the marginal monthly default hazard, `p_t` an optional
prepayment hazard and `r` the annual effective interest rate
(`config$ecl_discount = "none"` switches the discounting off). The
12-month figure uses `H = config$ecl_horizon_months`, the lifetime
figure the full term `T`. Stage 1 exposures carry the 12-month loss,
stages 2 and 3 the lifetime loss; stage 3 exposures are credit-impaired
and carry `LGD_1 * EAD_1`. When `stage` is `NULL` the rule is: stage 3
if `dpd >= config$ecl_stage_dpd[2]`, stage 2 if
`dpd >= config$ecl_stage_dpd[1]` or the 12-month PD now over the one at
origination (`pd_orig`) is at least `config$ecl_sicr_ratio`, else stage
1.

Scenarios are a named list of shocks applied to the base inputs, each a
list with any of `pd_mult` (multiplier of the hazards, capped at one),
`z` (systematic factor of the one-factor model applied to the hazards
with correlation `rho`, negative in a bad year), `lgd_add` (added to the
LGD) and `ead_mult`; `weights` (normalised to one) give the
probability-weighted result.

## References

International Accounting Standards Board (2014). *IFRS 9 Financial
Instruments*, section 5.5 and paragraphs B5.5.1-B5.5.55.

## See also

Other irb-capital:
[`scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_capital.md),
[`scr_el()`](https://evandeilton.github.io/scorecraft/reference/scr_el.md),
[`scr_irb_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_rw.md),
[`scr_pd_stress()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_stress.md),
[`scr_sa_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_sa_rw.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE)
d <- scr_demo_portfolio
h <- 1 - (1 - d$pd)^(1 / 12)       # flat monthly hazard from the annual PD
e <- scr_ecl(h, d$lgd, d$ead, eir = d$eir, dpd = d$dpd, pd_orig = d$pd_orig,
             t_max = 36L, segment = d$segment, config = cfg)
e
#> <scr_ecl> 5,000 exposures | ECL 30,230,826 | coverage 1.56% | 12-month horizon 12 of 36 months | discount: eir
#>   stage rule: dpd >= 90 -> stage 3; dpd >= 30 or PD ratio >= 2 -> stage 2
#>   stage 1  n 4,304   EAD 1,687,138,403  ECL 7,270,606    coverage 0.43%
#>   stage 2  n 542     EAD 201,418,836    ECL 2,271,246    coverage 1.13%
#>   stage 3  n 154     EAD 51,845,553     ECL 20,688,974   coverage 39.91%
#>   12-month 28,846,459 | lifetime 41,112,620 | scenarios: base 1.00
e$stages
#> Key: <stage>
#>    stage     n        ead    ecl_12m ecl_life      ecl   coverage
#>    <int> <int>      <num>      <num>    <num>    <num>      <num>
#> 1:     1  4304 1687138403  7270605.6 18152400  7270606 0.00430943
#> 2:     2   542  201418836   886879.2  2271246  2271246 0.01127623
#> 3:     3   154   51845553 20688974.1 20688974 20688974 0.39905012
```
