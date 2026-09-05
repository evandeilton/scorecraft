# Expected loss, risk-weighted assets and capital of a portfolio

Runs
[`scr_irb_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_rw.md)
on every exposure, aggregates by segment, compares the IRB result with
the standardised approach for the output floor, reconciles regulatory
expected loss with the provision stock (shortfall deducted from capital;
excess eligible as tier 2 up to 0.6 % of the IRB risk-weighted assets),
measures the impact of each input floor, runs a fixed sensitivity grid
and reports the name concentration of the book. The parameter tables
come from `params`; the object records whether they were edited.

## Usage

``` r
scr_capital(
  x,
  pd = "pd",
  lgd = "lgd",
  ead = "ead",
  segment = NULL,
  asset_class = config$capital_asset_class,
  m = NULL,
  defaulted = NULL,
  elbe = NULL,
  provisions = NULL,
  ltv = NULL,
  rating = NULL,
  sales = NULL,
  fi = NULL,
  transactor = NULL,
  grade = NULL,
  id = NULL,
  claim = NULL,
  granular = TRUE,
  params = scr_irb_params(config$framework),
  config = scr_config(),
  keep_rows = FALSE
)
```

## Arguments

- x:

  A table of exposures (`data.frame` or `data.table`) or the list form
  described above.

- pd, lgd, ead:

  Column names of the probability of default, loss given default and
  exposure at default.

- segment:

  Optional column name of the reporting segment.

- asset_class:

  A column name or a single asset class (see
  [`scr_irb_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_rw.md)).

- m, defaulted, elbe, provisions, ltv, rating, sales, fi, transactor,
  grade, id:

  Optional column names: effective maturity, default flag, best estimate
  of expected loss, provision stock, loan-to-value, external rating,
  annual sales, financial-institution flag, transactor flag, PD grade
  (defines the SQL pools together with `segment`) and exposure
  identifier.

- claim:

  Optional column name: the claim type of each exposure under the
  foundation approach (a row of `params$lgd_firb`); the supervisory LGD
  then replaces `lgd`.

- granular:

  `TRUE`, `FALSE` or a column name: whether the retail exposures belong
  to a granular regulatory retail pool (the standardised comparison uses
  the non-granular weight otherwise).

- params:

  An
  [`scr_irb_params()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_params.md)
  object; defaults to the preset of `config$framework`.

- config:

  An
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md)
  object (`capital_approach`, `capital_target_ratio`,
  `capital_output_floor`, `capital_sensitivity`, `nthread`, `verbose`).

- keep_rows:

  Keep the per-exposure table in the object.

## Value

An object of class `scr_capital`: a list with `exposures` (per-exposure
table, only with `keep_rows = TRUE`), `segments` (the reconciliation
table: `segment`, `n`, `ead`, `pd_mean`, `lgd_mean`, `m`, `r_mean`,
`k_mean`, `rw`, `rwa_irb`, `rwa_sa`, `irb_sa_ratio`, `el`, `provisions`,
`shortfall_excess`), `pools` (one row per segment and grade with the
constants the SQL emits), `totals` (`n`, `ead`, `el`, `rwa_irb`,
`rwa_sa`, `irb_sa_ratio`, `output_floor`, `rwa_floor`, `rwa_reported`,
`floor_binding`, `headroom`, `density`, `target_ratio`, `capital`,
`provisions`, `shortfall`, `excess`, `tier2_addback`, `tier2_cap`,
`hhi`, `n_eff`, `max_share`, `granular`), `floors` (`floor`, `n_hit`,
`ead_hit`, `delta_rwa`), `sensitivity` (`shock`, `rwa`, `delta`,
`delta_pct`), `concentration` (share of EAD and RWA by segment),
`framework`, `approach`, `params`, `config`, `ledger`, `model_card` and,
after
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md),
`files`. `segments` and `totals` also carry `n_defaulted`; `totals` also
`el_rate` and `rwa_irb_no_floors`; `concentration` has `segment`, `n`,
`ead`, `rwa`, `ead_share`, `rwa_share` and `hhi_contribution`; `columns`
records the column names the SQL reads.

## Inputs

`x` is either a table of exposures, the remaining arguments naming its
columns, or a list `list(pd = , lgd = , ead = , data = )` whose elements
are fitted models with an
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
method (the PD, LGD and EAD objects of the IRB modules) and `data` the
table to apply them to. In the list form each model present fills the
corresponding vector from the columns `pd_final`, `lgd_final` and
`ead_predicted` of its
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
output, and the provenance is written to the ledger; elements that are
`NULL` fall back to the named columns of `data`.

`asset_class` is a column name of `x` or a single class applied to every
row. Segment means are weighted by EAD. The sensitivity grid shocks the
PD (x1.10, x1.25, x1.50), the LGD (+5 percentage points), the EAD (+10
%), removes the input floors, scales the correlation (x1.25) and
stresses the PD with the one-factor model at `q = 0.95` and `0.99`
([`scr_pd_stress()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_stress.md),
the stressed PD then re-entering the function so that the correlation
follows it).

