# Stage 1: descriptive triage and sentinel resolution

Profiles every candidate **on the training rows only**, decides its fate
and materialises the clean data for train and hold-out with the same
values (training median, `"MISSING"` level). A sentinel or missing mass
with weight (`special_min_share`) and signal (`special_min_woe`) becomes
a categorical flag `<column><flag_suffix>`, which the engine bins and
emits in SQL natively.

## Usage

``` r
scr_triage(split, config = scr_config())
```

## Arguments

- split:

  An object from
  [`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md).

- config:

  An object from
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md).

## Value

An `scr_triage` object with `profile` (one row per candidate and derived
flag), `ledger` (the source of truth of the pre-processing the SQL
reproduces), `keep`, `derived`, `clean` (target + survivors + flags,
with no `NA`) and the originating `split`.

## Details

Failures at this stage: `CONSTANT`, `NEAR_CONSTANT`, `TOO_MANY_MISSING`,
`HIGH_CARDINALITY`, `NO_SIGNAL` (coarse IV below `min_iv_quick`) and
`DUPLICATE_OF:<column>`.

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
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md)

## Examples

``` r
sp <- scr_split(scr_demo, "default", date_col = "ref_date", drop = "id")
#>   OOT: 4 period(s) in train, 2 in hold-out (hold-out starts at 2026-05-01, 33.3% of rows)
tr <- scr_triage(sp, scr_config(verbose = FALSE))
tr
#> <scr_triage> target "default" | 38 candidates -> 37 survivors (7 derived)
#>   CONSTANT                 2
#>   TOO_MANY_MISSING;RESCUED_AS_FLAG 1
#>   TOO_MANY_MISSING         1
#>   NEAR_CONSTANT            1
#>   DUPLICATE_OF:vl_score_01 1
#>   HIGH_CARDINALITY         1
#>   NO_SIGNAL                1
table(tr$profile$triage_reason)
#> 
#>                         CONSTANT         DUPLICATE_OF:vl_score_01 
#>                                2                                1 
#>                 HIGH_CARDINALITY                    NEAR_CONSTANT 
#>                                1                                1 
#>                        NO_SIGNAL                               OK 
#>                                1                               37 
#>                 TOO_MANY_MISSING TOO_MANY_MISSING;RESCUED_AS_FLAG 
#>                                1                                1 
```
