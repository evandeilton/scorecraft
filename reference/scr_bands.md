# Percentile study of a score

Cuts the score into bands of equal share (or into tail percentiles)
**frozen on the reference sample**, and reads every band on the
reference and on the study samples: volume, event rate with a Jeffreys
interval, lift, capture (recall), the cumulative non-event share (false
positive rate), KS, the band WOE and IV, odds, the PSI term against the
reference and a one-sided Fisher exact test of rank order against the
previous band. The summary adds the AUC, Gini and KS of every sample
with a bootstrap interval.

## Usage

``` r
scr_bands(x, ...)

# S3 method for class 'scr_scorecard'
scr_bands(
  x,
  n_bands = NULL,
  spacing = c("uniform", "tail"),
  tail_probs = NULL,
  sample = "holdout",
  reference = "train",
  breaks = NULL,
  level = NULL,
  n_boot = NULL,
  seed = NULL,
  max_cells = 1e+05,
  boot_cells = 10000,
  ...
)

# S3 method for class 'data.frame'
scr_bands(
  x,
  score = "score",
  y = "y",
  objective = "risk",
  direction = NULL,
  weight = NULL,
  value = NULL,
  sample = NULL,
  reference = NULL,
  study = NULL,
  counts = FALSE,
  n = "n",
  events = "events",
  n_bands = 20L,
  spacing = c("uniform", "tail"),
  tail_probs = NULL,
  breaks = NULL,
  level = 0.95,
  n_boot = 200L,
  seed = NULL,
  max_cells = 1e+05,
  value_events = NULL,
  boot_cells = 10000,
  ...
)
```

## Arguments

- x:

  An object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
  or a `data.frame` with one row per scored case (or one row per score
  value with `counts = TRUE`).

- ...:

  Passed on to the methods; an unknown argument is an error.

- n_bands:

  Number of equal-share bands. For a scorecard, `NULL` uses
  `config$study_bands` (20).

- spacing:

  `"uniform"` (equal shares) or `"tail"` (the shares of `tail_probs`,
  counted from the event-rich side).

- tail_probs:

  Cumulative shares from the event-rich side for `spacing = "tail"`.
  `NULL` uses 0.001, 0.005, 0.01, 0.02, 0.05, 0.10, 0.20 and 0.50.

- sample:

  For a scorecard: the study sample(s), `"holdout"` (default) and/or
  `"train"`. For a data.frame: the name of a column with sample labels,
  or `NULL` (all rows are one sample, reference and study at once).

- reference:

  For a scorecard: the sample the bands are frozen on (`"train"`). For a
  data.frame: the label of the reference sample; `NULL` takes the first
  level of the `sample` column (the levels of a factor in their order,
  numbers in numeric order, text sorted).

- breaks:

  Explicit ascending cut points; overrides `n_bands` and `spacing`.
  Infinite values are ignored.

- level:

  Confidence level of the intervals. For a scorecard, `NULL` uses
  `config$study_level` (0.95).

- n_boot:

  Bootstrap resamples of the AUC interval (`0` skips it). For a
  scorecard, `NULL` uses `config$n_boot`.

- seed:

  Seed of the bootstrap. A number is local to the call (the user's
  random stream is restored on exit); `NULL` draws from the user's
  stream and advances it. For a scorecard, `NULL` uses `config$seed`.

- max_cells:

  Largest number of distinct score values kept exactly.

- boot_cells:

  Largest number of score cells resampled exactly by the bootstrap
  (default 10,000; `Inf` for no pooling). See the section Method.

- score, y:

  Column names of the score and of the 0/1 outcome (`NA` allowed).

- objective:

  `"risk"` (the event is the bad case) or `"propensity"` (the event is
  the good case).

- direction:

  `"higher_is_safer"` or `"higher_is_riskier"`; `NULL` derives it from
  `objective`.

- weight:

  Optional column of non-negative case weights.

- value:

  Optional column of a value per case (an amount, a balance): adds the
  value captured per band. With `counts = TRUE`, the value per score
  cell.

- study:

  Labels of the study samples; `NULL` takes every level other than the
  reference.

- counts:

  `TRUE` when `x` is pre-aggregated: one row per score value with the
  columns `score`, `n` and `events` (and, optionally, `value` and
  `value_events`).

