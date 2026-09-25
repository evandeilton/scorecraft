# Audit funnel: every input variable and its fate

The central deliverable. One row per input column, plus one per derived
variable, with the descriptive profile, the verdict of every gate, the
votes of every model and `exit_stage`, the exact stage at which the
variable failed. No candidate disappears from the report.

## Usage

``` r
scr_funnel(x, only_selected = FALSE, cols = "essentials")
```

## Arguments

- x:

  An object from
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md).

- only_selected:

  If `TRUE`, returns only the approved ones.

- cols:

  `"essentials"` (default) gives a lean view; `"all"` gives everything;
  or pass a vector of names.

## Value

A `data.table` ordered with the approved first.

## Values of `exit_stage`

- `00.config`:

  Never competed: it was in `drop`.

- `01.triage`:

  Constant, near-constant, high cardinality, exact duplicate, missing
  share above the ceiling, or no signal in the coarse IV.

- `02.binning`:

  The binning algorithm failed on this column.

- `03.screening`:

  Failed one of the eight admission rules.

- `04.holdout`:

  IV dropped out of sample, unstable PSI, or part of the hold-out falls
  in no bin.

- `05.correlation`:

  Redundant with a better-ranked variable.

- `05b.derived_excluded`:

  Passed everything, but is a column the pipeline created and
  `allow_derived_final = FALSE`.

- `06.consensus`:

  Not enough votes, or outside the top-N.

- `07.approved`:

  Entered the shortlist.

- `08.manual_drop`:

  In the automatic consensus, but removed by the analyst in the coarse
  classing lab
  ([`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md)).

## See also

Other accessors:
[`scr_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_gains.md),
[`scr_leakage()`](https://evandeilton.github.io/scorecraft/reference/scr_leakage.md),
[`scr_result`](https://evandeilton.github.io/scorecraft/reference/scr_result.md),
[`scr_score_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_score_gains.md),
[`scr_score_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_score_metrics.md),
[`scr_selected()`](https://evandeilton.github.io/scorecraft/reference/scr_selected.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
head(scr_funnel(res, only_selected = TRUE))
#>        feature derived_from        type approved  exit_stage consensus_rank
#>         <char>       <char>      <char>   <lgcl>      <char>          <int>
#> 1: vl_score_01         <NA>     numeric     TRUE 07.approved              1
#> 2: vl_score_02         <NA>     numeric     TRUE 07.approved              2
#> 3: vl_score_04         <NA>     numeric     TRUE 07.approved              3
#> 4:     ds_band         <NA> categorical     TRUE 07.approved              4
#> 5:     vl_late         <NA>     numeric     TRUE 07.approved              5
#> 6:   ds_region         <NA> categorical     TRUE 07.approved              6
#>    consensus_score votes n_bins   total_iv iv_holdout        ks         psi
#>              <num> <int>  <int>      <num>      <num>     <num>       <num>
#> 1:       1.0000000     3      7 0.34639015 0.28772640 0.1981484 0.006635574
#> 2:       0.9090909     3      7 0.17206972 0.12336796 0.1564626 0.005346830
#> 3:       0.8181818     3      7 0.12430307 0.11773607 0.1199427 0.003216554
#> 4:       0.6377928     3      4 0.08054551 0.07804157 0.1100565 0.001317467
#> 5:       0.6367525     3      7 0.07109472 0.06384879 0.1201400 0.104196466
#> 6:       0.6345456     3      5 0.08464808 0.09714339 0.1141337 0.006365199
#>    psi_flag_adjusted iv_suspect triage_reason screen_reason holdout_reason
#>               <char>     <lgcl>        <char>        <char>         <char>
#> 1:            stable      FALSE            OK            OK             OK
#> 2:            stable      FALSE            OK            OK             OK
#> 3:            stable      FALSE            OK            OK             OK
#> 4:            stable      FALSE            OK            OK             OK
#> 5:             shift      FALSE            OK            OK             OK
#> 6:            stable      FALSE            OK            OK             OK
#>    prune_corr_with
#>             <char>
#> 1:            <NA>
#> 2:            <NA>
#> 3:            <NA>
#> 4:            <NA>
#> 5:            <NA>
#> 6:            <NA>
table(scr_funnel(res, cols = "all")$exit_stage)
#> 
#>            00.config            01.triage         03.screening 
#>                    2                    8                   17 
#>           04.holdout       05.correlation 05b.derived_excluded 
#>                    4                    1                    3 
#>          07.approved 
#>                   12 
```
