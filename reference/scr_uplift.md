# Uplift of a treatment along a score

Reads a score on a treated and a control group (a campaign with a
hold-out): the difference of the event rates per score band with its
interval, the incremental events, the Qini and uplift curves with their
areas, and a check that the two groups have the same score distribution.

## Usage

``` r
scr_uplift(x, ...)

# S3 method for class 'data.frame'
scr_uplift(
  x,
  score = "score",
  y = "y",
  treat = "treat",
  n_bands = 10L,
  cuts = NULL,
  level = 0.95,
  n_boot = 200L,
  seed = NULL,
  objective = "propensity",
  direction = NULL,
  weight = NULL,
  max_cells = 1e+05,
  boot_cells = 10000,
  ...
)
```

## Arguments

- x:

  A `data.frame` with one row per case.

- ...:

  Passed on to the methods; an unknown argument is an error.

- score, y, treat:

  Column names of the score, of the 0/1 outcome (`NA` allowed) and of
  the 0/1 or logical treatment indicator (1 = treated).

- n_bands:

  Equal-share bands of the score when `cuts` is not given.

- cuts:

  Optional ascending cuts of the score, or an object from
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
  or
  [`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md),
  whose cuts, numbers and labels are then used, with its objective and
  direction.

- level:

  Confidence level of the intervals.

- n_boot:

  Bootstrap resamples of the Qini and AUUC intervals (`0` skips them).

- seed:

  Seed of the bootstrap. A number is local to the call (the user's
  random stream is restored on exit); `NULL` draws from the user's
  stream and advances it. For a scorecard, `NULL` uses `config$seed`.

- objective:

  `"propensity"` (default: the event is the outcome sought, and a higher
  score means a higher propensity) or `"risk"`.

- direction:

  `"higher_is_safer"` or `"higher_is_riskier"`; `NULL` derives it from
  `objective`.

- weight:

  Optional column of non-negative case weights.

- max_cells:

  Largest number of distinct score values kept exactly.

- boot_cells:

  Largest number of score cells resampled exactly by the bootstrap
  (default 10,000; `Inf` for no pooling). See the section Method.

## Value

An object of class `c("scr_uplift", "list")`:

- `table`:

  One row per band, event-richest first: `band`, `label`, `score_lo`,
  `score_hi`, `n_t`, `n_c`, `events_t`, `events_c`, `rate_t`, `rate_c`,
  `uplift`, `uplift_lo`, `uplift_hi`, `incremental`, `cum_incremental`,
  `cum_pct_treated` and `type`.

- `summary`:

  One row: `n_t`, `n_c`, `rate_t`, `rate_c`, `uplift`, `uplift_lo`,
  `uplift_hi`, `qini`, `qini_lo`, `qini_hi`, `auuc`, `auuc_lo`,
  `auuc_hi`, `psi`, `psi_critical` and `psi_flag`.

- `curve`:

  The curves, at most about 1,000 rows spread evenly in the treated
  share (the areas use every cell): `cut` (the score boundary),
  `pct_treated`, `pct_all`, `n_t`, `n_c`, `qini`, `qini_random` (the
  straight line) and `uplift`.

- `randomization`:

  A list: `psi`, `critical`, `flag` and `note`.

- `cuts`, `codes`, `labels`, `level`, `n_boot`, `objective`,
  `direction`, `score`, `target`, `treat`, `weighted`, `call`:

  The cuts and the settings.

## Bands

The bands are cut on the score of both arms together, tie-safe as in
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
the event-richest end first (`band = 1`). Per band, with \\n_t\\,
\\n_c\\ the rows with a known outcome and \\r_t\\, \\r_c\\ the event
rates of the treated and of the control:

- `uplift` = \\r_t - r_c\\, with the Newcombe hybrid score interval:
  from the Wilson intervals \\\[l_t, u_t\]\\ and \\\[l_c, u_c\]\\ of the
  two rates, \$\$lo = r_t - r_c - \sqrt{(r_t - l_t)^2 + (u_c - r_c)^2},
  \qquad hi = r_t - r_c + \sqrt{(u_t - r_t)^2 + (r_c - l_c)^2}.\$\$
  Under weights the Wilson intervals use the Kish effective sizes.

- `incremental` = `uplift` \\\times n_t\\: the events of the treated
  that the treatment added; `cum_incremental` is its running sum from
  the first band (a band with an empty arm adds nothing) and
  `cum_pct_treated` the cumulative share of the treated.

- `type`, a convention of this package: `"persuadable"` when the
  interval lies above 0, `"negative"` when it lies below, `"no effect"`
  when it covers 0.

## Qini and AUUC

The score cells are accumulated from the event-rich end. With
\\E_t(k)\\, \\E_c(k)\\ the cumulative events and \\N_t(k)\\, \\N_c(k)\\
the cumulative rows of each arm after \\k\\ cells:

- the Qini curve is \\Q(k) = E_t(k) - E_c(k) N_t(k) / N_c(k)\\ (the
  second term is 0 while no control row is in), read against \\N_t(k)\\;

- `qini` is the area between the Qini curve and the straight line from
  the origin to its end point, by trapezoids from the origin, divided by
  the square of the treated volume: \$\$qini = \frac{1}{N_t^2} \sum_k
  \frac{Q(k-1) + Q(k)}{2} (N_t(k) - N_t(k-1)) - \frac{Q(K)}{2 N_t}.\$\$
  It is 0 for a score that orders at random and positive when the
  incremental events come first;

- the uplift curve is \\U(k) = (E_t(k) / N_t(k) - E_c(k) / N_c(k))
  (N_t(k) + N_c(k)) / N\\ (an arm with no row yet has rate 0), read
  against the cumulative share of all rows \\(N_t(k) + N_c(k)) / N\\;
  `auuc` is the area under it by trapezoids from the origin. A score
  that orders at random gives about half the overall uplift.

Rows with a missing outcome are left out of the rates and of the curves.

`qini` is not Radcliffe's Q, which divides the same area by that of an
ideal curve; here the area is divided by \\N_t^2\\ only, so it reads as
incremental events per treated row, averaged over the depth.

The intervals of `qini` and `auuc` are percentile intervals of a
bootstrap on the counts, stratified by arm: each resample draws, for the
treated and for the control separately, the counts per score cell and
outcome from one multinomial law with the observed shares and the
unweighted size of the arm, the law of a row bootstrap within each arm.
The event totals of the arms vary from one resample to the next, so the
intervals carry the uncertainty of the overall uplift as well as that of
the ordering. Above `boot_cells` cells the resamples run on pooled cells
and are shifted to the point estimates, as in
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md).
A given `seed` is local to the call.

## Randomization check

Under a randomized assignment the score has the same distribution in
both arms. `randomization` holds the PSI of the treated against the
control over the bands, with the n-adjusted critical value at
`1 - level` (see
[`scr_psi()`](https://evandeilton.github.io/scorecraft/reference/scr_psi.md));
when the PSI exceeds it, `flag` is `TRUE` and `note` says so: the arms
then differ along the score and the uplift may reflect the assignment,
not the treatment.

## References

Newcombe, R. G. (1998). Interval estimation for the difference between
independent proportions: comparison of eleven methods. *Statistics in
Medicine*, 17(8), 873-890.

Radcliffe, N. J. (2007). Using control groups to target on predicted
lift: building and assessing uplift models. *Direct Marketing Analytics
Journal*, 1, 14-21.

Yurdakul, B. and Naranjo, J. (2020). Statistical properties of the
population stability index. *Journal of Risk Model Validation*, 14(4),
89-100.

## See also

[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
for the bands,
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md)
for the cut of a campaign under a budget.

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
[`scr_segments()`](https://evandeilton.github.io/scorecraft/reference/scr_segments.md),
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)

## Examples

``` r
local({
  set.seed(1)
  n <- 8000
  x <- rnorm(n)
  treat <- rbinom(n, 1, 0.5)
  # the offer works on the customers with a high score only
  d <- data.frame(score = round(500 + 50 * x), treat = treat,
                  y = rbinom(n, 1, plogis(-1.5 + 0.5 * x + treat * pmax(x, 0))))
  up <- scr_uplift(d, n_bands = 5, n_boot = 50, seed = 1)
  print(up)
  up$summary[, c("uplift", "qini", "qini_lo", "qini_hi", "auuc")]
})
#> <scr_uplift> outcome "y" | treatment "treat" | objective propensity | higher_is_riskier
#>   treated 3,956 (rate 27.2%) | control 4,044 (rate 18.8%) | uplift +8.38 pp [+6.54 pp, +10.21 pp]
#>   Qini 0.0314 [0.0276, 0.0358] | AUUC 0.0738 [0.0644, 0.0871] (95% bootstrap intervals, 50 resamples)
#>   randomization: PSI of the treated against the control 0.0034 (critical 0.0047)
#> 
#> Bands (event-richest first; 95% Newcombe interval of the uplift)
#>   band score                        n_t       n_c   rate_t   rate_c uplift [lo, hi]                    incremental      cum  type
#>      1 [543.5, Inf)                 758       845    62.1%    29.8% +32.31 pp [+27.59 pp, +36.83 pp]         244.9    244.9  persuadable
#>      2 [512.5, 543.5)               774       796    34.1%    22.4% +11.75 pp [+7.30 pp, +16.13 pp]           90.9    335.9  persuadable
#>      3 [486.5, 512.5)               822       805    17.2%    15.3% +1.87 pp [-1.72 pp, +5.46 pp]             15.4    351.3  no effect
#>      4 [457.5, 486.5)               820       772    14.8%    15.0% -0.27 pp [-3.79 pp, +3.23 pp]             -2.2    349.1  no effect
#>      5 [-Inf, 457.5)                782       826    10.0%    11.0% -1.04 pp [-4.05 pp, +1.98 pp]             -8.2    340.9  no effect
#>        uplift       qini    qini_lo    qini_hi       auuc
#>         <num>      <num>      <num>      <num>      <num>
#> 1: 0.08380639 0.03137835 0.02757451 0.03584169 0.07383066
```
