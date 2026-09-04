# Master scale of PD grades

A grade structure with geometric midpoints and geometric-mean
boundaries: \$\$PD_k = PD_1 \\ r^{k-1},\quad r = (PD_K /
PD_1)^{1/(K-1)},\quad \mathrm{bound}\_k = \sqrt{PD_k \\ PD\_{k+1}},\$\$
so that every grade doubles (or multiplies by `r`) the PD of the one
before. With `method = "supplied"` the table comes from the user: a
numeric vector of midpoints (boundaries derived as the geometric means)
or a `data.frame` with `pd_lo` and `pd_hi` (and optionally `pd_mid`,
`label`). Grade 1 is always the safest.

## Usage

``` r
scr_master_scale(
  pd_min = 3e-04,
  pd_max = 0.3,
  n_grades = 10L,
  method = c("geometric", "supplied"),
  grades = NULL,
  labels = NULL
)
```

## Arguments

- pd_min, pd_max:

  PD midpoints of the first and the last grade.

- n_grades:

  Number of grades.

- method:

  `"geometric"` (default) or `"supplied"`.

- grades:

  For `"supplied"`: a numeric vector of midpoints or a `data.frame` with
  `pd_lo` and `pd_hi`.

- labels:

  Optional grade labels (default `"1"`, `"2"`, ...).

## Value

A `data.table` of class `scr_master_scale` with `grade`, `label`,
`pd_lo`, `pd_mid`, `pd_hi`, and the attributes `ratio` (the geometric
ratio between consecutive midpoints) and `method`.

## See also

Other irb-pd:
[`predict.scr_grades()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_grades.md),
[`predict.scr_pd()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_pd.md),
[`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md),
[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md),
[`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md),
[`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md),
[`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md),
[`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md),
[`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md)

## Examples

``` r
ms <- scr_master_scale(0.0005, 0.25, n_grades = 8)
ms
#> <scr_master_scale> 8 grades (geometric) | ratio between midpoints 2.430
#>   grade  label         pd_lo     pd_mid      pd_hi
#>   1      1            0.000%     0.050%     0.078%
#>   2      2            0.078%     0.121%     0.189%
#>   3      3            0.189%     0.295%     0.460%
#>   4      4            0.460%     0.717%     1.118%
#>   5      5            1.118%     1.743%     2.717%
#>   6      6            2.717%     4.235%     6.601%
#>   7      7            6.601%    10.289%    16.038%
#>   8      8           16.038%    25.000%   100.000%
scr_master_scale(method = "supplied", grades = c(0.001, 0.01, 0.05, 0.20))
#> <scr_master_scale> 4 grades (supplied) | ratio between midpoints 5.848
#>   grade  label         pd_lo     pd_mid      pd_hi
#>   1      1            0.000%     0.100%     0.316%
#>   2      2            0.316%     1.000%     2.236%
#>   3      3            2.236%     5.000%    10.000%
#>   4      4           10.000%    20.000%   100.000%
```
