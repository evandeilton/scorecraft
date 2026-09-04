# Stage 2: optimal binning, screening, hold-out revalidation and pruning

Fits the bins **on the training rows only** (cut points and WOE use the
target), in parallel by column, and applies in sequence:

## Usage

``` r
scr_bin(triage, config = scr_config())
```

## Arguments

- triage:

  An object from
  [`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md).

- config:

  An object from
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md).

## Value

An `scr_bins` object with `fit` (an `obwoe` object), `screen` (`summary`
and `full`), `holdout`, `prune`, `pool` (eligible for the models),
`derived_excluded`, the WOE matrices `woe_train`/`woe_holdout` and the
originating `triage`.

## Details

1.  **Screening**, native to the engine: eight admission rules
    (`IV_BELOW_MIN`, `IV_SUSPICIOUS`, `NOT_MONOTONIC`, `TOO_FEW_BINS`,
    `TOO_MANY_BINS`, `SMALL_BIN`, `DEGENERATE_BIN`, `BINNING_ERROR`).

2.  **Hold-out revalidation** with frozen bins: IV recomputed on the
    same labels, train/hold-out PSI (the fixed threshold decides; the
    n-adjusted one is reported) and the fraction of hold-out without a
    bin.

3.  **Redundancy pruning** by rank correlation on the WOE space, ranked
    by hold-out IV.

## Parallelism

Columns are split into `config$nthread` chunks, each chunk is binned by
a worker and the fits are merged. The result is identical to the serial
one (a test pins this): the engine is deterministic per column.

## See also

Other stages:
[`predict.scr_align()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_align.md),
[`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md),
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md),
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md),
[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md),
[`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md),
[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md),
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md),
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1)
sp <- scr_split(scr_demo, "default", date_col = "ref_date", drop = "id")
#>   OOT: 4 period(s) in train, 2 in hold-out (hold-out starts at 2026-05-01, 33.3% of rows)
bn <- scr_bin(scr_triage(sp, cfg), cfg)
bn
#> <scr_bins> 37 binned | screening 20 | hold-out 16 | pruning 15 | pool 12
#>   screening: IV_BELOW_MIN               12
#>   screening: IV_BELOW_MIN;NOT_MONOTONIC 4
#>   screening: NOT_MONOTONIC              1
head(bn$holdout)
#>          feature iv_train_bins iv_holdout  iv_ratio         psi psi_flag
#>           <char>         <num>      <num>     <num>       <num>   <char>
#> 1:   vl_score_01    0.33268544 0.28772640 0.8648602 0.006635574   stable
#> 2: vl_redundante    0.17271398 0.10710836 0.6201488 0.006536686   stable
#> 3:   vl_score_02    0.16913274 0.12336796 0.7294150 0.005346830   stable
#> 4:   vl_score_04    0.11904839 0.11773607 0.9889766 0.003216554   stable
#> 5:     ds_regiao    0.08497314 0.09714339 1.1432247 0.006365199   stable
#> 6:      ds_faixa    0.07980052 0.07804157 0.9779582 0.001317467   stable
#>    psi_critical psi_flag_adjusted pct_unbinned holdout_ok holdout_reason
#>           <num>            <char>        <num>     <lgcl>         <char>
#> 1:  0.013490986            stable            0       TRUE             OK
#> 2:  0.013490986            stable            0       TRUE             OK
#> 3:  0.013490986            stable            0       TRUE             OK
#> 4:  0.013490986            stable            0       TRUE             OK
#> 5:  0.010165424            stable            0       TRUE             OK
#> 6:  0.008372923            stable            0       TRUE             OK
```
