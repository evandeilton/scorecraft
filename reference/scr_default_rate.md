# One-year default rates by cohort and the long-run average

From a flagged panel (an
[`scr_default()`](https://evandeilton.github.io/scorecraft/reference/scr_default.md)
object or any table with a 0/1 default column by unit and month),
computes for every cohort start the population of non-defaulted units,
the share that defaults within `horizon` months, optionally by `grade`
or `segment` (as observed at the cohort start) and exposure-weighted
when `exposure` is given. The long-run average is the arithmetic mean of
the cohort rates. When the analyst proposes an adjusted value
(`lra_adjusted`, for instance after judging that the period lacks bad
years), it is benchmarked against the larger of the last five years'
mean and the whole period's mean, and a flag records when it sits below
that benchmark.

## Usage

``` r
scr_default_rate(
  x,
  id = "id",
  date = "date",
  default = "default",
  horizon = 12L,
  by = NULL,
  grade = NULL,
  segment = NULL,
  exposure = NULL,
  lra_adjusted = NULL,
  config = scr_config()
)
```

## Arguments

- x:

  An `scr_default` or a `data.frame`/`data.table`.

- id, date, default:

  Column names (ignored for an `scr_default`).

- horizon:

  Months of the default window after the cohort start.

- by:

  Cohort frequency: `"month"`, `"quarter"` or `"year"`.

- grade, segment:

  Optional column names observed at the cohort start.

- exposure:

  Optional column name; adds exposure-weighted rates.

- lra_adjusted:

  Optional adjusted long-run average proposed by the analyst, in
  `[0, 1]`; benchmarked and flagged, never applied.

- config:

  A
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md);
  only `pd_dr_by` is read (the default of `by`).

## Value

An object of class `scr_dr`: `table` (cohort rates, by grade or segment
when given), `portfolio` (one row per cohort: `n`, `defaults`, `dr`),
`lra` (`mean`, `weighted_mean`, `recent5_mean`, `benchmark`, `adjusted`,
`flag_below_benchmark`, `min`, `max`, `sd`, `n_cohorts`, `years`),
`horizon` and `by`.

## See also

Other irb-parameters:
[`scr_default()`](https://evandeilton.github.io/scorecraft/reference/scr_default.md),
[`scr_irb_params()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_params.md)

## Examples

``` r
d <- scr_default(scr_demo_panel, id = "id", date = "ref_date", dpd = "dpd",
                 config = scr_config(verbose = FALSE))
dr <- scr_default_rate(d, by = "quarter")
dr
#> <scr_dr> 8 quarterly cohorts over 1.7 years | horizon 12 months
#>   default rate: mean 12.32% | weighted 12.30% | min 10.83% | max 14.19% | sd 1.11%
#>   long-run average 12.32% | benchmark 12.32% (max of last-5-years 12.32% and all-years 12.32%)
#>   note: fewer than five years of cohorts; the average is not a long-run one yet
dr$table
#>        cohort     n defaults        dr
#>        <Date> <int>    <int>     <num>
#> 1: 2023-01-01   600       65 0.1083333
#> 2: 2023-04-01   587       64 0.1090290
#> 3: 2023-07-01   569       70 0.1230228
#> 4: 2023-10-01   567       72 0.1269841
#> 5: 2024-01-01   568       75 0.1320423
#> 6: 2024-04-01   571       81 0.1418564
#> 7: 2024-07-01   551       67 0.1215971
#> 8: 2024-10-01   555       68 0.1225225
```