## References

Basel Committee on Banking Supervision (2023). *The Basel Framework*,
CRE31, CRE35 (treatment of expected losses and provisions), RBC20
(output floor).

## See also

Other irb-capital:
[`scr_ecl()`](https://evandeilton.github.io/scorecraft/reference/scr_ecl.md),
[`scr_el()`](https://evandeilton.github.io/scorecraft/reference/scr_el.md),
[`scr_irb_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_rw.md),
[`scr_pd_stress()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_stress.md),
[`scr_sa_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_sa_rw.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE)
cap <- scr_capital(scr_demo_portfolio, segment = "segment", asset_class = "asset_class",
                   m = "m", defaulted = "defaulted", elbe = "elbe", provisions = "provision",
                   ltv = "ltv", rating = "rating", sales = "sales", transactor = "transactor",
                   grade = "grade", id = "id", config = cfg)
cap
#> <scr_capital> bcb | airb | 5,000 exposures in 6 segments
#>   EAD 1,940,402,792 | EL 31,028,477 (1.60%) | RWA IRB 1,214,315,257 | density 62.6% | capital (8.0%) 97,145,221
#>   standardised RWA 1,553,528,212 | IRB/SA 0.782 | output floor 72.5%: not binding (headroom 88,007,303)
#>   provisions 43,425,571 vs EL: shortfall 0 | excess 12,397,094 | tier 2 add-back 7,285,892 (cap 7,285,892)
#>   floors: pd 194 rows, RWA 5,221,058 | lgd 0 rows, RWA         0 | m 0 rows, RWA         0 | HHI 0.00231 (n_eff 433, max share 1.19%)
#>   top segments by RWA:
#>     corporate_large        n 500     EAD 1,451,911,238  RW  65.1%  RWA 944,938,904     IRB/SA 0.77
#>     corporate_sme          n 700     EAD 302,516,540    RW  79.2%  RWA 239,492,431     IRB/SA 0.92
#>     mortgages              n 1,000   EAD 165,305,905    RW  12.6%  RWA 20,764,980      IRB/SA 0.37
#>     retail_loans           n 1,500   EAD 15,592,011     RW  44.5%  RWA 6,935,236       IRB/SA 0.59
#>     cards_revolver         n 800     EAD 3,282,347      RW  54.2%  RWA 1,777,936       IRB/SA 0.71
#>   sensitivity: vasicek_q0.99 +95.8% | vasicek_q0.95 +55.7% | r_x1.25 +26.8%
cap$segments[, c("segment", "n", "rw", "irb_sa_ratio")]
#>             segment     n        rw irb_sa_ratio
#>              <char> <int>     <num>        <num>
#> 1:  corporate_large   500 0.6508242    0.7729808
#> 2:    corporate_sme   700 0.7916672    0.9233544
#> 3:        mortgages  1000 0.1256155    0.3672066
#> 4:     retail_loans  1500 0.4447942    0.5866356
#> 5:   cards_revolver   800 0.5416660    0.7118514
#> 6: cards_transactor   500 0.2260868    0.4907211
cap$floors
#>        floor n_hit   ead_hit delta_rwa
#>       <char> <int>     <num>     <num>
#> 1:  pd_floor   194 110745561   5221058
#> 2: lgd_floor     0         0         0
#> 3:   m_floor     0         0         0
```
