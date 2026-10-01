# Probability statements about the event rate of score groups

Tests claims such as "the customers scoring 625 or more respond at a
rate of at least 60%" or "tier 'low' defaults at no more than 2%" on a
study sample, and writes each verdict as one English sentence with the
observed rate and its one-sided bound.

## Usage

``` r
scr_claims(x, claims, ...)

# S3 method for class 'scr_study'
scr_claims(
  x,
  claims,
  level = NULL,
  adjust = c("holm", "none"),
  type = c("average", "floor"),
  sample = NULL,
  floor_bins = 10L,
  ...
)

# S3 method for class 'scr_scorecard'
scr_claims(
  x,
  claims,
  level = NULL,
  adjust = c("holm", "none"),
  type = c("average", "floor"),
  sample = "holdout",
  reference = "train",
  n_bands = NULL,
  max_cells = 1e+05,
  floor_bins = 10L,
  ...
)

# S3 method for class 'data.frame'
scr_claims(
  x,
  claims,
  level = 0.95,
  adjust = c("holm", "none"),
  type = c("average", "floor"),
  sample = NULL,
  score = "score",
  y = "y",
  objective = "risk",
  direction = NULL,
  weight = NULL,
  reference = NULL,
  study = NULL,
  counts = FALSE,
  n = "n",
  events = "events",
  n_bands = 20L,
  max_cells = 1e+05,
  floor_bins = 10L,
  ...
)
```

## Arguments

