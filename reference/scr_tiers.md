# Tiers of a score: a few labeled levels of risk or propensity

Groups the score into a small number of contiguous tiers (typically 3, 5
or 7, labeled from "very low" to "very high") **fitted on the reference
sample** and read on the reference and the study samples. Tiers are a
policy and communication device; they are not a rating scale in the
sense of the internal ratings-based approach (see
[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md)
for that).

## Usage

``` r
scr_tiers(x, ...)

# S3 method for class 'scr_scorecard'
scr_tiers(
  x,
  n_tiers = 5L,
  method = c("optimal", "anchored", "quantile"),
  criterion = c("deviance", "iv"),
  anchors = NULL,
  conservative = FALSE,
  level = NULL,
  min_pct = NULL,
  min_events = NULL,
  alpha = 0.05,
  max_bins = NULL,
  labels = NULL,
  round_to = NULL,
  n_boot = 0L,
  seed = NULL,
  sample = "holdout",
  reference = "train",
  max_cells = 1e+05,
  ...
)

# S3 method for class 'data.frame'
scr_tiers(
  x,
  score = "score",
  y = "y",
  objective = "risk",
  direction = NULL,
  weight = NULL,
  sample = NULL,
  reference = NULL,
  study = NULL,
  counts = FALSE,
  n = "n",
  events = "events",
  n_tiers = 5L,
  method = c("optimal", "anchored", "quantile"),
  criterion = c("deviance", "iv"),
  anchors = NULL,
  conservative = FALSE,
  level = 0.95,
  min_pct = 0.05,
  min_events = 20L,
  alpha = 0.05,
  max_bins = 100L,
  labels = NULL,
  round_to = NULL,
  n_boot = 0L,
  seed = NULL,
  max_cells = 1e+05,
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

- n_tiers:

  Number of tiers requested (2 to 9).

- method:

  `"optimal"`, `"anchored"` or `"quantile"`.

- criterion:

  For `"optimal"`: `"deviance"` (binomial log-likelihood) or `"iv"`
  (information value).

- anchors:

  For `"anchored"`: event-rate thresholds, as numbers in (0, 1) or the
  string `"overall"` (the reference event rate); a character vector may
  mix both.

- conservative:

  For `"anchored"`: compare the anchors with the lower Jeffreys bound of
  the block rate instead of the rate.

- level:

  Confidence level of the Jeffreys intervals. For a scorecard, `NULL`
  uses `config$study_level` (0.95).

- min_pct:

  Smallest volume share of a tier. For a scorecard, `NULL` uses
  `config$tier_min_pct` (0.05).

- min_events:

  Fewest events, and fewest non-events, of a tier. For a scorecard,
  `NULL` uses `config$tier_min_events` (20).

- alpha:

  Significance level of the adjacency test (divided by `n_tiers - 1`)
  and of `all_distinct`.

- max_bins:

  Pre-bins of the search (2 to 500). For a scorecard, `NULL` uses
  `config$tier_max_bins` (100).

- labels:

  Optional labels, one per tier achieved, in ascending order of the
  event rate.

- round_to:

  Optional positive number: cuts are rounded to its multiples.

- n_boot:

  Bootstrap resamples of the stability study (`0`, the default, skips
  it).

- seed:

  Seed of the stability bootstrap. A number is local to the call (the
  user's random stream is restored on exit); `NULL` draws from the
  user's stream and advances it. For a scorecard, `NULL` uses
  `config$seed`.

- sample:

  For a scorecard: the study sample(s), `"holdout"` (default) and/or
  `"train"`. For a data.frame: the name of a column with sample labels,
  or `NULL` (all rows are one sample, reference and study at once).

- reference:

  For a scorecard: the sample the bands are frozen on (`"train"`). For a
  data.frame: the label of the reference sample; `NULL` takes the first
  level of the `sample` column.

- max_cells:

  Largest number of distinct score values kept exactly.

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

- study:

  Labels of the study samples; `NULL` takes every level other than the
  reference.

- counts:

  `TRUE` when `x` is pre-aggregated: one row per score value with the
  columns `score`, `n` and `events` (and, optionally, `value` and
  `value_events`).

- n, events:

  Column names of the counts when `counts = TRUE`.

## Value

An object of class `c("scr_study_tiers", "scr_study", "list")`:

- `table`:

  One row per sample and tier, event-richest tier first: `sample`,
  `tier`, `label`, `score_lo`, `score_hi`, `n`, `pct`, `events`, `rate`,
  `rate_lo`, `rate_hi`, `lift`, `pct_event`, `pct_nonevent`, `woe`,
  `p_adjacent` (one-sided Fisher exact test that the tier has a higher
  event rate than the next lower tier) and `p_adjacent_adj` (Holm).

- `summary`:

  One row per sample: `sample`, `n`, `events`, `rate`, `n_tiers`,
  `monotone` (the rates rise with the tier), `all_distinct` (every
  `p_adjacent_adj` below `alpha`), `iv` and `psi` (of the tier mix
  against the reference).

- `cuts`, `cuts_raw`:

  The cuts in use (rounded when `round_to` is given) and the fitted
  ones.

- `labels`:

  The tier labels, lowest rate first.

- `codes`, `code_labels`:

  Tier number and label of every interval in ascending score order, used
  by
  [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
  and
  [`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md).

