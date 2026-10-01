# Two scores on the same rows

Crosses two scores read on the same rows (a credit score and a churn
score, a champion and a challenger): the cross table of their bands with
the event rate of one or two outcomes, the rank association of the
scores, and the overlap of the rows each one selects at a few depths,
with the swap-in and swap-out sets.

## Usage

``` r
scr_score_cross(x, ...)

# S3 method for class 'data.frame'
scr_score_cross(
  x,
  score_a,
  score_b,
  y = NULL,
  y_a = NULL,
  y_b = NULL,
  objective_a = "risk",
  objective_b = NULL,
  direction_a = NULL,
  direction_b = NULL,
  n_bands = 5L,
  cuts_a = NULL,
  cuts_b = NULL,
  depths = c(0.05, 0.1, 0.2),
  weight = NULL,
  level = 0.95,
  ...
)
```

## Arguments

- x:

  A `data.frame` with both scores on every row.

- ...:

  Not used; an unknown argument is an error.

- score_a, score_b:

  Column names of the two scores.

- y:

  Column name of a 0/1 outcome read under both scores.

- y_a, y_b:

  Instead of `y`: the outcome of score A and of score B (two different
  targets on the same rows); either may be given alone.

- objective_a, objective_b:

  `"risk"` or `"propensity"`; `objective_b = NULL` takes `objective_a`.
  A study given as cuts sets the objective of its score.

- direction_a, direction_b:

  `"higher_is_safer"` or `"higher_is_riskier"`; `NULL` derives each from
  its objective, or takes it from the study given as cuts.

- n_bands:

  Bands of each score when its cuts are not given.

- cuts_a, cuts_b:

  Optional cuts of each score: a numeric vector, or an object from
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
  or
  [`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md),
  which also sets the objective and the direction of that score.

- depths:

  Shares of the rows selected by each score for the overlap, in (0, 1\].

- weight:

  Optional column of non-negative case weights.

- level:

  Confidence level of the Jeffreys intervals.

## Value

An object of class `c("scr_score_cross", "list")`:

- `table`:

  The cross table: `band_a`, `label_a`, `band_b`, `label_b`, `n`, `pct`
  and the outcome columns (see the section Cross table).

- `overlap`:

  One row per depth: `depth`, `cut_a`, `cut_b`, `share_a`, `share_b`,
  `n_a`, `n_b`, `n_both`, `n_a_only`, `n_b_only` and `jaccard`.

- `overlap_rates`:

  With an outcome, one row per depth, outcome and set (`"A"`, `"B"`,
  `"both"`, `"A only"`, `"B only"`): `n`, `events`, `rate`, `rate_lo`
  and `rate_hi`.

- `association`:

  One row per method (`"spearman"`, `"kendall_tau_b"`): `estimate`,
  `oriented` and `n`.

- `settings`:

  A list: the score and outcome columns, objectives, directions, cuts,
  codes and labels of both scores, `depths`, `level`, `n` (the volume
  used: the sum of the weights, the number of rows without weights),
  `n_rows` (the rows used), `n_dropped` (rows left out) and `weighted`.

## Bands

Each score is cut into `n_bands` bands of equal share, tie-safe as in
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
(band 1 is the event-richest), unless `cuts_a` or `cuts_b` gives the
cuts: a numeric vector, or an object from
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
or
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md),
whose cuts, numbers and labels are then used (the tier labels for
tiers). Bands are left-closed, `score >= cut` being the upper side.

A study given as cuts also sets the objective and the direction of its
score, so the event-rich end of the overlap is the one the study was
fitted with. `objective_a`, `direction_a` (or their `_b` counterparts)
need not be given then; when given and different from the study, the
call is an error.

## Cross table

One row per pair of bands, every pair listed (empty ones with `n = 0`),
then the totals of each band of A (`band_b` missing,
`label_b = "total"`), of each band of B, and the grand total. Per row:
`n`, `pct` (share of all rows) and, for every outcome, `events`, `rate`
with its Jeffreys interval `rate_lo`, `rate_hi` (on the Kish effective
size under weights) and `lift` (the rate over the overall rate of that
outcome). With `y` the outcome columns have no suffix; with `y_a` and
`y_b` they end in `_a` and `_b`.

## Association

Spearman's rank correlation (Pearson on mid-ranks, as
`cor(method = "spearman")`) and Kendall's tau-b (pairs tied on either
score count neither way, as `cor(method = "kendall")`), both on the raw
scores and unweighted. The tau-b counts are exact, by Knight's (1966)
algorithm in `O(n log n)`. `oriented` multiplies each estimate by the
signs of the two directions, so it is positive when the two scores put
the same rows at their event-rich ends.

## Overlap

At each depth, each score selects the share `depth` of the rows from its
event-rich end (tie-safe: the selection stops at the boundary between
two distinct scores nearest to the target, so the share selected can
differ from `depth` by the share of one score value; `share_a` and
`share_b` report it). `overlap` counts the rows selected by A, by B, by
both, by A only and by B only, and the Jaccard index
`n_both / (n_a + n_b - n_both)`. With an outcome, `overlap_rates` gives
the event rate of each of the five sets with its Jeffreys interval: when
B replaces A at the same depth, `"B only"` is the swap-in and `"A only"`
the swap-out.

Rows with a missing or infinite value of either score, or a zero weight,
are left out (`n_dropped`); rows with a missing outcome count in the
volume but not in the rates of that outcome.

## References

Brown, L. D., Cai, T. T. and DasGupta, A. (2001). Interval estimation
for a binomial proportion. *Statistical Science*, 16(2), 101-133.
[doi:10.1214/ss/1009213286](https://doi.org/10.1214/ss/1009213286)

Knight, W. R. (1966). A computer method for calculating Kendall's tau
with ungrouped data. *Journal of the American Statistical Association*,
61(314), 436-439.
[doi:10.1080/01621459.1966.10480879](https://doi.org/10.1080/01621459.1966.10480879)

## See also

[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
and
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)
for the cuts of each score.

Other score-studies:
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md),
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md),
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md),
[`scr_rag_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_rag_plan.md),
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)