- x:

  An object from
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
  or
  [`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md),
  an object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
  or a `data.frame` with one row per scored case (or one row per score
  value with `counts = TRUE`).

- claims:

  A `data.frame` of claims; see the section Claims.

- ...:

  Passed on to the methods; an unknown argument is an error.

- level:

  Confidence level of the tests and of the one-sided bounds. For a
  scorecard, `NULL` uses `config$study_level` (0.95); for a score study,
  `NULL` uses the level of the study.

- adjust:

  `"holm"` (default) or `"none"`: multiplicity adjustment across the
  claims.

- type:

  `"average"` (the rate of the whole group) or `"floor"` (the rate at
  the weakest end of the group under a monotone fit of the rate); see
  the section Average and floor.

- sample:

  For a score study: the sample the claims are read on, `NULL` for its
  first study sample. For a scorecard: that sample (`"holdout"`). For a
  data.frame: the name of a column with sample labels, as in
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md);
  the claims are read on `study`.

- floor_bins:

  Pre-bins of equal share of a group for `type = "floor"`: the
  resolution of the floor (default 10; 1 makes the floor the average).

- reference:

  For a scorecard: the sample the bands are frozen on (`"train"`). For a
  data.frame: the label of the reference sample; `NULL` takes the first
  level of the `sample` column.

- n_bands:

  Bands of the internal percentile study (their labels and numbers can
  be used in `claims$label`). For a scorecard, `NULL` uses
  `config$study_bands` (20).

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

  For a data.frame: the label of the sample the claims are read on;
  `NULL` takes the first label other than the reference.

- counts:

  `TRUE` when `x` is pre-aggregated: one row per score value with the
  columns `score`, `n` and `events` (and, optionally, `value` and
  `value_events`).

- n, events:

  Column names of the counts when `counts = TRUE`.

## Value

An object of class `c("scr_claims", "list")`:

- `table`:

  One row per claim: `name`, `group` (the label or the score range),
  `type`, `score_lo` and `score_hi` (the range tested), `n` (rows with a
  known outcome; their weighted volume under weights), `n_eff` (Kish
  effective size, the `n` of the test; equal to `n` without weights),
  `events`, `rate`, `bound` (one-sided Jeffreys bound), `op`,
  `rate_claimed`, `p_value` and `p_adj` (test of the claim), `p_refute`
  and `p_refute_adj` (the opposite test), `verdict` and `statement`
  (under weights, the sentence quotes the effective n of the test next
  to the weighted volume).

- `sample`, `reference`, `level`, `adjust`, `type`, `floor_bins`,
  `objective`, `direction`, `target`, `call`:

  The settings (`floor_bins` is used by `type = "floor"` only).

## Claims

`claims` is a `data.frame` with one row per claim:

- `op`:

  `">="` (the event rate is at least `rate`) or `"<="` (at most `rate`).

- `rate`:

  The claimed event rate, in (0, 1).

- `label`:

  A band or tier of the study: its label (the `label` column of the
  study table, or the numbered `tier_label` of a tiers study) or its
  number (the `band` or `tier` column).

- `score_lo`, `score_hi`:

  Instead of a label, a score range `[score_lo, score_hi)`; a missing
  end is open. A claim with neither a label nor a score range is on the
  whole sample.

- `name`:

  Optional: a name for the printed statement.

## Test

Each claim is read on the rows of the group with a known outcome in the
study sample. With weights, the counts are taken to the Kish effective
size \\n = (\sum w)^2 / \sum w^2\\ and \\x = \hat p\\ n\\ effective
events (without weights, the counts themselves). The claim "rate \>= r"
is the alternative to \\H_0: p \le r\\, tested by the exact one-sided
binomial p-value \\P(X \ge x)\\, \\X \sim \mathrm{Binomial}(n, r)\\;
\\x\\ and \\n\\ are rounded to whole numbers for the binomial only. The
refutation is the opposite test, \\P(X \le x)\\. For "rate \<= r" the
two tests swap. With `adjust = "holm"`, the claim p-values and the
refutation p-values are each Holm-adjusted across the claims. They are
two Holm families, the tests of the claims and the tests of the
refutations, each controlled at `1 - level`; a claim and its refutation
can never both be significant.

The verdict is `"supported"` when the adjusted p-value of the claim is
below `1 - level`, `"refuted"` when the adjusted p-value of the
refutation is, and `"not proven"` otherwise (also for a group without a
row with a known outcome). `bound` is the one-sided Jeffreys bound at
`level` in the direction of the claim, on the unrounded effective
counts: the lower bound, the Beta(\\x + 1/2, n - x + 1/2\\) quantile
`1 - level`, for "rate \>= r" (0 when \\x = 0\\), and the upper bound,
its quantile `level`, for "rate \<= r" (1 when \\x = n\\). The bound
describes the uncertainty; the verdict comes from the tests.

## Average and floor

`type = "average"` reads the claim on the event rate of the whole group.
`type = "floor"` reads it on the weakest end of the group under a
monotone fit of the rate: a claim that holds there holds for the part of
the group where it is hardest to meet, not only for the average.

The reference rows of the group are cut into `floor_bins` pre-bins of
equal share (tie-safe, as the bands of
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)),
and their event rates are fitted by pool adjacent violators: the rate is
made monotone along the score, rising toward its event-rich end. The
weakest end is the run of pre-bins with the lowest fitted rate of the
group for "rate \>= r", with the highest for "rate \<= r". Its score
range is found on the reference sample and the claim is tested on the
rows of the study sample in that range, so the end is not chosen on the
rows it is tested on (unless the study sample is the reference). When
the fitted rate is flat over the group, the weakest end is the whole
group.

Two limits follow from the fit. A dip of the rate inside the group is
pooled with its neighbors by the monotone fit, so the floor does not see
a weak pocket in the middle of the group, only the end the fit calls
weakest. And `floor_bins` sets the resolution: the floor speaks for runs
of pre-bins, about one part in `floor_bins` of the group or more, never
for a single customer (a fit on single score values would spike at its
ends and read the floor on a handful of rows).

## Input

An object from
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
or
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)
is read as it is: labels refer to its bands or tiers, and `sample` picks
one of its samples (by default its first study sample). A scorecard or a
`data.frame` is first summarized by a percentile study
([`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
`n_bands` bands frozen on the reference, no bootstrap) whose count table
keeps every distinct score up to `max_cells`; the finite ends of the
score ranges of `claims` are forced as cell edges, so a score range is
exact even when more distinct scores are pooled into cells. A score
range read on a study whose cells were pooled must not cut through a
cell, or the call is an error.

