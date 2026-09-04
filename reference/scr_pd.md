# The PD model: grades, margin of conservatism and the floor

Assembles the final grade table: `pd_be` from
[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md),
the active entries of the MoC ledger by category (`A` and `B` summed
over their entries, the latest `C`), `pd_moc = pd_be + A + B + C`, the
PD floor of the asset class under the framework of `params`, and
`pd_final = max(pd_moc, floor)`. With `philosophy = "pit"` the
through-the-cycle `pd_moc` is converted with the one-factor bridge of
[`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md)
before the floor (`rho` and `z` required).

## Usage

``` r
scr_pd(
  grades,
  moc = NULL,
  params = NULL,
  asset_class = NULL,
  philosophy = c("ttc", "pit"),
  rho = NULL,
  z = NULL
)
```

## Arguments

- grades:

  An
  [`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md)
  object, after
  [`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md).

- moc:

  `NULL` uses `grades$moc`; otherwise a ledger in the same format.

- params:

  An
  [`scr_irb_params()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_params.md);
  `NULL` uses `config$framework`.

- asset_class:

  Asset class of the floor; `NULL` uses `config$pd_asset_class`.

- philosophy:

  `"ttc"` (default) or `"pit"`.

- rho, z:

  Asset correlation and systematic factor for `"pit"`.

## Value

An object of class `scr_pd`: `table` (`grade`, `label`, `score_lo`,
`score_hi`, `n`, `share`, `defaults`, `dr`, `pd_be`, `moc_a`, `moc_b`,
`moc_c`, `pd_moc`, `pd_ttc`, `pd_pit`, `floor`, `pd_final`,
`floor_applied`), `breaks`, `band_grade`, `direction`, `alignment`,
`alignment_score`, `master_scale`, `asset_class`, `framework`, `floor`,
`philosophy`, `rho`, `z`, `moc_ledger`, `calibration`, `concentration`,
`portfolio` (weighted `pd_be`, `pd_moc`, `pd_final`, `moc_bp`,
`share_at_floor`), `scorecard`, `ledger`, `model_card`.

## See also

Other irb-pd:
[`predict.scr_grades()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_grades.md),
[`predict.scr_pd()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_pd.md),
[`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md),
[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md),
[`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md),
[`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md),
[`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md),
[`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md),
[`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 40, n_boot = 10)
res <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                  date_col = "ref_date")
sc <- scr_scorecard(res)
gr <- scr_moc(scr_grades(sc, n_grades = 6, min_defaults = 10), "C", method = "ci_binomial")
pd <- scr_pd(gr)
pd
#> <scr_pd> target "default" | bcb | retail_other | floor 0.05% | 4 grades | ttc
#>   calibration: scorecard alignment | grades: geometric, PD source lra | HHI 0.303
#>   grade  score_lo  score_hi      n    pd_be   moc_a   moc_b   moc_c   pd_moc pd_final floor
#>   1        562.85       Inf    473    3.38%     0.0     0.0   136.7    4.75%    4.75%      
#>   2        535.61    562.85    500   12.80%     0.0     0.0   245.8   15.26%   15.26%      
#>   3        503.12    535.61    335   26.57%     0.0     0.0   396.9   30.54%   30.54%      
#>   4          -Inf    503.12     92   36.96%     0.0     0.0   827.7   45.23%   45.23%      
#>   portfolio: PD_BE 14.500% | MoC 283.3 bp (A/B/C in bp) | PD_final 17.333% | 0.0% of obligors at the floor
pd$table[, c("grade", "pd_be", "moc_c", "pd_final", "floor_applied")]
#>    grade      pd_be      moc_c   pd_final floor_applied
#>    <int>      <num>      <num>      <num>        <lgcl>
#> 1:     1 0.03382664 0.01367268 0.04749932         FALSE
#> 2:     2 0.12800000 0.02457568 0.15257568         FALSE
#> 3:     3 0.26567164 0.03969379 0.30536544         FALSE
#> 4:     4 0.36956522 0.08277496 0.45234018         FALSE
head(predict(pd, score = c(480, 560, 640), type = "pd_final"))
#> [1] 0.45234018 0.15257568 0.04749932
head(scr_apply(pd, head(scr_demo, 5)))
#>       score score_points grade         pd     pd_be  pd_final
#>       <num>        <num> <int>      <num>     <num>     <num>
#> 1: 546.5330          546     2 0.11314626 0.1280000 0.1525757
#> 2: 562.3290          562     2 0.06872463 0.1280000 0.1525757
#> 3: 560.5217          559     2 0.07284358 0.1280000 0.1525757
#> 4: 507.0636          507     3 0.33378976 0.2656716 0.3053654
#> 5: 536.7619          536     2 0.15182491 0.1280000 0.1525757
cat(tail(scr_sql(pd), 8), sep = "\n")
#> )
#> 
#> -- Block 4: rating grade and final PD from the score cut points (4 grades, higher_is_safer)
#> SELECT
#>     s.*,
#>     CASE WHEN score <= 503.11688107909112 THEN 4 WHEN score <= 535.6113744573629 THEN 3 WHEN score <= 562.8474695224495 THEN 2 ELSE 1 END AS grade,
#>     CASE WHEN score <= 503.11688107909112 THEN 0.45234017577521279 WHEN score <= 535.6113744573629 THEN 0.3053654350250784 WHEN score <= 562.8474695224495 THEN 0.15257567651855442 ELSE 0.04749931808441589 END AS pd_final
#> FROM score_scr s;
```
