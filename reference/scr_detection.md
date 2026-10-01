# Time to detection of fraud episodes

Reads a score on transactions grouped by entity (a card, an account, a
device) and measures, for each alert threshold, how many fraud episodes
the score detects, how many fraudulent transactions pass before the
first alert, how long that takes and how much of the loss is prevented.

## Usage

``` r
scr_detection(x, ...)

# S3 method for class 'data.frame'
scr_detection(
  x,
  entity,
  time,
  score = "score",
  y = "y",
  amount = NULL,
  thresholds = NULL,
  alert_shares = NULL,
  direction = "higher_is_riskier",
  max_cells = 1e+05,
  ...
)
```

## Arguments

- x:

  A `data.frame` with one row per transaction.

- ...:

  Not used; an unknown argument is an error.

- entity:

  Name of the column that identifies the entity.

- time:

  Name of the time column: a number, a `Date` or a `POSIXct`.

- score, y:

  Column names of the score and of the 0/1 outcome (1 = a fraudulent
  row).

- amount:

  Optional column of the amount of each row, for the loss.

- thresholds:

  Score thresholds of the alerts.

- alert_shares:

  Shares of all rows to alert, in (0, 1\], turned into thresholds; may
  be given with or instead of `thresholds`.

- direction:

  `"higher_is_riskier"` (default) or `"higher_is_safer"`.

- max_cells:

  Largest number of distinct score values kept exactly in the count
  table of the alert shares.

## Value

An object of class `c("scr_detection", "list")`:

- `table`:

  One row per threshold: `threshold`, `target_share`, `alert_share`,
  `episodes`, `detected`, `pct_detected`, `median_events_before`,
  `mean_events_before`, `median_time`, `loss_before`, `loss_total` and
  `pct_loss_prevented`.

- `episodes`:

  One row per episode: `entity`, `start`, `rows` (from the start),
  `events`, `amount` (of its event rows), `peak_score` (the highest
  score from the start; the lowest under `higher_is_safer`) and, for the
  strictest threshold, `detected`, `detect_time`, `time_to_detect`,
  `events_before` and `loss_before` (`NA` when the episode is not
  detected).

- `direction`, `entity`, `time`, `score`, `target`, `amount`, `n_rows`,
  `n_dropped`, `n_episode_rows`, `call`:

  The settings and the row counts; `n_episode_rows` is the number of
  rows of the episodes, from their starts.

## Episodes

An episode is an entity with at least one event row. It starts at its
first event row in time order (rows at the same time keep their order in
`x`), and the rows of the entity before that start are ignored. At a
threshold \\t\\, the episode is detected at the first row from its start
whose score is on the alert side: `score >= t` under
`higher_is_riskier`, `score < t` under `higher_is_safer`. The detecting
row may be any row of the entity, an event or not.

## Table

One row per threshold, the strictest (fewest alerts) first:

- `alert_share`: the share of **all** rows of `x` on the alert side of
  the threshold, the workload it costs;

- `episodes`, `detected` and `pct_detected`;

- `median_events_before` and `mean_events_before`: the event rows of the
  episode before the detecting row, over the detected episodes (0 when
  the first event row is alerted);

- `median_time`: the median time from the start of the episode to the
  detecting row, in the unit of `time` (days for a `Date`, seconds for a
  `POSIXct`);

- with `amount`: `loss_before`, the amount of the event rows before the
  detecting row, plus the whole amount of the episodes never detected;
  `loss_total`, the amount of every event row; and `pct_loss_prevented`
  = `1 - loss_before / loss_total`. The detecting row and the rows after
  it count as prevented.

`alert_shares` are turned into thresholds on all rows, tie-safe as in
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md):
the boundary between two distinct scores nearest to the share
(`target_share` keeps the share asked for, `alert_share` the one
realized).

Rows with a missing entity or time, or a missing or infinite score, are
left out (`n_dropped`); a missing outcome is not an event, and a missing
amount counts as 0.

## See also

[`scr_overlap()`](https://evandeilton.github.io/scorecraft/reference/scr_overlap.md)
for the rules against the score,
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md)
for the threshold under a review capacity.

Other score-studies:
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md),
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
local({
  set.seed(1)
  n <- 30000
  d <- data.frame(card = sample(3000, n, TRUE), ts = sort(runif(n, 0, 30)))
  # 60 cards are compromised from some day on; their later rows are fraud
  hit <- sample(3000, 60)
  since <- runif(3000, 5, 25)
  d$y <- as.integer(d$card %in% hit & d$ts >= since[d$card])
  d$score <- round(100 * plogis(rnorm(n, -2 + 2 * d$y)))
  d$amount <- round(rexp(n, 1 / 60), 2)
  dt <- scr_detection(d, entity = "card", time = "ts", amount = "amount",
                      alert_shares = c(0.01, 0.03, 0.10))
  print(dt)
  head(dt$episodes)
})
#> <scr_detection> entity "card" | time "ts" | score "score" (higher_is_riskier) | outcome "y"
#>   30,000 rows | 60 episodes over 293 rows from their starts | loss 17,820.9
#> 
#>      threshold alert share  detected      pct   events before        (mean)  median time  loss prevented
#>           61.5       0.98%        49    81.7%             1.0          1.27        0.393           70.7%
#>           48.5       3.07%        55    91.7%             0.0          0.64            0           86.1%
#>           33.5       9.73%        59    98.3%             0.0          0.24            0           94.3%
#>    entity     start  rows events amount peak_score detected detect_time
#>     <int>     <num> <int>  <num>  <num>      <num>   <lgcl>       <num>
#> 1:     15 21.131215     1      1  75.68          9    FALSE          NA
#> 2:     20 11.112258     8      8 518.91         90     TRUE   20.547708
#> 3:     31 19.862280     4      4 297.71         89     TRUE   25.001172
#> 4:    153 24.852141     2      2 289.27         63     TRUE   29.804259
#> 5:    257 17.405602     4      4  81.36         60    FALSE          NA
#> 6:    263  9.378193     8      8 717.00         84     TRUE    9.378193
#>    time_to_detect events_before loss_before
#>             <num>         <num>       <num>
#> 1:             NA            NA          NA
#> 2:       9.435450             4      373.03
#> 3:       5.138892             3      148.32
#> 4:       4.952117             1      214.43
#> 5:             NA            NA          NA
#> 6:       0.000000             0        0.00
```
