# Stage 6: honest reject inference through a sensitivity band

Does not ship parcelling as the default behaviour: instead of inventing
a single multiplier and reweighting, it declares the **population
scope** of the scorecard, measures the **coverage per band** (where an
observed outcome exists, and in what volume) and presents a
**sensitivity band**: the event rate each band would have if the
population without an outcome were 2, 4 or 8 times worse than the
observed one, with the effect on the total. The analyst reads the band;
no single number is fabricated.

## Usage

``` r
scr_reject(
  x,
  population = NULL,
  accepted = NULL,
  multipliers = NULL,
  sample = "holdout"
)
```

## Arguments

- x:

  An object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

- population:

  Optional: a table of the full population (accepted and rejected,
  without outcome), scored by
  [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md).
  `NULL` restricts the scope to the population with an outcome.

- accepted:

  Optional: a logical vector, of the length of `population`, marking the
  rows with an observed outcome. `NULL` treats the whole `population` as
  without an outcome beyond the development sample.

- multipliers:

  Sensitivity band. `NULL` uses the configuration.

- sample:

  Reference sample of the observed outcomes.

## Value

An `scr_reject` object with `scope`, `coverage` (per band) and
`sensitivity` (per band and multiplier, plus the `TOTAL` row).

## See also

Other stages:
[`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md),
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md),
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md),
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
sc <- scr_scorecard(res)
scr_reject(sc)
#> <scr_reject> target "default" | multipliers 2x, 4x, 8x
#>   The scorecard describes the population WITH an observed outcome. No extrapolation to rejects was made; the sensitivity band shows the effect of declared assumptions, not an inferred number.
#>   observed event rate: 14.50%
#>   implied rate if the population without outcome is 2x worse: 14.50%
#>   implied rate if the population without outcome is 4x worse: 14.50%
#>   implied rate if the population without outcome is 8x worse: 14.50%
#>   bands with weak coverage: (590, Inf] (few_events), (577,590] (few_events), (567,577] (few_events), (558,567] (few_events), (550,558] (few_events), (542,550] (few_events), (533,542] (few_events)
# with a through-the-door population: rows with an outcome are the hold-out
acc <- seq_len(nrow(scr_demo)) %in% res$split$holdout_idx
scr_reject(sc, population = scr_demo, accepted = acc)
#> <scr_reject> target "default" | multipliers 2x, 4x, 8x
#>   The full population has 4,200 rows, of which 1,400 (33.3%) have an observed outcome. The rest enter only the sensitivity band, under declared multipliers.
#>   observed event rate: 14.50%
#>   implied rate if the population without outcome is 2x worse: 24.56%
#>   implied rate if the population without outcome is 4x worse: 40.45%
#>   implied rate if the population without outcome is 8x worse: 53.43%
#>   bands with weak coverage: (590, Inf] (few_events), (577,590] (few_events), (567,577] (few_events), (558,567] (few_events), (550,558] (few_events), (542,550] (few_events), (533,542] (few_events)
```