## References

Brown, L. D., Cai, T. T. and DasGupta, A. (2001). Interval estimation
for a binomial proportion. *Statistical Science*, 16(2), 101-133.
[doi:10.1214/ss/1009213286](https://doi.org/10.1214/ss/1009213286)

Holm, S. (1979). A simple sequentially rejective multiple test
procedure. *Scandinavian Journal of Statistics*, 6(2), 65-70.

Kish, L. (1965). *Survey Sampling*. Wiley.

## See also

[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
and
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)
for the groups,
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md)
to choose a cut under constraints.

Other score-studies:
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md),
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md),
[`scr_rag_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_rag_plan.md),
[`scr_score_cross()`](https://evandeilton.github.io/scorecraft/reference/scr_score_cross.md),
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)

## Examples

``` r
set.seed(1)
x <- rnorm(4000)
d <- data.frame(score = round(500 + 50 * x),
                y = rbinom(4000, 1, plogis(-0.5 + 1.2 * x)))
claims <- data.frame(op = c(">=", ">=", "<="), rate = c(0.60, 0.80, 0.25),
                     score_lo = c(550, 550, NA), score_hi = c(NA, NA, 450),
                     name = c("top converts", "top converts well", "bottom is cold"))
cl <- scr_claims(d, claims, objective = "propensity")
cl
#> <scr_claims> target "y" | objective propensity | sample 'all' | level 95% (one-sided) | adjustment holm | average
#>   claim                    group                              n     rate    bound claimed       p_adj  verdict
#>   top converts             score >= 550                     692    78.3%    75.7% >= 60.0%     0.0000  supported
#>   top converts well        score >= 550                     692    78.3%    75.7% >= 80.0%     0.8743  not proven
#>   bottom is cold           score < 450                      645     9.5%    11.5% <= 25.0%     0.0000  supported
#> 
#> On 'all' (n = 692), rows with score >= 550 had an event rate of 78.3% (95% one-sided lower bound
#>   75.7%); the claim 'top converts' (rate >= 60%) is supported.
#> On 'all' (n = 692), rows with score >= 550 had an event rate of 78.3% (95% one-sided lower bound
#>   75.7%); the claim 'top converts well' (rate >= 80%) is not proven.
#> On 'all' (n = 645), rows with score < 450 had an event rate of 9.5% (95% one-sided upper bound
#>   11.5%); the claim 'bottom is cold' (rate <= 25%) is supported.
cl$table[, c("name", "n", "rate", "bound", "p_adj", "verdict")]
#>                 name     n       rate     bound        p_adj    verdict
#>               <char> <num>      <num>     <num>        <num>     <char>
#> 1:      top converts   692 0.78323699 0.7566252 2.834300e-24  supported
#> 2: top converts well   692 0.78323699 0.7566252 8.743393e-01 not proven
#> 3:    bottom is cold   645 0.09457364 0.1148683 1.504897e-23  supported

# the same claims at the weakest end of each group, not only on its average
scr_claims(d, claims, objective = "propensity", type = "floor")$table$verdict
#> [1] "not proven" "refuted"    "supported" 

# claims on the tiers of a study, by label
tr <- scr_tiers(d, objective = "propensity", n_tiers = 3)
scr_claims(tr, data.frame(label = "high", op = ">=", rate = 0.5))
#> <scr_claims> target "y" | objective propensity | sample 'all' | level 95% (one-sided) | adjustment holm | average
#>   claim                    group                              n     rate    bound claimed       p_adj  verdict
#>   rate >= 50%              high                           1,199    71.5%    69.3% >= 50.0%     0.0000  supported
#> 
#> On 'all' (n = 1,199), rows in tier 'high' had an event rate of 71.5% (95% one-sided lower bound
#>   69.3%); the claim 'rate >= 50%' is supported.
```
