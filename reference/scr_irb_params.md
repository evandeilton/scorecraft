# IRB parameter tables by framework preset

Returns the numeric tables the IRB functions read: probability of
default (PD) floors, loss given default (LGD) input floors for own
estimates, supervisory LGD values of the foundation approach,
standardised credit conversion factors (CCF), asset-correlation
parameters of the risk-weight function, maturity rules, the output floor
and the standardised risk weights used for the floor comparison. Three
presets ship: `"bcb"` (Brazil, Resolução BCB 303/2023 and 229/2022),
`"basel3_final"` (the consolidated Basel Framework in force from 2023)
and `"crr3"` (the EU text applicable from 2025). The presets differ in a
handful of cells, all visible with
[`print()`](https://rdrr.io/r/base/print.html); users who need another
jurisdiction edit the tables and pass the object to the functions that
take `params`.

## Usage

``` r
scr_irb_params(framework = c("bcb", "basel3_final", "crr3"))
```

## Arguments

- framework:

  `"bcb"`, `"basel3_final"` or `"crr3"`.

## Value

An object of class `scr_irb_params`: a list with `framework`, `source`
(one line), `pd_floor`, `lgd_floor`, `lgd_firb`, `ccf_sa`,
`ccf_floor_fraction`, `correlation`, `scaling_factor`, `confidence`,
`m_default`, `m_range`, `output_floor` and `sa_rw`.

## See also

Other irb-parameters:
[`scr_default()`](https://evandeilton.github.io/scorecraft/reference/scr_default.md),
[`scr_default_rate()`](https://evandeilton.github.io/scorecraft/reference/scr_default_rate.md)

## Examples

``` r
p <- scr_irb_params("bcb")
p
#> <scr_irb_params> framework: bcb
#>   Resolucao BCB 303/2023 (IRB) and 229/2022 (standardised); values as tables, editable
#>   PD floors:   corporate 0.05% | bank 0.05% | sovereign none | retail_mortgage 0.05% | qrre_transactor 0.05% | qrre_revolver 0.10% | retail_other 0.05% 
#>   LGD floors (unsecured):  corporate 25% | retail_mortgage n/a | qrre 50% | retail_other 30% 
#>   F-IRB LGD: senior_unsecured 75% | priority_claim 45% | subordinated 75% | secured_financial 0% | secured_receivables 20% | secured_real_estate 20% | secured_other 25%
#>   CCF (standardised): uncond_cancellable 10% | commitment 40% | nif_ruf 50% | direct_substitute 100% | own-estimate floor 50% of the standardised value
#>   correlation: corporate 0.12-0.24 (k=50) | mortgage 0.15 | QRRE 0.04 | other retail 0.03-0.16 (k=35) | FI x1.25 | SME adj 0.04 (BRL m 15-300)
#>   confidence 0.999 | scaling factor 1 | M default 2.5 in [1, 5] | output floor 72.5% | SA risk weights: 26 rows
p$pd_floor
#>        asset_class floor
#>             <char> <num>
#> 1:       corporate 5e-04
#> 2:            bank 5e-04
#> 3:       sovereign    NA
#> 4: retail_mortgage 5e-04
#> 5: qrre_transactor 5e-04
#> 6:   qrre_revolver 1e-03
#> 7:    retail_other 5e-04
p2 <- p; p2$pd_floor$floor[p2$pd_floor$asset_class == "retail_other"] <- 0.001
```
