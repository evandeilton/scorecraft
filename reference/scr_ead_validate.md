# Validate CCF pools: calibration, discrimination, back-testing and stability

Per pool and in total, compares realised and predicted values on the
validation rows (the hold-out of the model by default): simple and
exposure-weighted averages, the one-sided t-test of realised above
predicted (under-estimation) with its p-value, the EAD adequacy ratio
(sum of realised EAD over sum of predicted EAD) and traffic lights
(green when p \> 0.05, amber when 0.01 \< p \<= 0.05, red when p \<=
0.01; adequacy green at or below 1, amber up to 1.05, red above). Adds
the discrimination block (gAUC with a bootstrap interval against the
development value, Spearman correlation, cumulative EAD accuracy ratio),
the back-test by cohort and the stability of the pool distribution and
of the driver bins
([`scr_psi()`](https://evandeilton.github.io/scorecraft/reference/scr_psi.md),
fixed and sample-size-adjusted thresholds). The numeric limits of the
lights are a convention of the package, stated as such in the output.

## Usage

``` r
scr_ead_validate(
  x,
  newdata = NULL,
  lights = c(0.01, 0.05),
  adequacy_lights = c(1, 1.05)
)
```

## Arguments

- x:

  An
  [`scr_ead()`](https://evandeilton.github.io/scorecraft/reference/scr_ead.md)
  object.

- newdata:

  `NULL` (the hold-out rows of `x`), an
  [`scr_ead_data()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_data.md)
  object or its `rds` table.

- lights:

  Two increasing p-value thresholds: red at or below the first, amber at
  or below the second.

- adequacy_lights:

  Two increasing adequacy-ratio thresholds.

## Value

An object of class `scr_ead_validation`: `calibration`,
`discrimination`, `backtest`, `stability`, `summary` (test, statistic,
p, light), `n`, `source`.

## See also

Other irb-ead:
[`scr_bin_continuous()`](https://evandeilton.github.io/scorecraft/reference/scr_bin_continuous.md),
[`scr_ead()`](https://evandeilton.github.io/scorecraft/reference/scr_ead.md),
[`scr_ead_data()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_data.md),
[`scr_ead_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_downturn.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, n_boot = 20, nthread = 1)
ed <- scr_ead_data(scr_demo_ead, facility_id = "facility_id", date_col = "ref_date",
                   limit = "limit", drawn = "drawn", defaulted = "defaulted",
                   drivers = c("product", "months_on_book"), config = cfg)
m <- scr_ead(ed, drivers = c("utilisation_ref", "product"), config = cfg)
v <- scr_ead_validate(m)
v
#> <scr_ead_validation> 42 rows (holdout)
#>   pool        n  realised predicted        t        p  light  adequacy  light
#>   P1         20    0.4073    0.4377   -0.243   0.5947 green     0.9725 green 
#>   P2         21    0.5698    0.6245   -0.800   0.7835 green     0.9747 green 
#>   LF          1    1.0400    0.9962        -        - NA        1.0000 green 
#>   TOTAL      42    0.4905    0.5334   -0.606   0.7261 green     0.9733 green 
#>   gAUC 0.6248 [0.5159, 0.6777] vs development 0.5953 (p 0.6899) | Spearman 0.4169 | CEAR -0.2516
#>   stability: pool PSI 0.0625 (stable) | product PSI 0.0005 (stable)
#>   lights: calibration_t_total green | ead_adequacy_total green | gauc_vs_development green | pool_psi green
v$calibration
#> Index: <pool>
#>      pool     n n_main  realised predicted realised_ew predicted_ew         se
#>    <char> <int>  <int>     <num>     <num>       <num>        <num>      <num>
#> 1:     P1    20     20 0.4072615 0.4377121   0.4170193    0.4377121 0.12537121
#> 2:     P2    21     21 0.5698213 0.6245361   0.5969057    0.6245361 0.06838965
#> 3:     LF     1      1 1.0400000 0.9962084   1.0400000    1.0400000         NA
#> 4:  TOTAL    42     41 0.4905238 0.5334025   0.4660587    0.4886428 0.07074482
#>             t         p light_p ead_realised ead_predicted  adequacy
#>         <num>     <num>  <char>        <num>         <num>     <num>
#> 1: -0.2428832 0.5946507   green       119370     122740.82 0.9725371
#> 2: -0.8000456 0.7834575   green        59740      61291.56 0.9746855
#> 3:         NA        NA    <NA>          520        520.00 1.0000000
#> 4: -0.6061024 0.7260644   green       179630     184552.38 0.9733280
#>    light_adequacy
#>            <char>
#> 1:          green
#> 2:          green
#> 3:          green
#> 4:          green
```