- `method`, `criterion`, `measure`, `n_tiers_requested`, `n_tiers`:

  The fit.

- `ledger`:

  One row per step: `step`, `n_tiers`, `status` and `detail`.

- `stability`:

  `NULL`, or with `n_boot > 0` a list: `cuts` (per cut: `score`,
  `median`, `q25`, `q75`, `iqr` and `n_same`, the resamples that gave
  the same number of tiers), `agreement`, `same_count` and `n_boot`.

- `objective`, `direction`, `level`, `alpha`, `min_pct`, `min_events`,
  `reference`, `samples`, `target`, `hist`, `call`:

  The settings and the count table.

## Method

The reference scores are cut into at most `max_bins` pre-bins of equal
share (tie-safe, as in
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md));
adjacent pre-bins are then pooled (pool adjacent violators) until the
event rate rises monotonically toward the event-rich side of the score.
Every tier is a run of these blocks, so the tier rates are monotone on
the reference.

`method = "optimal"` searches every segmentation of the blocks into
`n_tiers` contiguous tiers with an exact dynamic program and keeps the
one that maximizes the binomial log-likelihood \$\$\sum_t \left\[e_t \ln
p_t + (n_t - e_t) \ln(1 - p_t)\right\], \qquad p_t = e_t / n_t\$\$
(`criterion = "deviance"`, the same as minimizing the deviance) or the
information value (`criterion = "iv"`), subject to: every tier holds at
least `min_pct` of the volume; at least `min_events` events **and**
`min_events` non-events; and every pair of adjacent tiers is distinct by
a one-sided Fisher exact test at `alpha / (L - 1)`, where \\L\\ is the
tier count being tried. The rates and the objective use the weighted
counts; the event constraints and the Fisher test use the unweighted
counts. When no segmentation into `n_tiers` tiers meets the constraints,
`n_tiers - 2`, `n_tiers - 4`, ... down to 2 are tried (an odd count
stays odd while possible); when even 2 tiers are infeasible, the last
resort is a single tier. Every attempt is recorded in `ledger` and a
warning is raised. The tiers are never relabeled silently: the labels
follow the number of tiers achieved.

The previous tier enters the state of the program, so its cost is \\O(L
M^3)\\ time and \\L M^2\\ memory for \\L\\ tiers and \\M\\ blocks
(compiled code); the Fisher tests are cached when \\M \le 200\\ and
recomputed above. `n_tiers` is capped at 9 and `max_bins` (hence \\M\\)
at 500, and the stability study refits once per resample, so `n_boot`
multiplies the cost.

`method = "anchored"` places one cut per value of `anchors` (event-rate
thresholds; `"overall"` stands for the reference event rate): the cut
sits before the first block, from the low-rate side, whose event rate
(its lower Jeffreys bound with `conservative = TRUE`) reaches the
anchor. `n_tiers` is then `length(anchors) + 1` and the argument is
ignored. `method = "quantile"` cuts the reference into `n_tiers` tiers
of equal share, the baseline.

`round_to` rounds every cut to the nearest multiple (a policy-friendly
cut-off, such as 500 or 520 points); the tiers are then re-evaluated on
every sample with the rounded cuts, and both sets of cuts are kept. When
the scores were pooled into cells (`max_cells`), the count table is
rebuilt with the rounded cuts as forced cell edges, so the reported
tiers agree exactly with
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
and
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md).
Tiers are left-closed: `score >= cut` is the upper side, the convention
of
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md).

