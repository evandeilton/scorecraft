# Maturity of the event by score band

Follows the units of each score band over time and estimates, at each
horizon, the cumulative share that has had the event, allowing for units
whose follow-up ends before the horizon (censoring). It shows how fast
each band matures, where the curve flattens (the performance window) and
how the discrimination of the score changes with the horizon.

## Usage

``` r
scr_maturity(x, ...)

# S3 method for class 'data.frame'
scr_maturity(
  x,
  score = "score",
  time = "time",
  event = "event",
  horizons,
  objective = "risk",
  direction = NULL,
  n_bands = 5L,
  cuts = NULL,
  level = 0.95,
  weight = NULL,
  max_cells = 1e+05,
  ...
)
```

## Arguments

- x:

  A `data.frame` with one row per unit.

- ...:

  Passed on to the methods; an unknown argument is an error.

- score, time, event:

  Column names of the score, of the time to the event or to the end of
  the follow-up, and of the 0/1 event indicator.

- horizons:

  Times at which the incidence is read, in the unit of `time` (positive
  numbers).

- objective:

  `"risk"` (the event is the bad case) or `"propensity"` (the event is
  the good case).

- direction:

  `"higher_is_safer"` or `"higher_is_riskier"`; `NULL` derives it from
  `objective`.

- n_bands:

  Equal-share bands of the score (tie-safe, the event-richest first)
  when `cuts` is not given.

