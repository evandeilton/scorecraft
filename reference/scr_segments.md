# One score on many segments

Reads one score on the segments of a population (a product, a channel, a
region) and says, for each, whether the score ranks and calibrates there
as it does on the whole: discrimination with its standard error, the
observed events against those expected from the pooled bands, the offset
on the log-odds scale, the slope of the score relative to the pooled one
and a suggested action.

## Usage

``` r
scr_segments(x, ...)

# S3 method for class 'data.frame'
scr_segments(
  x,
  segment,
  by = NULL,
  n_bands = 10L,
  level = 0.95,
  min_events = 20L,
  n_boot = 0L,
  auc_tol = 0.03,
  offset_tol = 0.25,
  slope_tol = 0.25,
  score = "score",
  y = "y",
  objective = "risk",
  direction = NULL,
  weight = NULL,
  seed = NULL,
  max_cells = 1e+05,
  ...
)

# S3 method for class 'scr_scorecard'
scr_segments(
  x,
  newdata,
  segment,
  by = NULL,
  n_bands = 10L,
  level = NULL,
  min_events = 20L,
  n_boot = 0L,
  auc_tol = 0.03,
  offset_tol = 0.25,
  slope_tol = 0.25,
  target = NULL,
  seed = NULL,
  max_cells = 1e+05,
  ...
)
```

## Arguments

- x:

  A `data.frame` with one row per scored case, or an object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

- ...:

  Passed on to the methods; an unknown argument is an error.

- segment:

  Name of the segment column. A missing segment is the segment
  `"(missing)"`.

- by:

  Optional name of a column of periods or groups.

- n_bands:

  Equal-share bands frozen on the pooled rows, for the expected events
  and the PSI.

- level:

  Confidence level of the intervals; `1 - level` is the significance of
  the tests. For a scorecard, `NULL` uses `config$study_level` (0.95).

- min_events:

  Fewest events, and non-events, for an action other than
  `"too few events"`.

- n_boot:

  Bootstrap resamples of the AUC interval; `0` (default) keeps the
  DeLong interval.

- auc_tol, offset_tol, slope_tol:

  Tolerances of the actions: on the difference of the AUC from the
  weighted mean, on the absolute offset and on the distance of the slope
  ratio from 1.

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

- seed:

  Seed of the bootstrap. A number is local to the call (the user's
  random stream is restored on exit); `NULL` draws from the user's
  stream and advances it. For a scorecard, `NULL` uses `config$seed`.

- max_cells:

  Largest number of distinct score values kept exactly.

- newdata:

  For a scorecard: the rows to score with
  [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
  holding the candidate variables, the target and the segment column.

- target:

  For a scorecard: the outcome column of `newdata`; `NULL` uses the
  target of the scorecard.

## Value

An object of class `c("scr_segments", "list")`:

- `table`:

  One row per group and segment: `group`, `segment`, `n`, `events`,
  `rate`, `auc`, `auc_se`, `auc_lo`, `auc_hi`, `gini`, `ks`, `psi`,
  `psi_critical`, `expected`, `oe_ratio`, `oe_lo`, `oe_hi`, `offset`,
  `slope`, `slope_ratio`, `auc_diff`, `p_auc`, `p_auc_adj`, `p_slope`,
  `p_slope_adj` and `action`.

- `test`:

  One row per group: `group`, `segments` (those in the test), `auc_w`,
  `statistic`, `df` and `p_value`.

- `pooled`:

  One row per group, the pooled rows: `group`, `n`, `events`, `rate`,
  `auc`, `auc_se`, `auc_lo`, `auc_hi`, `gini`, `ks` and `slope`.

- `cuts`, `segment`, `by`, `level`, `min_events`, `auc_tol`,
  `offset_tol`, `slope_tol`, `objective`, `direction`, `target`, `call`:

  The pooled cuts and the settings.

## Statistics

The rows are counted once per segment and distinct score. Per segment:

- `auc`, `gini` and `ks`, with the DeLong standard error `auc_se`
  computed from the counts and the interval `auc +/- z * auc_se` (cut to
  \[0, 1\]); with `n_boot > 0`, the interval is the percentile interval
  of the count bootstrap of
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md).
  A segment without a positive standard error (fewer than two events or
  non-events, or every score tied) has no interval.

