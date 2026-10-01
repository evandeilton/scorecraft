# Operating point of a score under constraints

Accumulates the score from one end, one score value at a time, and finds
the cut that maximizes the value of the decision under volume, budget,
daily capacity and event-rate constraints: how many customers to target,
how many alerts to raise, or how many applicants to approve.

## Usage

``` r
scr_operating(x, ...)

# S3 method for class 'scr_scorecard'
scr_operating(
  x,
  side = NULL,
  gain_event = NULL,
  cost_select = 0,
  revenue_good = NULL,
  loss_bad = NULL,
  max_n = NULL,
  max_share = NULL,
  budget = NULL,
  max_per_day = NULL,
  day_quantile = 0.9,
  date = NULL,
  min_rate = NULL,
  max_rate = NULL,
  sample = "holdout",
  n_points = 200L,
  level = NULL,
  max_cells = 1e+05,
  ...
)

# S3 method for class 'data.frame'
scr_operating(
  x,
  side = NULL,
  gain_event = NULL,
  cost_select = 0,
  revenue_good = NULL,
  loss_bad = NULL,
  max_n = NULL,
  max_share = NULL,
  budget = NULL,
  max_per_day = NULL,
  day_quantile = 0.9,
  date = NULL,
  min_rate = NULL,
  max_rate = NULL,
  sample = NULL,
  n_points = 200L,
  score = "score",
  y = "y",
  objective = "risk",
  direction = NULL,
  weight = NULL,
  value = NULL,
  study = NULL,
  counts = FALSE,
  n = "n",
  events = "events",
  value_events = NULL,
  level = 0.95,
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

- side:

  `"event"` or `"safe"`; `NULL` follows the objective and the direction
  (see the section Side).

- gain_event:

  Gain per selected event (side `"event"`).

- cost_select:

  Cost per selected case (default 0).

- revenue_good, loss_bad:

  Revenue per accepted non-event and loss per accepted event (side
  `"safe"`).

- max_n:

  Largest volume selected.

- max_share:

  Largest share of the volume selected, in (0, 1\].

- budget:

  Largest cost, `cost_select * n_sel`; needs a positive `cost_select`.

- max_per_day:

  Largest selected volume per day, read at the `day_quantile` quantile
  of the days; needs a date.

- day_quantile:

  Quantile of the daily volume compared with `max_per_day` (0.9: nine
  days in ten within capacity).

- date:

  For a data.frame: name of a date column, for the daily capacity. For a
  scorecard: a column of the scored sample; `NULL` uses its `date`
  column when present.

- min_rate:

  Smallest event rate among the selected (side `"event"`).

- max_rate:

  Largest event rate among the accepted (side `"safe"`).

- sample:

  For a scorecard: the sample the curve is read on (`"holdout"`). For a
  data.frame: the name of a column with sample labels, as in
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md);
  the curve is read on `study`.

- n_points:

  About how many rows of the curve to keep.

- level:

  Confidence level of the Jeffreys intervals. For a scorecard, `NULL`
  uses `config$study_level` (0.95).

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

- value:

  Optional column of the value of every case: with no `gain_event`, the
  value of the selected events is the gain.

- study:

  For a data.frame: the label of the sample the curve is read on; `NULL`
  takes the first label other than the first level (the reference of
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)),
  or the only one.

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

An object of class `c("scr_operating", "list")`:

- `curve`:

  The thinned curve (see the section Curve).

- `optimum`:

  One row: the columns of the curve at the optimum, `binding`,
  `shadow_price` and `next_rate` (the marginal rate of the next score
  value).

- `constraints`:

  One row per constraint given: `constraint`, `limit`, `at_optimum` (the
  constrained quantity at the optimum) and `binding`.

- `side`, `objective`, `direction`, `target`, `sample`, `level`,
  `gain_event`, `cost_select`, `revenue_good`, `loss_bad`,
  `day_quantile`, `call`:

  The settings.

- `economics`, `value_column`:

  Whether the curve has a value, and whether it comes from the `value`
  column instead of `gain_event`.

- `select_high`:

  `TRUE` when the selection starts at the high scores (`score >= cut`),
  `FALSE` at the low ones (`score < cut`).

- `n_cells`, `n_days`, `quantized`, `weighted`:

  The number of candidate cuts (score values or pooled cells), the
  number of distinct dates (`NA` without a date), whether the scores
  were pooled into `max_cells` cells, and whether weights were used.

- `message`:

  `NA`, or the explanation of an infeasible or a loss-making optimum.

## Side

`side = "event"` selects from the event-rich end of the score (targeting
under propensity, alerting under fraud, collections under credit);
`side = "safe"` accepts from the safe end (approval under credit). The
default follows the objective and the direction: propensity selects from
the event-rich end (`"event"`); risk with `higher_is_riskier` (fraud)
alerts from the event-rich end (`"event"`); risk with `higher_is_safer`
(credit) approves from the safe end (`"safe"`).

The selected rows are `score >= cut` when the selection starts at the
high scores and `score < cut` when it starts at the low ones, the
convention of
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md).
Every cut sits between two adjacent distinct scores (or on a bucket edge
when the scores were pooled into `max_cells` cells), as in
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md);
the last row of the curve selects every row (`cut` is `-Inf` or `Inf`).

## Curve

One row per candidate cut, in increasing depth: `cut`, `depth` (share of
the volume selected), `n_sel`, `events_sel`, `rate_sel` with its
Jeffreys interval `rate_lo`, `rate_hi` (on the Kish effective size under
weights), `capture` (share of all events selected), `lift` (`rate_sel`
over the overall rate), `marginal_rate` (the event rate of the score
value just added, smoothed by pool adjacent violators toward the
event-rich end of the score), `cost` (`cost_select * n_sel`), `value`
and `feasible`. With a date, `day_q` (the `day_quantile` quantile of the
selected volume per day) and `pct_days_over` (share of days above
`max_per_day`).

The economics:

- side `"event"`:
  `value = gain_event * events_sel - cost_select * n_sel`; with a
  `value` column and no `gain_event`, the sum of the value of the
  selected events replaces `gain_event * events_sel`.

- side `"safe"`:
  `value = revenue_good * nonevents_sel - loss_bad * events_sel - cost_select * n_sel`,
  the cumulative profit of
  [`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md)
  when `cost_select = 0` (a missing one of `revenue_good` and `loss_bad`
  counts as 0).