- n, events:

  Column names of the counts when `counts = TRUE`.

- value_events:

  With `counts = TRUE`: the column of the value of the events per score
  cell.

## Value

An object of class `c("scr_study_bands", "scr_study", "list")`:

- `table`:

  One row per sample and band, event-richest band first: `sample`,
  `band`, `label`, `score_lo`, `score_hi`, `n`, `pct`, `cum_pct`,
  `events`, `rate`, `rate_lo`, `rate_hi`, `cum_rate`, `lift`, `lift_lo`,
  `lift_hi`, `cum_lift`, `capture`, `cum_nonevent_pct`, `ks`,
  `pct_event`, `pct_nonevent`, `woe`, `iv`, `odds`, `log_odds`, `psi`,
  `p_reversal`, `p_reversal_adj` and, with `value`, `value`,
  `value_events`, `value_capture` (cumulative share of the event value)
  and `value_precision` (cumulative event value over cumulative value).

- `summary`:

  One row per sample: `sample`, `n`, `events`, `rate`, `auc`, `auc_lo`,
  `auc_hi`, `gini`, `gini_lo`, `gini_hi`, `ks`, `iv`, `psi` (against the
  reference), `n_bands_requested`, `n_bands_effective` and `reversals`
  (bands with `p_reversal_adj` below 0.05).

- `cuts`:

  The ascending cut points.

