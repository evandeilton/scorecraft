# Stage 0: type the data and split train and hold-out

First stage of the pipeline, callable on its own. Converts the target to
0/1 (resolving `event_level`), types the candidates (numerics become
`double`, everything else becomes `character`) and splits train and
hold-out **before** any supervised fit.

## Usage

``` r
scr_split(
  data,
  target,
  date_col = NULL,
  ratio = 0.3,
  seed = NULL,
  event_level = NULL,
  drop = character(),
  copy = TRUE
)
```

## Arguments

- data:

  A `data.frame` or `data.table` with the target and the candidates.

- target:

  Name of the target column. Binary: 0/1, logical, or a two-level
  factor/character.

- date_col:

  Date column of the out-of-time cut. `NULL` uses a random stratified
  split.

- ratio:

  Target hold-out fraction.

- seed:

  Seed of the random split.

- event_level:

  Which target value counts as the event. `NULL` uses the convention
  (`1`, or the second alphabetical level).

- drop:

  Columns that are never candidates (identifiers, sibling targets, free
  text). They stay in the funnel as `00.config`.

- copy:

  If `TRUE` (default), works on a copy of `data`. `FALSE` modifies
  `data` by reference (typing), saving memory.

## Value

An `scr_split` object with `data` (typed), `target`, `train_idx`,
`holdout_idx`, `method`, `cutoff`, `date_col` and `cols` (`features`,
`var_num`, `var_cat`, `dropped`, `event`).

## Details

The split prefers out-of-time by `date_col`: it is the only one that
tests generalisation to a future period. The cut is made on the
**distinct** date values, not by row quantile: it picks the smallest set
of most recent periods that already reaches `ratio` of the population.
Without a date column, or with a single period, it falls back to random
stratified by the target. The date column is never a candidate: it is
the key of the split and leaves the contest.

## Event orientation

`event_level` changes **what is modelled**. Passing `0` makes class 0
the event: the sign of every WOE flips, the emitted SQL changes, the
points change. For a text target, the second level in alphabetical order
is the event by default, and the choice is always reported. Not to be
confused with `config$objective`, which only orients the reading and the
points scale.

## See also

Other stages:
[`predict.scr_align()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_align.md),
[`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md),
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md),
[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md),
[`scr_monitoring_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_monitoring_plan.md),
[`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md),
[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md),
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md),
[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)

## Examples

``` r
sp <- scr_split(scr_demo, "default", date_col = "ref_date", drop = "id")
#>   OOT: 4 period(s) in train, 2 in hold-out (hold-out starts at 2026-05-01, 33.3% of rows)
sp
#> <scr_split> target "default" | 4,200 rows: train 2,800, hold-out 1,400
#>   method: out-of-time (hold-out from 2026-05-01)
#>   candidates: 38 (32 numeric, 6 categorical) | dropped: 2
#>   event: class '1'
length(sp$train_idx); length(sp$holdout_idx)
#> [1] 2800
#> [1] 1400
```