Without economics (`gain_event`, a `value` column, `revenue_good` or
`loss_bad`), `value` is `NA`. Non-events are rows with a known outcome
that are not events; rows with a missing outcome count in the volume and
the cost only.

The curve is thinned to about `n_points` rows evenly spread in depth;
the rows of the optimum, the last row meeting each constraint, the
deepest row and the rows nearest 1%, 5%, 10%, 20% and 50% are always
kept. The optimum and the constraints are evaluated on every cell
boundary.

## Constraints and optimum

`max_n` (`n_sel <= max_n`), `max_share` (`depth <= max_share`), `budget`
(`cost_select * n_sel <= budget`), `max_per_day`
(`day_q <= max_per_day`), `min_rate` (`rate_sel >= min_rate`, side
`"event"`) and `max_rate` (`rate_sel <= max_rate`, the event rate among
the accepted, side `"safe"`). A row is feasible when it meets every
constraint given.

The optimum is the feasible row with the highest value (the smallest
depth on a tie); without economics, the deepest feasible row. A
constraint is `binding` when dropping it alone, the others kept,
improves the optimum: a higher value, or a greater depth when there are
no economics. A constraint that is slack at the optimum is therefore
never named, and a constraint that stops the curve at the row that is
the best anyway is not binding either. Constraints that stop the optimum
at the same row bind jointly (none improves it alone) and are named
together. When no constraint binds, `binding` is `"value"` with
economics (no row is worth more than the optimum) and
`"end of the curve"` without (every row is selected). `shadow_price` is
the marginal value of the next score value beyond the optimum, per
additional selected case: `gain_event * marginal_rate - cost_select` on
side `"event"` (with a `value` column, the smoothed event value per case
of that score value),
`revenue_good * (1 - marginal_rate) - loss_bad * marginal_rate - cost_select`
on side `"safe"`. It is what one more selected case is worth when a
constraint binds; divide it by `cost_select` for the value of one more
unit of budget. When no row is feasible, the optimum is `NA` and a
warning names the constraints that the first row already breaks.

## Daily capacity

