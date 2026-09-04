# scorecraft: from raw table to aligned scorecard and production SQL

This vignette walks the whole pipeline on the bundled `scr_demo` table,
a synthetic dataset fabricated with the defects real data has: sentinel
`-999`, missing values, constants, duplicates, a redundant pair, high
cardinality, pure noise and a column that only degrades in the last
period.

``` r

library(scorecraft)
cfg <- scr_config("moderate", objective = "risk", verbose = FALSE, nthread = 1,
                  use_ranger = FALSE, xgb_rounds = 60, n_boot = 30)
cfg
#> <scr_config> preset "moderate" | objective "risk" | seed 2203 | threads 1
#> 
#> Convention
#>   target = 1             target = 1 is the BAD case
#>   points scale           more points = lower probability of the event (safer) [higher_is_safer]
#> 
#> Funnel
#>   variables at the end   10 to 25
#>   minimum votes          2
#>   admissible IV          [0.02, 1)  warning at 0.5
#>   correlation            0.7 (spearman)
#> 
#> Binning
#>   bins                   3 to 7, algorithm "jedi"
#>   monotonicity           numeric (weak)
#>   smallest bin           2.0%
#> 
#> Scorecard
#>   scale                  600 points at odds 50:1, PDO 20
#>   alignment              regression (10 bands)
#>   challenger             none
#>   bootstrap CI           30 resamples, 95%
#> 
#> Data
#>   sentinels              -999
#>   derived at the end     no (diagnostic only)
#>   hold-out               30.0%
#> 
#> Models
#>   enabled                glmnet, xgboost, lightgbm
#>   row cap                200,000
```

## Stages 0 to 4: selection

