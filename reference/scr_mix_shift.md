# Mix and rate effects of a change in the event rate

Splits the change of the event rate between a base and a comparison
sample into the part due to the mix (the population moved across the
score bands) and the part due to the rates (the bands themselves have a
different event rate), on bands frozen on the base. With `by`, every
period or segment is compared with the base.

## Usage

``` r
scr_mix_shift(x, ...)

# S3 method for class 'scr_study'
scr_mix_shift(x, base = NULL, compare = NULL, level = NULL, ...)

# S3 method for class 'scr_scorecard'
scr_mix_shift(
  x,
  base = NULL,
  compare = NULL,
  by = NULL,
  n_bands = NULL,
  breaks = NULL,
  level = NULL,
  max_cells = 1e+05,
  ...
)

# S3 method for class 'data.frame'
scr_mix_shift(
  x,
  base = NULL,
  compare = NULL,
  by = NULL,
  n_bands = NULL,
  breaks = NULL,
  level = 0.95,
  score = "score",
  y = "y",
  objective = "risk",
  direction = NULL,
  weight = NULL,
  counts = FALSE,
  n = "n",
  events = "events",
  max_cells = 1e+05,
  ...
)
```

## Arguments

- x:

  An object from
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
  [`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)
  or
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
  or a `data.frame` with one row per scored case (or one row per score
  value with `counts = TRUE`).

- ...:

  Passed on to the methods; an unknown argument is an error.

- base:

  The base: a sample or a value of `by` (see the section Input). `NULL`
  takes the reference of a study, `"train"` for a scorecard, and the
  first value of `by` otherwise.

- compare:

  The comparisons: samples or values of `by`. `NULL` takes every one but
  the base.

- level:

  Confidence level: `1 - level` is the significance of the PSI critical
  value and of the count of changed bands. `NULL` uses the level of the
  study or `config$study_level` (0.95).

- by:

  Name of the column of periods or segments. Needed for a data.frame;
  for a scorecard, a column of its scored samples.

- n_bands:

  Equal-share bands frozen on the base. `NULL` uses
  `config$study_bands` (20) for a scorecard and 10 for a data.frame.

- breaks:

  Explicit ascending cut points; overrides `n_bands`.

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

- counts:

  `TRUE` when `x` is pre-aggregated: one row per group and score value
  with the columns `score`, `n` and `events`.

- n, events:

  Column names of the counts when `counts = TRUE`.

## Value

An object of class `c("scr_mix_shift", "list")`:

- `table`:

  One row per comparison and band, event-richest band first: `group`,
  `band`, `label`, `n_base`, `n_cmp` (rows with a known outcome),
  `pct_base`, `pct_cmp`, `rate_base`, `rate_cmp`, `mix_effect`,
  `rate_effect`, `total`, `p_rate` and `p_rate_adj`.

- `summary`:

  One row per comparison: `group`, `n_base`, `n_cmp`, `rate_base`,
  `rate_cmp`, `delta`, `mix_total`, `rate_total`, `share_mix`, `psi`,
  `psi_critical` and `bands_changed` (bands with `p_rate_adj` below
  `1 - level`).

- `cuts`, `base`, `groups`, `by`, `level`, `objective`, `direction`,
  `target`, `call`:

  The cuts and the settings.

## Decomposition

With \\p_k\\ the share of band \\k\\ among the rows with a known outcome
and \\r_k\\ its event rate, on the base (\\b\\) and on the comparison
(\\c\\): \$\$mix_k = (p\_{c,k} - p\_{b,k}) (r\_{b,k} + r\_{c,k}) / 2,
\qquad rate_k = (r\_{c,k} - r\_{b,k}) (p\_{b,k} + p\_{c,k}) / 2.\$\$ The
weights are the midpoints of the two samples, so the effects carry no
interaction term and add up exactly: \\\sum_k mix_k + \sum_k rate_k =
R_c - R_b\\, the change of the overall rate. A band empty in one sample
has no rate there; it takes the rate of the other sample, so its rate
effect is 0 and its whole contribution is a mix effect (the columns
`rate_base` and `rate_cmp` keep the missing rate as `NA`). `total` is
`mix_effect + rate_effect`.

The summary adds, per comparison, `share_mix = mix_total / delta` (`NA`
when the rate did not change; it can fall outside \[0, 1\] when the two
effects have opposite signs) and the PSI of the band shares against the
base with its n-adjusted critical value at `1 - level` (see
[`scr_psi()`](https://evandeilton.github.io/scorecraft/reference/scr_psi.md)).

## Tests

`p_rate` is the two-sided p-value of the change of the rate of the band,
on the unweighted counts: Fisher's exact test when the smallest expected
count of the two-by-two table (sample by outcome) is below 5, and the
pooled two-proportion z test otherwise. `p_rate_adj` is Holm-adjusted
across the bands of the comparison. A band empty in either sample has no
test.

## Input

- A score study:

  An object from
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
  or
  [`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)
  with at least two samples: its cuts and labels are used, `base` is one
  of its samples (default its reference) and `compare` the others.