- cuts:

  Optional ascending cuts of the score, or an object from
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
  or
  [`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md),
  whose cuts, numbers and labels are then used, with its objective and
  direction.

- level:

  Confidence level of the intervals.

- weight:

  Optional column of non-negative case weights.

- max_cells:

  Largest number of distinct score values kept exactly.

## Value

An object of class `c("scr_maturity", "list")`:

- `table`:

  One row per band and horizon, event-richest band first, then all units
  (`band = NA`, `label = "all"`): `band`, `label`, `n`, `horizon`,
  `at_risk`, `events`, `censored`, `incidence`, `se`, `lo`, `hi` and
  `pct_of_final`.

- `discrimination`:

  One row per horizon: `horizon`, `n` (units with a complete window),
  `events`, `auc` and `gini`.

- `cuts`, `codes`, `labels`:

  The ascending cuts, and the band number and label of every interval in
  ascending score order.

- `horizons`, `level`, `objective`, `direction`, `score`, `time`,
  `event`, `n`, `n_rows`, `n_dropped`, `weighted`, `call`:

  The settings: `n` is the volume used (the sum of the weights),
  `n_rows` the rows used and `n_dropped` those left out.

## Data

One row per unit (a loan, a customer), with the score at the origin,
`time` and `event`:

- `time`:

  A non-negative number of periods (days, months) from the origin to the
  event, or to the end of the follow-up.

- `event`:

  1 when the event was observed at `time`, 0 when the follow-up ended
  there without it (censored).

From a monthly panel, take per unit the months from its opening date to
its first month in default (`event = 1`), or to its last observed month
when it never defaulted (`event = 0`); the example does it for
[scr_demo_panel](https://evandeilton.github.io/scorecraft/reference/scr_demo_panel.md).

Rows with a missing or infinite score, a missing time or event, or a
zero weight are left out (`n_dropped`).

## Incidence

Per band and for all units, the Kaplan-Meier estimate of the survival is
\\S(t) = \prod\_{t_j \le t} (1 - d_j / n_j)\\, with \\d_j\\ the events
at the distinct time \\t_j\\ and \\n_j\\ the units still followed just
before it (units censored at \\t_j\\ are at risk at \\t_j\\).
`incidence` is \\1 - S(h)\\ at the horizon \\h\\, and `se` its standard
error by Greenwood's formula, \\S(h) \sqrt{\sum\_{t_j \le h} d_j / (n_j
(n_j - d_j))}\\. The interval `lo`, `hi` is the complementary log-log
interval of \\S(h)\\, \\S^{\exp(\pm z \sigma)}\\ with \\\sigma =
\sqrt{\sum d_j / (n_j (n_j - d_j))} / \|\ln S\|\\, which stays inside
\[0, 1\]. It is undefined when no event has happened by the horizon
(`lo = 0`, `hi = NA`) and when every unit has had the event (`NA`).

Under weights, \\d_j\\ and \\n_j\\ are weighted sums and each term of
Greenwood's sum is computed on the Kish effective size of the risk set,
\\d_j / ((n_j - d_j)\\ n^{eff}\_j)\\ with \\n^{eff}\_j = n_j^2 / \sum
w^2\\; equal weights give the unweighted result.

Per band and horizon the table also counts `events` (events up to the
horizon), `censored` (units censored before it) and `at_risk` (the other
units: still followed at the horizon without the event), which add up to
`n`. `pct_of_final` is the incidence over the incidence at the largest
horizon: the share of the final events already seen.

Past the last follow-up time of a band nothing more is observed: the
curve is carried flat, and a horizon beyond it repeats the last estimate
with `at_risk = 0`. Read such a row as "no information", not as a
plateau of the event rate.

## Discrimination

At each horizon, the units with a complete window are those with the
event by the horizon and those followed for at least the horizon without
it; units censored earlier are left out. `auc` and `gini` are those of
the score for "event by the horizon" among them, from the counts per
score value. The complete window ignores the censored units, so it is
unbiased only when censoring does not depend on the score.

## References

Greenwood, M. (1926). The natural duration of cancer. *Reports on Public
Health and Medical Subjects*, 33, 1-26. HMSO.

Kalbfleisch, J. D. and Prentice, R. L. (2002). *The Statistical Analysis
of Failure Time Data*, 2nd edition. Wiley.
[doi:10.1002/9781118032985](https://doi.org/10.1002/9781118032985)

Kaplan, E. L. and Meier, P. (1958). Nonparametric estimation from
incomplete observations. *Journal of the American Statistical
Association*, 53(282), 457-481.
[doi:10.1080/01621459.1958.10501452](https://doi.org/10.1080/01621459.1958.10501452)

## See also

[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
and
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)
for the bands,
[`scr_default()`](https://evandeilton.github.io/scorecraft/reference/scr_default.md)
and
[`scr_default_rate()`](https://evandeilton.github.io/scorecraft/reference/scr_default_rate.md)
for the default flag and the cohort rates of a monthly panel.

Other score-studies:
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md),
[`scr_detection()`](https://evandeilton.github.io/scorecraft/reference/scr_detection.md),
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
# time and event from a monthly panel: months from the opening date to
# the first default (90 days past due), or to the last observed month
p <- scr_demo_panel[order(scr_demo_panel$id, scr_demo_panel$ref_date), ]
month <- 12 * as.integer(format(p$ref_date, "%Y")) + as.integer(format(p$ref_date, "%m"))
first <- !duplicated(p$id)
bad <- which(p$dpd >= 90)
bad <- bad[!duplicated(p$id[bad])]
u <- data.frame(id = p$id[first], score = p$score[first], open = month[first])
u$event <- as.integer(u$id %in% p$id[bad])
u$end <- as.vector(tapply(month, p$id, max)[as.character(u$id)])
u$end[u$event == 1] <- month[bad][match(u$id[u$event == 1], p$id[bad])]
u$time <- u$end - u$open

mt <- scr_maturity(u, horizons = c(6, 12, 24, 35), n_bands = 4)
mt
#> <scr_maturity> event "event" over "time" | objective risk | higher_is_safer
#>   600 units | 4 bands (equal shares) | horizons 6, 12, 24, 35 | 95% complementary log-log intervals
#> 
#> Cumulative incidence (Kaplan-Meier), event-richest band first
#>   band score                            n       t=6      t=12      t=24      t=35
#>      1 [-Inf, 556.5)                  149     12.1%     24.2%     47.7%     58.4%
#>      2 [556.5, 603.5)                 150      7.3%     12.0%     27.3%     34.7%
#>      3 [603.5, 643.5)                 150      3.3%      4.0%      8.7%     14.7%
#>      4 [643.5, Inf)                   151    0.662%      3.3%      5.3%     11.3%
#>        all                            600      5.8%     10.8%     22.2%     29.7%
#>        share of the final (all)                 20%       37%       75%      100%
#> 
#> Discrimination at each horizon (units with a complete window)
#>     horizon         n    events      AUC     Gini
#>           6       600        35   0.7492   0.4984
#>          12       600        65   0.7601   0.5202
#>          24       600       133   0.7965   0.5930
#>          35       600       178   0.7692   0.5384
mt$discrimination
#>    horizon     n events       auc      gini
#>      <num> <num>  <num>     <num>     <num>
#> 1:       6   600     35 0.7492035 0.4984071
#> 2:      12   600     65 0.7601006 0.5202013
#> 3:      24   600    133 0.7965014 0.5930028
#> 4:      35   600    178 0.7692103 0.5384206
```