[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
chains the split (out-of-time by whole periods), the triage, the optimal
binning with screening and hold-out revalidation, and the multi-strategy
consensus. Each stage is also exported on its own
([`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md)).

``` r

res <- scr_select(scr_demo, "default", config = cfg, drop = "id", date_col = "ref_date")
res
#> <scr_result> target "default"
#>   4,200 rows (train 2,800 / hold-out 1,400) | split out-of-time at 2026-05-01
#>   event: 14.25% on train, 14.50% on hold-out | 1.8s
#>   convention: risk (target=1 is the bad case)
#> 
#> Funnel
#>   candidates        38 ############################
#>   1. triage         37 ###########################
#>   2. binning        37 ###########################
#>   3. screening      20 ###############
#>   4. hold-out       16 ############
#>   5. correlation    12 #########
#>   6. consensus      12 #########
#> 
#> Approved: 12
#>    1. vl_score_01                                  IV  0.346  KS 0.198
#>    2. vl_score_02                                  IV  0.172  KS 0.156
#>    3. vl_score_04                                  IV  0.124  KS 0.120
#>    4. ds_faixa                                     IV  0.081  KS 0.110
#>    5. vl_tardio                                    IV  0.071  KS 0.120
#>   ... (+7) - scr_selected() for the list
#> 
#> Models (hold-out)
#>   glmnet    AUC 0.7345 [0.7029, 0.7715]  KS 0.3842
#>   xgboost   AUC 0.7375 [0.7067, 0.7752]  KS 0.3695
#>   lightgbm  AUC 0.7236 [0.6916, 0.7563]  KS 0.3641
#> 
#> Warnings
#>   - 3 derived flag(s) outside the deliverable by policy (allow_derived_final)
```

The funnel is the deliverable: every input column, the stage it died at
and why.

``` r

table(scr_funnel(res, cols = "all")$exit_stage)
#> 
#>            00.config            01.triage         03.screening 
#>                    2                    8                   17 
#>           04.holdout       05.correlation 05b.derived_excluded 
#>                    4                    1                    3 
#>          07.approved 
#>                   12
head(scr_funnel(res, only_selected = TRUE)[, .(feature, total_iv, iv_holdout, ks, psi, psi_flag_adjusted)])
#>        feature   total_iv iv_holdout        ks         psi psi_flag_adjusted
#>         <char>      <num>      <num>     <num>       <num>            <char>
#> 1: vl_score_01 0.34639015 0.28772640 0.1981484 0.006635574            stable
#> 2: vl_score_02 0.17206972 0.12336796 0.1564626 0.005346830            stable
#> 3: vl_score_04 0.12430307 0.11773607 0.1199427 0.003216554            stable
#> 4:    ds_faixa 0.08054551 0.07804157 0.1100565 0.001317467            stable
#> 5:   vl_tardio 0.07109472 0.06384879 0.1201400 0.104196466             shift
#> 6:   ds_regiao 0.08464808 0.09714339 0.1141337 0.006365199            stable
```

## Stages 4 and 5: scorecard and alignment

[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
fits the logistic regression on the WOE columns, checks the signs, and
aligns the logit to the declared scale by regressing empirical log-odds
on score bands and composing with the PDO map. The alignment object
records the odds orientation so that two scorecards aligned this way are
comparable.

``` r

sc <- scr_scorecard(res)
sc
#> <scr_scorecard> target "default" | 12 variables | higher_is_safer
#>   scale: 600 points at odds 50:1 (safe:event), PDO 20 | alignment regression
#>   score = 491.1967 + -26.3189 * logit | base_points = 538
#>   train    n 2,800   AUC 0.7856 [0.7671, 0.8062]  KS 0.4411  Gini 0.5713
#>   holdout  n 1,400   AUC 0.7394 [0.7071, 0.7764]  KS 0.3889  Gini 0.4788
#>   score PSI (hold-out): 0.0069 - fixed: stable | adjusted (0.0181): stable
#> 
#> Points (first rows)
#>   vl_score_01                  (-Inf;33.360000]             -2.063      61
#>   vl_score_01                  (33.360000;38.150000]        -0.731      22
#>   vl_score_01                  (38.150000;44.240000]        -0.658      20
#>   vl_score_01                  (44.240000;48.060000]        -0.523      16
#>   vl_score_01                  (48.060000;63.940000]         0.040      -1
#>   vl_score_01                  (63.940000;72.610000]         0.704     -21
#>   vl_score_01                  (72.610000;+Inf]              0.996     -30
#>   vl_score_02                  (-Inf;40.880000]             -0.824      22
#>   ... (+56 rows)
sc$alignment
#> <scr_align> 600 points at odds 50:1 (safe:event), PDO 20 | higher_is_safer
#>   factor = 28.853901 | offset = 487.122876
#>   calibration: ln(odds) = 0.141187 + -0.912143 * raw  (adj. R2 = 0.9668, 10 bands)
#>   score = 491.196658 + -26.318891 * raw
head(sc$points[, .(variable, bin, woe, coef, points)])
#>       variable                   bin         woe     coef points
#>         <char>                <char>       <num>    <num>  <num>
#> 1: vl_score_01      (-Inf;33.360000] -2.06253559 1.128507     61
#> 2: vl_score_01 (33.360000;38.150000] -0.73104946 1.128507     22
#> 3: vl_score_01 (38.150000;44.240000] -0.65810792 1.128507     20
#> 4: vl_score_01 (44.240000;48.060000] -0.52261206 1.128507     16
#> 5: vl_score_01 (48.060000;63.940000]  0.03978629 1.128507     -1
#> 6: vl_score_01 (63.940000;72.610000]  0.70394095 1.128507    -21
```

Discrimination always comes with a bootstrap confidence interval, and
the score PSI with both thresholds.

``` r

scr_score_metrics(sc)[, .(sample, auc, auc_lo, auc_hi, ks, gini)]
#>     sample       auc    auc_lo    auc_hi        ks      gini
#>     <char>     <num>     <num>     <num>     <num>     <num>
#> 1:   train 0.7856428 0.7670819 0.8062129 0.4411466 0.5712856
#> 2: holdout 0.7394060 0.7071079 0.7764112 0.3889033 0.4788120
sc$stability$score
#>     sample         psi flag_fixed   critical flag_adjusted n_base n_compare
#>     <char>       <num>     <char>      <num>        <char>  <int>     <int>
#> 1: holdout 0.006937751     stable 0.01812748        stable   2800      1400
```

## Stage 6: cut-off, strategy and reject inference

``` r

scr_cutoff(sc, n_cuts = 8)
#> <scr_cutoff> target "default" | 8 cuts frozen on train | safe side: high score
#>        cut     %safe    ev.safe   ev.risky   ev.avoid       KS
#>      511.6     90.2%     12.19%     35.77%      24.1%    0.168
#>      525.6     80.0%     10.27%     31.43%      43.3%    0.273
#>      536.6     68.0%      8.09%     28.12%      62.1%    0.352
#>      546.0     55.6%      6.68%     24.32%      74.4%    0.351
#>      554.1     45.3%      5.21%     22.19%      83.7%    0.340
#>      563.8     32.6%      3.28%     19.94%      92.6%    0.295
#>      573.8     22.0%      3.57%     17.58%      94.6%    0.194
#>      588.0     12.1%      2.96%     16.08%      97.5%    0.112
scr_strategy(sc, revenue_good = 1080, loss_bad = 4500)
#> <scr_strategy> target "default" | sample holdout | break-even event rate: 19.35% (revenue 1080, loss 4500)
#>   band                       vol%    event decision     EP/acct       profit
#>   (590, Inf]                11.2%    3.18% approve       902.29       141660
#>   (577,590]                  8.9%    3.23% approve       900.00       111600
#>   (567,577]                  9.1%    3.91% approve       862.03       110340
#>   (558,567]                 10.6%    7.38% approve       668.05        99540
#>   (550,558]                 10.6%   12.16% approve       401.35        59400
#>   (542,550]                 10.8%   11.26% approve       451.79        68220
#>   (533,542]                 10.6%   17.45% approve       106.31        15840
#>   (524,533]                  9.9%   26.62% decline      -405.32       -56340
#>   (510,524]                  9.1%   27.34% decline      -445.78       -57060
#>   [-Inf,510]                 9.1%   35.43% decline      -897.17      -113940
scr_reject(sc)
#> <scr_reject> target "default" | multipliers 2x, 4x, 8x
#>   The scorecard describes the population WITH an observed outcome. No extrapolation to rejects was made; the sensitivity band shows the effect of declared assumptions, not an inferred number.
#>   observed event rate: 14.50%
#>   implied rate if the population without outcome is 2x worse: 14.50%
#>   implied rate if the population without outcome is 4x worse: 14.50%
#>   implied rate if the population without outcome is 8x worse: 14.50%
#>   bands with weak coverage: (590, Inf] (few_events), (577,590] (few_events), (567,577] (few_events), (558,567] (few_events), (550,558] (few_events), (542,550] (few_events), (533,542] (few_events)
```

## Production: R and SQL agree

``` r

new <- head(scr_demo, 5)
scr_apply(sc, new)
#>         link       prob    score score_points
#>        <num>      <num>    <num>        <num>
#> 1: -2.102534 0.10885077 546.5330          546
#> 2: -2.702712 0.06281350 562.3290          562
#> 3: -2.634040 0.06697956 560.5217          559
#> 4: -0.602874 0.35368644 507.0636          507
#> 5: -1.731277 0.15042432 536.7619          536
scr_reasons(sc, new, k = 2)
#>       reason_1 shortfall_1    reason_2 shortfall_2
#>         <char>       <num>      <char>       <num>
#> 1: vl_score_01   25.197857 vl_score_02   17.828571
#> 2: vl_score_04    9.052857   vl_tardio    5.716071
#> 3:   vl_tardio   13.716071 vl_score_07    7.605357
#> 4:   ds_regiao   13.807143    ds_faixa   11.932500
#> 5: vl_score_02   17.828571 vl_score_05    9.054286
```

``` r

cat(tail(scr_sql(sc, table = "prd.customers", dialect = "databricks"), 8), sep = "\n")
#>       CASE vl_score_06_idx WHEN 1 THEN 9 WHEN 2 THEN 4 WHEN 3 THEN -3 WHEN 4 THEN -4 WHEN 5 THEN -5 WHEN 6 THEN -10 WHEN 7 THEN -15 ELSE 0 END AS vl_score_06_points,
#>       CASE vl_score_07_idx WHEN 1 THEN 14 WHEN 2 THEN 6 WHEN 3 THEN 6 WHEN 4 THEN 1 WHEN 5 THEN -2 WHEN 6 THEN -7 ELSE 0 END AS vl_score_07_points,
#>       CASE vl_score_05_idx WHEN 1 THEN 6 WHEN 2 THEN -3 WHEN 3 THEN -9 WHEN 4 THEN -9 WHEN 5 THEN -14 ELSE 0 END AS vl_score_05_points,
#>       CASE ds_canal_idx WHEN 1 THEN 9 WHEN 2 THEN 4 WHEN 3 THEN -5 ELSE 0 END AS ds_canal_points,
#>       CASE vl_score_10_idx WHEN 1 THEN 2 WHEN 2 THEN -6 WHEN 3 THEN -21 ELSE 0 END AS vl_score_10_points,
#>       CASE vl_hist_04_idx WHEN 1 THEN 19 WHEN 2 THEN 9 WHEN 3 THEN -3 ELSE 0 END AS vl_hist_04_points
#>   FROM woe_scr
#> ) pts;
```

## Monitoring

[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md)
recomputes the score PSI, the per-variable CSI with the signed points
shift and the performance by vintage on any new data. It never schedules
itself.

``` r

scr_monitor(sc, scr_demo, date_col = "ref_date", target = "default", n_boot = 30)
#> <scr_monitor> target "default" | 6 period(s)
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
#>     2026-01-01   n 700     event  14.14%  AUC 0.8152 [0.7733, 0.8503]  KS 0.5069
#>     2026-02-01   n 700     event  14.57%  AUC 0.7997 [0.7634, 0.8416]  KS 0.4708
#>     2026-03-01   n 700     event  13.71%  AUC 0.7605 [0.7082, 0.7983]  KS 0.4487
#>     2026-04-01   n 700     event  14.57%  AUC 0.7644 [0.7131, 0.8038]  KS 0.4094
#>     2026-05-01   n 700     event  14.00%  AUC 0.7500 [0.6978, 0.8039]  KS 0.3904
#>     2026-06-01   n 700     event  15.00%  AUC 0.7318 [0.6708, 0.7633]  KS 0.3950
```

## Deliverables

[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
writes hardened `.xlsx` workbooks (selection, scorecard, validation,
strategy), the SQL files and a Markdown summary.

``` r

out <- file.path(tempdir(), "scorecraft-vignette")
basename(unlist(scr_export(sc, out, stamp = FALSE)$files))
#>   /tmp/RtmpaFtz34/scorecraft-vignette/scorecard_default.xlsx
#>   /tmp/RtmpaFtz34/scorecraft-vignette/validation_default.xlsx
#>   /tmp/RtmpaFtz34/scorecraft-vignette/strategy_default.xlsx
#>   /tmp/RtmpaFtz34/scorecraft-vignette/sql_score_default.sql
#>   /tmp/RtmpaFtz34/scorecraft-vignette/sql_woe_default.sql
#> [1] "scorecard_default.xlsx"  "validation_default.xlsx"
#> [3] "strategy_default.xlsx"   "sql_score_default.sql"  
#> [5] "sql_woe_default.sql"
```
