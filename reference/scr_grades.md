# Rating grades on the score

Cuts the production score into grades whose PD is monotone. The grade
boundaries are score cut points, direction-aware: grade 1 is the safest
(the highest scores under `higher_is_safer`). Three constructions:
`"geometric"` builds a
[`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md)
between the 1st and 99th percentiles of the calibrated PD and converts
its PD bounds into scores through the calibrated alignment; `"quantile"`
cuts equal-count score bands (cut points moved half-way between
neighbouring scores, so a boundary never sits on an observed value);
`"supplied"` grades by the PD bands of a given master scale.

## Usage

``` r
scr_grades(
  x,
  calibration = NULL,
  master_scale = NULL,
  n_grades = NULL,
  method = NULL,
  min_obligors = NULL,
  min_defaults = NULL,
  monotone = TRUE,
  pd_source = NULL,
  sample = "holdout",
  dr = NULL
)
```

## Arguments

- x:

  An
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

- calibration:

  An
  [`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md)
  object (or its alignment); `NULL` uses the scorecard's own alignment.

- master_scale:

  An
  [`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md)
  for `method = "supplied"` (optional for `"geometric"`).

- n_grades, method, min_obligors, min_defaults, pd_source:

  `NULL` reads `pd_n_grades`, `pd_grade_method`, `pd_min_obligors`,
  `pd_min_defaults` and `pd_source` from the scorecard configuration.

- monotone:

  Repair non-monotone grade PDs by pooling.

- sample:

  Sample of the scorecard used to build the grades.

- dr:

  Optional `scr_dr` with a `grade` column keyed by the final grades (see
  the section above).

## Value

An object of class `scr_grades`: `table` (`grade`, `label`, `score_lo`,
`score_hi`, `pd_lo`, `pd_hi`, `n`, `share`, `defaults`, `dr`, `pd_mean`,
`pd_be`, `merged_from`, and `n_series`, `t_series` when a series is
given), `breaks` (ascending score cut points), `band_grade` (grade of
every score band, ascending), `direction`, `method`, `pd_source`,
`master_scale`, `alignment` (calibrated), `alignment_score` (the
scorecard's), `concentration` (`hhi`, `cv`, `hi`, `k`), `repairs`,
`ledger`, `moc` (empty, filled by
[`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md)),
`dr` (the pooled series), `rows` (score, outcome and grade of the
sample), `scorecard`, `sample`, `ct`, `sample_rate`.

## Details

Grades below `min_obligors` obligors or `min_defaults` defaults are
merged with the neighbour of closer default rate; the sequence of grade
PDs is then repaired by pool-adjacent-violators when `monotone = TRUE`,
and every merge is recorded in `repairs`. The grade PD (`pd_be`) is the
long-run average of the grade default rates when a default-rate series
by grade is given in `dr` (`pd_source = "lra"`), the sample default rate
of the grade otherwise, or the mean of the calibrated individual PDs
(`pd_source = "mean_pd"`). Concentration is reported as the Herfindahl
index, the coefficient of variation of the grade shares and the
Herfindahl-based `hi` index.

## Two-pass workflow with a default-rate series

The series must be keyed by the final grades of this same call. Run
`scr_grades()` once, grade the cohort panel with
[`predict.scr_grades()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_grades.md),
build the series with
[`scr_default_rate()`](https://evandeilton.github.io/scorecraft/reference/scr_default_rate.md)
(`grade =`) and pass it as `dr` in a second call with identical
arguments (or in
[`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md)
and
[`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md),
which read it the same way).

## See also

Other irb-pd:
[`predict.scr_grades()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_grades.md),
[`predict.scr_pd()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_pd.md),
[`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md),
[`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md),
[`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md),
[`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md),
[`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md),
[`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md),
[`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 40, n_boot = 10)
res <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                  date_col = "ref_date")
sc <- scr_scorecard(res)
cal <- scr_calibrate(sc, target = 0.06)
gr <- scr_grades(sc, cal, n_grades = 7, min_defaults = 10)
gr
#> <scr_grades> target "default" | 5 grades (geometric) on holdout | PD source: lra | higher_is_safer
#>   concentration: HHI 0.250 | CV 0.500 | HI 0.139 | repairs 2 | calibrated to CT 6.000%
#>   grade label    score_lo  score_hi      n  share   def       dr  pd_mean    pd_be
#>   1     1+2+3      569.06       Inf    369  26.4%    13    3.52%    1.14%    3.52%
#>   2     4          545.99    569.06    410  29.3%    39    9.51%    3.17%    9.51%
#>   3     5          522.00    545.99    390  27.9%    76   19.49%    6.67%   19.49%
#>   4     6          495.73    522.00    174  12.4%    55   31.61%   14.12%   31.61%
#>   5     7            -Inf    495.73     57   4.1%    20   35.09%   28.40%   35.09%
#>   repair (min_counts): 1 -> 2 | n 46, defaults 2 (minimum 30 / 10)
#>   repair (min_counts): 1+2 -> 3 | n 148, defaults 4 (minimum 30 / 10)
gr$table[, c("grade", "score_lo", "score_hi", "n", "dr", "pd_be")]
#>    grade score_lo score_hi     n         dr      pd_be
#>    <int>    <num>    <num> <int>      <num>      <num>
#> 1:     1 569.0615      Inf   369 0.03523035 0.03523035
#> 2:     2 545.9895 569.0615   410 0.09512195 0.09512195
#> 3:     3 522.0009 545.9895   390 0.19487179 0.19487179
#> 4:     4 495.7314 522.0009   174 0.31609195 0.31609195
#> 5:     5     -Inf 495.7314    57 0.35087719 0.35087719
# grade a cohort panel with the score cut points
head(predict(gr, score = scr_demo_panel$score))
#> [1] 1 1 1 1 1 1
```
