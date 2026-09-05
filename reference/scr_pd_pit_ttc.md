# One-factor bridge between point-in-time and through-the-cycle PD

Vasicek's conditional default probability: \$\$PD\_{PIT} =
\Phi\left(\frac{\Phi^{-1}(PD\_{TTC}) - \sqrt{\rho}\\
z}{\sqrt{1-\rho}}\right),\$\$ and its inverse for `to = "ttc"`. A
positive `z` is a benign state (lower PIT PD), a negative one a stressed
state.

## Usage

``` r
scr_pd_pit_ttc(pd, z, rho, to = c("pit", "ttc"))
```

## Arguments

- pd:

  Numeric PDs in `(0, 1)`.

- z:

  Systematic factor (standard normal scale).

- rho:

  Asset correlation in `(0, 1)`.

- to:

  `"pit"` (input is TTC) or `"ttc"` (input is PIT).

## Value

A numeric vector of the length of `pd`.

## References

Vasicek, O. (2002). The distribution of loan portfolio value. *Risk*,
15(12), 160-162.

## See also

[`scr_pd_stress()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_stress.md),
the same bridge with the systematic factor given as a quantile `q`
rather than a value of `z`.

Other irb-pd:
[`predict.scr_grades()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_grades.md),
[`predict.scr_pd()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_pd.md),
[`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md),
[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md),
[`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md),
[`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md),
[`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md),
[`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md),
[`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md)

## Examples

``` r
scr_pd_pit_ttc(c(0.01, 0.05), z = -2, rho = 0.15)
#> [1] 0.04617685 0.17260368
scr_pd_pit_ttc(scr_pd_pit_ttc(0.02, z = -1, rho = 0.1), z = -1, rho = 0.1, to = "ttc")
#> [1] 0.02
```