- A scorecard:

  `base` and `compare` are scored samples (`"train"` against
  `"holdout"`). With `by`, a column of the scored samples such as
  `"date"`, the rows of both samples are pooled and grouped by that
  column; `base` is then one of its values (default the first) and
  `compare` the others.

- A data.frame:

  `by` names the column that tells the groups apart (a period, a segment
  or a sample label); `base` is one of its values (default the first
  level) and `compare` the others.

The values of `by` are read in the order of the levels of a factor, in
numeric order for a numeric column and as sorted text otherwise (dates
included); the first is the default base. Rows with a missing `by` value
are left out. Rows with a missing outcome are left out of the shares and
of the rates, so that the effects add up to the change of the rate.

## References

Holm, S. (1979). A simple sequentially rejective multiple test
procedure. *Scandinavian Journal of Statistics*, 6(2), 65-70.

Yurdakul, B. and Naranjo, J. (2020). Statistical properties of the
population stability index. *Journal of Risk Model Validation*, 14(4),
89-100.

## See also

[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
for the bands,
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md)
for the lights of a sample against its reference,
[`scr_segments()`](https://evandeilton.github.io/scorecraft/reference/scr_segments.md)
for one score read on many segments.

Other score-studies:
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md),
[`scr_detection()`](https://evandeilton.github.io/scorecraft/reference/scr_detection.md),
[`scr_maturity()`](https://evandeilton.github.io/scorecraft/reference/scr_maturity.md),
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
local({
  set.seed(1)
  n <- 6000
  period <- rep(c("2025", "2026"), each = n / 2)
  # 2026 has riskier applicants (mix) and a higher rate at every score (rate)
  x <- rnorm(n, mean = ifelse(period == "2026", -0.3, 0))
  d <- data.frame(period = period, score = round(600 + 50 * x),
                  y = rbinom(n, 1, plogis(-2 - x + 0.3 * (period == "2026"))))
  ms <- scr_mix_shift(d, by = "period", n_bands = 5)
  print(ms)
  ms$table[, c("band", "label", "pct_base", "pct_cmp", "mix_effect", "rate_effect")]
})
#> <scr_mix_shift> target "y" | objective risk | higher_is_safer
#>   base '2025' of 'period' | 5 bands frozen on the base | 1 comparison
#>   2026         rate 15.5% -> 23.4% (+7.83 pp): mix +3.77 pp, rate +4.06 pp | PSI 0.0808 (critical 0.0063)
#> 
#> Largest band effects on '2026' (p_adj: Holm-adjusted test of the band rate)
#>   band score                               share               rate        mix       rate      total   p_adj
#>      1 [-Inf, 556.5)              20.1% -> 28.8%     40.1% -> 44.5%   +3.65 pp   +1.08 pp   +4.73 pp   0.183
#>      2 [556.5, 586.5)             19.8% -> 23.1%     19.5% -> 25.3%   +0.72 pp   +1.24 pp   +1.97 pp   0.040
#>      3 [586.5, 611.5)             19.9% -> 19.1%      9.6% -> 14.6%   -0.09 pp   +0.99 pp   +0.90 pp   0.031
#>      4 [611.5, 644.5)             20.3% -> 17.0%       4.8% -> 8.8%   -0.23 pp   +0.76 pp   +0.53 pp   0.031
#>      5 [644.5, Inf)               19.9% -> 12.1%       3.7% -> 3.6%   -0.28 pp   -0.02 pp   -0.30 pp   0.936
#>     band          label  pct_base   pct_cmp    mix_effect   rate_effect
#>    <int>         <char>     <num>     <num>         <num>         <num>
#> 1:     1  [-Inf, 556.5) 0.2013333 0.2876667  0.0365026699  0.0108306635
#> 2:     2 [556.5, 586.5) 0.1983333 0.2306667  0.0072402119  0.0124264548
#> 3:     3 [586.5, 611.5) 0.1986667 0.1913333 -0.0008872565  0.0098872565
#> 4:     4 [611.5, 644.5) 0.2030000 0.1696667 -0.0022671282  0.0076004615
#> 5:     5   [644.5, Inf) 0.1986667 0.1206667 -0.0028401498 -0.0001598502
```