## Examples

``` r
set.seed(1)
n <- 4000
z <- rnorm(n)
d <- data.frame(credit = round(600 + 40 * (-z + rnorm(n, sd = 0.6))),
                churn = round(450 + 30 * (0.4 * z + rnorm(n))),
                default = rbinom(n, 1, plogis(-2 + z)),
                left = rbinom(n, 1, 0.3))
cx <- scr_score_cross(d, "credit", "churn", y_a = "default", y_b = "left",
                      objective_b = "propensity", n_bands = 4)
cx
#> <scr_score_cross> A "credit" (risk, higher_is_safer) | B "churn" (propensity, higher_is_riskier)
#>   4,000 rows | outcomes: default, left | bands: A equal shares, B equal shares
#>   association (raw scores): Spearman -0.323, Kendall tau-b -0.221 | oriented to the event-rich ends: 0.323, 0.221
#> 
#> Share of rows
#>   A \ B                           B1        B2        B3        B4     total
#>   A1 [-Inf, 567.5)              9.8%      7.6%      4.2%      3.2%     24.7%
#>   A2 [567.5, 599.5)             6.5%      6.9%      6.6%      5.0%     25.0%
#>   A3 [599.5, 631.5)             5.6%      5.8%      7.2%      7.0%     25.6%
#>   A4 [631.5, Inf)               3.3%      4.9%      6.6%      9.9%     24.7%
#>   total                        25.1%     25.2%     24.6%     25.1%    100.0%
#> 
#> Event rate of "default"
#>   A \ B                           B1        B2        B3        B4     total
#>   A1 [-Inf, 567.5)             34.8%     33.3%     28.0%     26.0%     32.1%
#>   A2 [567.5, 599.5)            18.9%     16.6%     11.4%     13.0%     15.1%
#>   A3 [599.5, 631.5)             9.0%     10.9%      9.0%     11.8%     10.2%
#>   A4 [631.5, Inf)               6.1%      5.6%      4.5%      5.3%      5.3%
#>   total                        21.2%     18.2%     11.7%     11.3%     15.6%
#> 
#> Event rate of "left"
#>   A \ B                           B1        B2        B3        B4     total
#>   A1 [-Inf, 567.5)             28.1%     30.4%     34.5%     25.2%     29.5%
#>   A2 [567.5, 599.5)            29.7%     27.8%     30.3%     33.5%     30.1%
#>   A3 [599.5, 631.5)            29.1%     26.5%     31.1%     27.5%     28.7%
#>   A4 [631.5, Inf)              38.2%     31.0%     33.6%     31.1%     32.7%
#>   total                        30.1%     28.9%     32.2%     29.8%     30.2%
#>   B bands: B1 [471.5, Inf), B2 [449.5, 471.5), B3 [427.5, 449.5), B4 [-Inf, 427.5)
#> 
#> Overlap (each score selects from its event-rich end)
#>    depth  share_a  share_b       n_a       n_b      both    A only    B only  Jaccard
#>     5.0%     4.9%     4.9%       196       196        34       162       162    0.095
#>    10.0%    10.1%    10.0%       405       398       100       305       298    0.142
#>    20.0%    20.2%    20.4%       807       817       285       522       532    0.213
#> 
#> Event rate of each set (B only = swap-in, A only = swap-out)
#>    depth outcome              A         B      both    A only    B only
#>     5.0% default          50.0%     25.0%     52.9%     49.4%     19.1%
#>    10.0% default          42.7%     26.4%     47.0%     41.3%     19.5%
#>    20.0% default          35.2%     22.6%     38.9%     33.1%     13.9%
#>     5.0% left             32.1%     28.1%     29.4%     32.7%     27.8%
#>    10.0% left             31.1%     30.2%     31.0%     31.1%     29.9%
#>    20.0% left             30.1%     29.7%     27.0%     31.8%     31.2%
cx$association
#>           method   estimate  oriented     n
#>           <char>      <num>     <num> <int>
#> 1:      spearman -0.3226129 0.3226129  4000
#> 2: kendall_tau_b -0.2208241 0.2208241  4000
cx$overlap_rates[cx$overlap_rates$depth == 0.1, ]
#>     depth outcome    set     n events      rate   rate_lo   rate_hi
#>     <num>  <char> <char> <num>  <num>     <num>     <num>     <num>
#>  1:   0.1 default      A   405    173 0.4271605 0.3796446 0.4757133
#>  2:   0.1 default      B   398    105 0.2638191 0.2223441 0.3087148
#>  3:   0.1 default   both   100     47 0.4700000 0.3742005 0.5675083
#>  4:   0.1 default A only   305    126 0.4131148 0.3588898 0.4689800
#>  5:   0.1 default B only   298     58 0.1946309 0.1527520 0.2424073
#>  6:   0.1    left      A   405    126 0.3111111 0.2674907 0.3574203
#>  7:   0.1    left      B   398    120 0.3015075 0.2579825 0.3479075
#>  8:   0.1    left   both   100     31 0.3100000 0.2257483 0.4050706
#>  9:   0.1    left A only   305     95 0.3114754 0.2614699 0.3650397
#> 10:   0.1    left B only   298     89 0.2986577 0.2488281 0.3523768
```