A day is a distinct value of the date column: with a monthly date, read
the capacity per month. For every candidate cut, the selected volume of
each day is a cumulative sum over a table of counts per day and score
value; `day_q` is its quantile across the days (type 7 of
[`stats::quantile()`](https://rdrr.io/r/stats/quantile.html)). The
quantile grows with the depth, so the deepest cut within `max_per_day`
is found by bisection. Rows with a missing date count in the curve but
not in the daily volumes. A scorecard uses the dates of its scored
sample when they exist. A date-time column counts every distinct time as
a day: convert it with
[`as.Date()`](https://rdrr.io/r/base/as.Date.html) first.

## References

Brown, L. D., Cai, T. T. and DasGupta, A. (2001). Interval estimation
for a binomial proportion. *Statistical Science*, 16(2), 101-133.
[doi:10.1214/ss/1009213286](https://doi.org/10.1214/ss/1009213286)

Thomas, L. C., Crook, J. and Edelman, D. (2017). *Credit Scoring and Its
Applications*, 2nd edition. SIAM.
[doi:10.1137/1.9781611974560](https://doi.org/10.1137/1.9781611974560)

## See also

[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md)
and
[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md)
for the cut-off sweep and the strategy table of a scorecard,
[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md)
to test statements about the selected rates.

Other score-studies:
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md),
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md),
[`scr_rag_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_rag_plan.md),
[`scr_score_cross()`](https://evandeilton.github.io/scorecraft/reference/scr_score_cross.md),
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)

## Examples

``` r
set.seed(1)
x <- rnorm(5000)
d <- data.frame(score = round(500 + 50 * x),
                y = rbinom(5000, 1, plogis(-1.5 + 1.2 * x)),
                day = as.Date("2026-01-01") + sample(0:29, 5000, TRUE))
# targeting under propensity: a gain per responder, a cost per contact, a budget
op <- scr_operating(d, objective = "propensity", gain_event = 40, cost_select = 6,
                    budget = 6000)
op
#> <scr_operating> target "y" | objective propensity | higher_is_riskier | side event (from the high scores, score >= cut)
#>   sample 'all' | 288 score values | economics: gain 40 per event, cost 6
#>   constraints: budget 6,000
#> 
#> Optimum: cut 544.5 | depth 19.8% (n 989) | rate 55.5% [52.4%, 58.6%] | capture 47.0% | value 16,026
#>   binding: budget | shadow price 9.693 per additional case | next marginal rate 39.2%
#> 
#> Curve (selected rows)
#>     depth          cut      n_sel rate [lo, hi]             capture   lift  marginal          value feasible
#>      1.0%        615.5         50 86.0% [74.5%, 93.5%]         3.7%   3.68     84.8%          1,420      yes
#>      5.0%        584.5        252 71.8% [66.0%, 77.1%]        15.5%   3.07     61.0%          5,728      yes
#>     10.2%        565.5        510 63.7% [59.5%, 67.8%]        27.8%   2.73     51.9%          9,940      yes
#>     19.8%        544.5        989 55.5% [52.4%, 58.6%]        47.0%   2.37     39.2%         16,026      yes  <- optimum
#>     20.2%        543.5      1,011 55.1% [52.0%, 58.1%]        47.6%   2.36     39.2%         16,214       no
#>     49.7%        499.5      2,484 38.6% [36.7%, 40.5%]        82.0%   1.65     18.6%         23,456       no
#>    100.0%         -Inf      5,000 23.4% [22.2%, 24.6%]       100.0%   1.00      0.0%         16,760       no
op$optimum[, c("cut", "depth", "n_sel", "rate_sel", "value", "binding", "shadow_price")]
#>      cut  depth n_sel  rate_sel value binding shadow_price
#>    <num>  <num> <num>     <num> <num>  <char>        <num>
#> 1: 544.5 0.1978   989 0.5551062 16026  budget     9.693215

# alerting under a daily capacity: at most 40 alerts on nine days in ten
scr_operating(d, objective = "propensity", max_per_day = 40, date = "day")$optimum
#>      cut  depth n_sel events_sel  rate_sel rate_lo   rate_hi   capture     lift
#>    <num>  <num> <num>      <num>     <num>   <num>     <num>     <num>    <num>
#> 1: 546.5 0.1854   927        526 0.5674218 0.53536 0.5990633 0.4499572 2.426954
#>    marginal_rate  cost value feasible day_q pct_days_over     binding
#>            <num> <num> <num>   <lgcl> <num>         <num>      <char>
#> 1:     0.4318182     0    NA     TRUE  38.2    0.03333333 max_per_day
#>    shadow_price next_rate
#>           <num>     <num>
#> 1:           NA 0.3923304
```