- `psi`: the population stability index of the score distribution of the
  segment against the pooled one, over `n_bands` equal-share bands
  frozen on the pooled rows (see
  [`scr_psi()`](https://evandeilton.github.io/scorecraft/reference/scr_psi.md)).
  The segment is part of the pooled rows, so the two distributions are
  not independent: `psi_critical`, the n-adjusted critical value at
  `1 - level`, uses \\(1/n_s - 1/N)\\\chi^2\_{B-1}\\ in place of
  \\(1/n_s + 1/N)\\\chi^2\_{B-1}\\, with \\n_s\\ and \\N\\ the sizes of
  the segment and of the pooled rows (under weights, the Kish effective
  sizes, with the covariance term scaled by the weight share of the
  segment). It is `NA` when the segment is the whole pool.

- `expected`: the events expected by indirect standardization, \\\sum_b
  n\_{s,b} R_b\\, with \\n\_{s,b}\\ the rows of the segment in the
  pooled band \\b\\ and \\R_b\\ the pooled event rate of the band;
  `oe_ratio` = events / `expected`, with the Jeffreys interval of the
  observed rate (on the Kish effective size under weights) divided by
  the expected rate.

- `offset` = logit(observed rate) - logit(expected rate): what a segment
  intercept would add to the log-odds. `NA` when either rate is 0 or 1.

- `slope`: the coefficient of the score in a logistic regression of the
  outcome within the segment, fitted on the count table with the counts
  as weights (equal to the fit on the rows); `slope_ratio` is `slope`
  over the pooled slope. `NA` when the segment has a single score value
  or its classes are separated by the score. `p_slope` is the two-sided
  Wald test of the slope of the segment against the slope fitted on the
  rest of its group (the pooled rows without the segment, an independent
  sample), \\z = (b_s - b_r) / \sqrt{v_s + v_r}\\ with the model-based
  variances of the two fits (scaled to the Kish effective size under
  weights); `p_slope_adj` is its Holm adjustment across the segments.

Rows with a missing outcome count in the volume and in the PSI only.
With more than `max_cells` distinct scores the scores are pooled into
cells, and the slope is fitted on the cell midpoints.

## Test of equal discrimination

With \\w_s = 1 / se_s^2\\, the inverse-variance weighted mean is \\AUC_w
= \sum_s w_s AUC_s / \sum_s w_s\\, and \$\$Q = \sum_s (AUC_s - AUC_w)^2
/ se_s^2\$\$ is compared with a chi-square law with \\S - 1\\ degrees of
freedom (`test`: `statistic`, `df`, `p_value`). The segments are
disjoint, so their AUCs are independent. Per segment, `auc_diff` =
\\AUC_s - AUC_w\\ is tested by a two-sided z test with the variance
\\se_s^2 - 1 / \sum_s w_s\\ (the mean contains the segment); `p_auc` is
its p-value and `p_auc_adj` the Holm adjustment across the segments.
Segments without a positive standard error (fewer than two events or
non-events, or every score tied) are left out of the test. With exactly
two segments the two tests are one and the same, so no adjustment is
made; the same holds for the slope tests.

## Action

A convention of this package, read in this order:

- `"too few events"`:

  Fewer than `min_events` events, or non-events, in the segment
  (unweighted counts).

- `"separate model"`:

  The score ranks differently: `abs(auc_diff) > auc_tol` with
  `p_auc_adj < 1 - level`, or `abs(slope_ratio - 1) > slope_tol` with
  `p_slope_adj < 1 - level`. A difference must be both material and
  significant: on a small segment, a slope ratio far from 1 is often
  noise.

- `"offset"`:

  The ranking holds but the level does not: `abs(offset) > offset_tol`
  and the interval of `oe_ratio` excludes 1.

- `"shared"`:

  None of the above: the pooled score serves the segment.

The tolerances are starting points, not rules; set them to the policy in
force.

## Groups

With `by` (a period, a sample label), the analysis is repeated within
each group: the pooled reference of a segment is the whole of its group.
The bands are frozen once, on all rows. Groups and segments are listed
in the order of their labels; numeric columns in numeric order.

## References

Brown, L. D., Cai, T. T. and DasGupta, A. (2001). Interval estimation
for a binomial proportion. *Statistical Science*, 16(2), 101-133.
[doi:10.1214/ss/1009213286](https://doi.org/10.1214/ss/1009213286)

DeLong, E. R., DeLong, D. M. and Clarke-Pearson, D. L. (1988). Comparing
the areas under two or more correlated receiver operating characteristic
curves: a nonparametric approach. *Biometrics*, 44(3), 837-845.

Thomas, L. C., Crook, J. and Edelman, D. (2017). *Credit Scoring and Its
Applications*, 2nd edition. SIAM.
[doi:10.1137/1.9781611974560](https://doi.org/10.1137/1.9781611974560)

## See also

[`scr_mix_shift()`](https://evandeilton.github.io/scorecraft/reference/scr_mix_shift.md)
for the change of the event rate between samples,
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md)
for lights per segment against a reference.

Other score-studies:
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md),
[`scr_detection()`](https://evandeilton.github.io/scorecraft/reference/scr_detection.md),
[`scr_maturity()`](https://evandeilton.github.io/scorecraft/reference/scr_maturity.md),
[`scr_mix_shift()`](https://evandeilton.github.io/scorecraft/reference/scr_mix_shift.md),
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md),
[`scr_overlap()`](https://evandeilton.github.io/scorecraft/reference/scr_overlap.md),
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md),
[`scr_rag_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_rag_plan.md),
[`scr_score_cross()`](https://evandeilton.github.io/scorecraft/reference/scr_score_cross.md),
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md),
[`scr_uplift()`](https://evandeilton.github.io/scorecraft/reference/scr_uplift.md)

## Examples

``` r
local({
  set.seed(1)
  n <- 6000
  seg <- sample(c("app", "store", "web"), n, TRUE, c(0.5, 0.3, 0.2))
  x <- rnorm(n)
  # the score ranks the same everywhere; "web" defaults more at every score
  d <- data.frame(channel = seg, score = round(600 + 50 * x),
                  y = rbinom(n, 1, plogis(-2 - x + 0.6 * (seg == "web"))))
  sg <- scr_segments(d, segment = "channel")
  print(sg)
  sg$test
})
#> <scr_segments> target "y" | objective risk | higher_is_safer | segments of 'channel'
#>   tolerances: AUC 0.03, offset 0.25, slope 0.25 | fewest events 20 | level 95%
#> 
#> Pooled: n 6,000 | rate 17.7% | AUC 0.7375 | equal AUC across 3 segments: chi-square 0.04 (df 2), p 0.9819
#>   segment                n     rate AUC [lo, hi]                 PSI O/E [lo, hi]          offset slope ratio  action
#>   app                3,042    15.6% 0.7406 [0.717, 0.764]     0.0007 0.89 [0.81, 0.96]      -0.14        1.03  shared
#>   store              1,711    15.2% 0.7367 [0.705, 0.768]     0.0029 0.87 [0.77, 0.97]      -0.17        0.97  shared
#>   web                1,247    26.3% 0.7395 [0.708, 0.771]     0.0054 1.45 [1.32, 1.59]      +0.47        1.02  offset
#>     group segments     auc_w  statistic    df   p_value
#>    <char>    <int>     <num>      <num> <int>     <num>
#> 1:    all        3 0.7392968 0.03660684     2 0.9818631
```