- `codes`, `code_labels`:

  Band number and label of every interval in ascending score order, used
  by
  [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
  and
  [`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md).

- `objective`, `direction`, `level`, `spacing`, `reference`, `samples`,
  `target`, `call`:

  The settings.

- `n_bands_requested`, `n_bands_effective`, `quantized`, `hist`:

  The band counts, whether the scores were pooled, and the count table
  the study was computed from.

## Method

The scored rows are aggregated once into a table of counts per distinct
score (per sample); every statistic is then computed from that table, so
the cost is one pass over the rows plus work proportional to the number
of distinct scores. With more than `max_cells` distinct scores, the
scores are first pooled into `max_cells` cells of equal weighted share.

The cut targets are cumulative shares counted from the event-rich side
of the score (the high scores under `higher_is_riskier`, the low ones
under `higher_is_safer`): `k / n_bands` with `spacing = "uniform"`, or
the shares in `tail_probs` with `spacing = "tail"` (default 0.1%, 0.5%,
1%, 2%, 5%, 10%, 20% and 50%). Each cut is placed midway between two
adjacent distinct reference scores, at the boundary nearest to its
target, so a group of tied scores is never split and a target is hit
within the share of one score value. Targets that land on the same
boundary give one cut: `n_bands_effective` can be smaller than
`n_bands_requested`, and both are reported. A band is left-closed,
`[lo, hi)`: `score >= cut` is the upper side, the convention of
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md).
`breaks` given explicitly are used as they are; the bands of
[`scr_score_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_score_gains.md)
(`breaks = sc$breaks`) are right-closed, so a score equal to a break
falls one band higher here.

The band table lists the event-richest band first (`band = 1`). With
\\e_b\\ events and \\m_b\\ non-events in band \\b\\, totals \\E\\ and
\\M\\, and overall rate \\R\\:

- `rate` = \\e_b / (e_b + m_b)\\, with the Jeffreys interval `rate_lo`,
  `rate_hi`: the Beta(\\e_b + 1/2, m_b + 1/2\\) quantiles, 0 and 1 at
  the edges (Brown, Cai and DasGupta, 2001). Under weights, the counts
  are scaled to the Kish effective size \\(\sum w)^2 / \sum w^2\\.

- `lift` = `rate` / \\R\\ (its interval divides the rate bounds by
  \\R\\); `cum_rate` and `cum_lift` accumulate from the first band.

- `capture` = \\\sum\_{j \le b} e_j / E\\ (recall), `cum_nonevent_pct` =
  \\\sum\_{j \le b} m_j / M\\ (false positive rate) and `ks` their
  absolute difference.

- `pct_event`, `pct_nonevent` and `woe` = \\\ln(e_b / E) - \ln(m_b /
  M)\\ as in
  [`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md)
  (0.5 is added to every band only when a band lacks events or
  non-events); `iv` = (`pct_event` - `pct_nonevent`) \* `woe`.

- `odds` and `log_odds` in the orientation of the scale (non-events per
  event under `higher_is_safer`, events per non-event under
  `higher_is_riskier`, 0.5 added to each count), as in
  [`scr_score_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_score_gains.md).

- `psi`: the band term of the PSI against the reference shares (see
  [`scr_psi()`](https://evandeilton.github.io/scorecraft/reference/scr_psi.md));
  `NA` on the reference itself.

- `p_reversal`: one-sided Fisher exact test that the band has a
  **higher** event rate than the previous, event-richer band (a reversal
  of the rank order); `p_reversal_adj` is Holm-adjusted over the bands
  of the sample. The tests use the unweighted counts.

Rows with a missing or infinite score, or a zero weight, are not
counted; rows with a missing outcome count in the volume (`n`, `pct`,
the PSI) but not in the rates.

The bootstrap of the AUC draws the event and non-event counts of every
score value from multinomial laws with the observed shares (the law of a
row bootstrap stratified by outcome), with the unweighted class counts
as sizes; a given `seed` is local to the call, while `seed = NULL` draws
from, and advances, the user's random stream. Up to `boot_cells` cells
of the count table the bootstrap is exact. Above it, the resamples run
on `boot_cells` cells of equal share (adjacent cells pooled) and are
shifted to the point estimate of the full table, so the interval is an
approximation. The point estimates use every cell of the count table:
every distinct score, unless `max_cells` pooled the scores into cells.
`boot_cells = Inf` keeps the bootstrap exact, at a cost per resample
proportional to the number of cells.

## References

Brown, L. D., Cai, T. T. and DasGupta, A. (2001). Interval estimation
for a binomial proportion. *Statistical Science*, 16(2), 101-133.
[doi:10.1214/ss/1009213286](https://doi.org/10.1214/ss/1009213286)

DeLong, E. R., DeLong, D. M. and Clarke-Pearson, D. L. (1988). Comparing
the areas under two or more correlated receiver operating characteristic
curves: a nonparametric approach. *Biometrics*, 44(3), 837-845.

Siddiqi, N. (2006). *Credit Risk Scorecards: Developing and Implementing
Intelligent Credit Scoring*. Wiley.

Yurdakul, B. and Naranjo, J. (2020). Statistical properties of the
population stability index. *Journal of Risk Model Validation*, 14(4),
89-100.

## See also

[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)
for a small number of policy tiers,
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md)
for traffic lights,
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
and
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
to assign the bands in production.

Other score-studies:
[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md),
[`scr_detection()`](https://evandeilton.github.io/scorecraft/reference/scr_detection.md),
[`scr_maturity()`](https://evandeilton.github.io/scorecraft/reference/scr_maturity.md),
[`scr_mix_shift()`](https://evandeilton.github.io/scorecraft/reference/scr_mix_shift.md),
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md),
[`scr_overlap()`](https://evandeilton.github.io/scorecraft/reference/scr_overlap.md),
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md),
[`scr_rag_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_rag_plan.md),
[`scr_score_cross()`](https://evandeilton.github.io/scorecraft/reference/scr_score_cross.md),
[`scr_segments()`](https://evandeilton.github.io/scorecraft/reference/scr_segments.md),
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md),
[`scr_uplift()`](https://evandeilton.github.io/scorecraft/reference/scr_uplift.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 40, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                  date_col = "ref_date")
sc <- scr_scorecard(res)
b <- scr_bands(sc, n_bands = 10)
b
#> <scr_study_bands> target "default" | objective risk | higher_is_safer
#>   bands frozen on 'train', read on 'holdout' | 10 requested, 10 effective (uniform)
#>   sample             n    events     rate AUC [95% CI]           Gini     KS     IV     PSI  reversals
#>   train          2,800       399   14.25% 0.7856 [0.764, 0.813]  0.571  0.441  1.136       -         0
#>   holdout        1,400       203   14.50% 0.7394 [0.715, 0.763]  0.479  0.389  0.804  0.0069         0
#> 
#> Bands on 'holdout' (event-richest first; 95% Jeffreys interval of the rate)
#>   band score                        pct rate [lo, hi]                 lift  capture     KS p_rev_adj
#>      1 [-Inf, 509.8922)            9.1% 35.43% [27.52%, 44.00%]       2.44    22.2%  0.153         -
#>      2 [509.8922, 523.5026)        9.1% 27.34% [20.19%, 35.51%]       1.89    39.4%  0.248     1.000
#>      3 [523.5026, 533.3684)        9.9% 26.62% [19.81%, 34.39%]       1.84    57.6%  0.345     1.000
#>      4 [533.3684, 542.0923)       10.6% 17.45% [12.01%, 24.14%]       1.20    70.4%  0.370     1.000
#>      5 [542.0923, 550.3612)       10.8% 11.26% [6.96%, 17.03%]        0.78    78.8%  0.342     1.000
#>      6 [550.3612, 557.7648)       10.6% 12.16% [7.64%, 18.15%]        0.84    87.7%  0.322     1.000
#>      7 [557.7648, 566.5601)       10.6% 7.38% [3.99%, 12.41%]         0.51    93.1%  0.261     1.000
#>      8 [566.5601, 576.5187)        9.1% 3.91% [1.51%, 8.35%]          0.27    95.6%  0.183     1.000
#>      9 [576.5187, 590.2783)        8.9% 3.23% [1.10%, 7.49%]          0.22    97.5%  0.102     1.000
#>     10 [590.2783, Inf)            11.2% 3.18% [1.23%, 6.84%]          0.22   100.0%  0.000     1.000
b$table[sample == "holdout", .(band, label, n, rate, lift, capture, ks)]
#>      band                label     n       rate      lift   capture        ks
#>     <int>               <char> <num>      <num>     <num>     <num>     <num>
#>  1:     1     [-Inf, 509.8922)   127 0.35433071 2.4436601 0.2216749 0.1531703
#>  2:     2 [509.8922, 523.5026)   128 0.27343750 1.8857759 0.3940887 0.2478898
#>  3:     3 [523.5026, 533.3684)   139 0.26618705 1.8357728 0.5763547 0.3449428
#>  4:     4 [533.3684, 542.0923)   149 0.17449664 1.2034251 0.7044335 0.3702647
#>  5:     5 [542.0923, 550.3612)   151 0.11258278 0.7764330 0.7881773 0.3420621
#>  6:     6 [550.3612, 557.7648)   148 0.12162162 0.8387698 0.8768473 0.3221272
#>  7:     7 [557.7648, 566.5601)   149 0.07382550 0.5091414 0.9310345 0.2610261
#>  8:     8 [566.5601, 576.5187)   128 0.03906250 0.2693966 0.9556650 0.1828998
#>  9:     9 [576.5187, 590.2783)   124 0.03225806 0.2224694 0.9753695 0.1023536
#> 10:    10      [590.2783, Inf)   157 0.03184713 0.2196354 1.0000000 0.0000000

# tail percentiles, from a data.frame
d <- data.frame(score = sc$samples$holdout$score, y = sc$samples$holdout$y)
scr_bands(d, spacing = "tail", n_boot = 0)$table[, .(band, label, pct, rate, capture)]
#>     band                label          pct      rate     capture
#>    <int>               <char>        <num>     <num>       <num>
#> 1:     1     [-Inf, 458.7678) 0.0007142857 1.0000000 0.004926108
#> 2:     2 [458.7678, 472.9255) 0.0042857143 0.0000000 0.004926108
#> 3:     3 [472.9255, 480.5795) 0.0050000000 0.5714286 0.024630542
#> 4:     4 [480.5795, 488.4818) 0.0100000000 0.3571429 0.049261084
#> 5:     5  [488.4818, 498.268) 0.0300000000 0.3333333 0.118226601
#> 6:     6  [498.268, 512.1523) 0.0500000000 0.3714286 0.246305419
#> 7:     7 [512.1523, 525.5947) 0.1000000000 0.2714286 0.433497537
#> 8:     8 [525.5947, 550.6549) 0.3000000000 0.1738095 0.793103448
#> 9:     9      [550.6549, Inf) 0.5000000000 0.0600000 1.000000000
```