With `n_boot > 0`, the stability of the fit is measured by redrawing the
event and non-event counts of the reference pre-bins from a multinomial
law and refitting: per cut, the median and interquartile range of the
refitted cut in score units, and the agreement rate (the share of the
reference volume that keeps its tier).

## Labels

Tiers are numbered by event rate, lowest first: 3 tiers are labeled
`"low"`, `"medium"`, `"high"`; 5 tiers `"very low"`, `"low"`,
`"medium"`, `"high"`, `"very high"`; 7 tiers add `"extremely low"` and
`"extremely high"`; any other count `"T1"`, `"T2"`, ... The labels
describe the event rate, so under `objective = "risk"` they read as risk
and under `"propensity"` as propensity (`measure`). The table lists the
event-richest tier first.

## References

Brown, L. D., Cai, T. T. and DasGupta, A. (2001). Interval estimation
for a binomial proportion. *Statistical Science*, 16(2), 101-133.
[doi:10.1214/ss/1009213286](https://doi.org/10.1214/ss/1009213286)

Siddiqi, N. (2006). *Credit Risk Scorecards: Developing and Implementing
Intelligent Credit Scoring*. Wiley.

Yurdakul, B. and Naranjo, J. (2020). Statistical properties of the
population stability index. *Journal of Risk Model Validation*, 14(4),
89-100.

## See also

[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md);
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
and
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
assign the tiers in production.

Other score-studies:
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md),
[`scr_rag_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_rag_plan.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 40, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                  date_col = "ref_date")
sc <- scr_scorecard(res)
tr <- scr_tiers(sc, n_tiers = 5)
tr
#> <scr_study_tiers> target "default" | measure risk | higher_is_safer
#>   optimal (deviance) | 5 tiers requested, 5 achieved | fitted on 'train'
#>   cuts: 502.3609, 516.0750, 538.0089, 555.0927
#>   sample             n    events     rate     IV     PSI  tiers  monotone  distinct
#>   train          2,800       399   14.25%  1.162       -      5       yes       yes
#>   holdout        1,400       203   14.50%  0.744  0.0019      5       yes        no
#> 
#> Tiers on 'holdout' (event-richest first)
#>   tier label           score                        pct     rate [95% CI]               p_adj
#>      5 very high       [-Inf, 502.3609)            6.3%   36.36% [26.88%, 46.72%]       0.487
#>      4 high            [502.3609, 516.075)         6.9%   35.05% [26.11%, 44.87%]       0.033
#>      3 medium          [516.075, 538.0089)        20.6%   23.18% [18.60%, 28.30%]       0.001
#>      2 low             [538.0089, 555.0927)       22.4%   12.46% [9.15%, 16.46%]        0.000
#>      1 very low        [555.0927, Inf)            43.8%    5.06% [3.53%, 7.01%]             -
tr$table[sample == "holdout", .(tier, label, score_lo, score_hi, pct, rate)]
#>     tier     label score_lo score_hi        pct       rate
#>    <int>    <char>    <num>    <num>      <num>      <num>
#> 1:     5 very high     -Inf 502.3609 0.06285714 0.36363636
#> 2:     4      high 502.3609 516.0750 0.06928571 0.35051546
#> 3:     3    medium 516.0750 538.0089 0.20642857 0.23183391
#> 4:     2       low 538.0089 555.0927 0.22357143 0.12460064
#> 5:     1  very low 555.0927      Inf 0.43785714 0.05057096

# policy cuts on round numbers, and the tiers assigned to new scores
tr10 <- scr_tiers(sc, n_tiers = 3, round_to = 10)
tr10$cuts
#> [1] 520 550
head(scr_apply(tr10, c(480, 530, 600)))
#>    score  tier tier_label
#>    <num> <int>     <char>
#> 1:   480     3       high
#> 2:   530     2     medium
#> 3:   600     1        low

# anchors on the event rate: below, around and above the overall rate
scr_tiers(sc, method = "anchored", anchors = c(0.08, "overall", 0.25))$summary
#>     sample     n events   rate n_tiers monotone all_distinct       iv
#>     <char> <num>  <num>  <num>   <int>   <lgcl>       <lgcl>    <num>
#> 1:   train  2800    399 0.1425       4     TRUE         TRUE 1.120941
#> 2: holdout  1400    203 0.1450       4     TRUE         TRUE 0.732374
#>             psi
#>           <num>
#> 1:           NA
#> 2: 0.0006075206
```
