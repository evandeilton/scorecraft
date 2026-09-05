# Monitor the scorecard on new data

Recomputes, per period of `date_col` (or for the whole data), the score
PSI against train with frozen bands, the CSI of every variable with
frozen bins plus the signed points shift and, when the target is
present, the performance by vintage (event rate, AUC/KS/Gini with CI).
Always reports both thresholds (fixed and n-adjusted). Schedules
nothing: the analyst calls it when needed.

## Usage

``` r
scr_monitor(
  x,
  newdata,
  date_col = NULL,
  target = NULL,
  alpha = NULL,
  n_boot = NULL,
  plan = NULL
)
```

## Arguments

- x:

  An object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

- newdata:

  New table with the source columns.

- date_col:

  Period column. `NULL` treats `newdata` as a single period.

- target:

  Target column in `newdata`, for the performance by vintage. `NULL`
  skips it.

- alpha:

  Level of the adjusted threshold. `NULL` (default) takes it from the
  plan.

- n_boot:

  CI resamples per vintage. `NULL` uses the configuration.

- plan:

  The monitoring contract: `NULL` (default) uses the plan stored in the
  scorecard
  ([`scr_monitoring_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_monitoring_plan.md));
  otherwise an `item`/`value` table, or the path of a strategy workbook
  written by
  [`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md),
  whose `Monitoring_Plan` sheet is read. The fixed thresholds of the PSI
  and CSI flags, the alpha of the adjusted threshold and
  `min_events_per_period` come from it.

## Value

An `scr_monitor` object with `psi` (score, per period), `csi` (per
variable and period), `vintage` (or `NULL`; `status` says
`"insufficient"` when a period has fewer events than the plan requires)
and `plan` (the contract actually used).

## See also

Other production:
[`predict.scr_align()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_align.md),
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md),
[`scr_monitoring_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_monitoring_plan.md),
[`scr_reasons()`](https://evandeilton.github.io/scorecraft/reference/scr_reasons.md),
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
sc <- scr_scorecard(res)
mo <- scr_monitor(sc, scr_demo, date_col = "ref_date", target = "default")
mo
#> <scr_monitor> target "default" | 6 period(s) | plan: PSI 0.1/0.25, CSI 0.1/0.25, alpha 0.05, min events 100
#>   period              n      score      PSI fixed      critical adj.    
#>   2026-01-01        700      549.8   0.0083 stable       0.0302 stable  
#>   2026-02-01        700      550.3   0.0071 stable       0.0302 stable  
#>   2026-03-01        700      550.4   0.0084 stable       0.0302 stable  
#>   2026-04-01        700      550.7   0.0125 stable       0.0302 stable  
#>   2026-05-01        700      550.2   0.0284 stable       0.0302 stable  
#>   2026-06-01        700      552.3   0.0129 stable       0.0302 stable  
#>   largest points shifts (variable @ period):
#>     vl_tardio                    2026-06-01   CSI 0.4141  shift +1.89 pts
#>     vl_score_01                  2026-02-01   CSI 0.0039  shift -1.01 pts
#>     vl_score_04                  2026-02-01   CSI 0.0189  shift +0.80 pts
#>     vl_score_01                  2026-06-01   CSI 0.0209  shift -0.61 pts
#>     vl_hist_04                   2026-05-01   CSI 0.0183  shift +0.60 pts
#>   performance by vintage:
#>     2026-01-01   n 700     event  14.14%  AUC 0.8152 [0.7928, 0.8508]  KS 0.5069  (insufficient events)
#>     2026-02-01   n 700     event  14.57%  AUC 0.7997 [0.7587, 0.8363]  KS 0.4708
#>     2026-03-01   n 700     event  13.71%  AUC 0.7605 [0.7049, 0.7906]  KS 0.4487  (insufficient events)
#>     2026-04-01   n 700     event  14.57%  AUC 0.7644 [0.7097, 0.8061]  KS 0.4094
#>     2026-05-01   n 700     event  14.00%  AUC 0.7500 [0.7008, 0.7908]  KS 0.3904  (insufficient events)
#>     2026-06-01   n 700     event  15.00%  AUC 0.7318 [0.6903, 0.7583]  KS 0.3950
mo$psi
#>        period     n mean_score         psi flag_fixed   critical flag_adjusted
#>        <char> <int>      <num>       <num>     <char>      <num>        <char>
#> 1: 2026-01-01   700   549.8457 0.008300253     stable 0.03021246        stable
#> 2: 2026-02-01   700   550.2764 0.007138020     stable 0.03021246        stable
#> 3: 2026-03-01   700   550.4213 0.008386231     stable 0.03021246        stable
#> 4: 2026-04-01   700   550.6736 0.012474292     stable 0.03021246        stable
#> 5: 2026-05-01   700   550.1794 0.028352777     stable 0.03021246        stable
#> 6: 2026-06-01   700   552.3036 0.012863926     stable 0.03021246        stable
head(mo$csi)
#>        period    variable     n         csi flag_fixed   critical flag_adjusted
#>        <char>      <char> <int>       <num>     <char>      <num>        <char>
#> 1: 2026-01-01 vl_score_01   700 0.004088224     stable 0.02248498        stable
#> 2: 2026-01-01 vl_score_02   700 0.004951889     stable 0.02248498        stable
#> 3: 2026-01-01 vl_score_04   700 0.003680758     stable 0.02248498        stable
#> 4: 2026-01-01    ds_faixa   700 0.002128715     stable 0.01395487        stable
#> 5: 2026-01-01   vl_tardio   700 0.008873842     stable 0.02248498        stable
#> 6: 2026-01-01   ds_regiao   700 0.005328940     stable 0.01694237        stable
#>    points_shift
#>           <num>
#> 1:   0.06071429
#> 2:  -0.14000000
#> 3:  -0.12000000
#> 4:   0.11035714
#> 5:   0.47821429
#> 6:  -0.06857143
```
