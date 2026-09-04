# PD calibration and rating grades

The introductory vignette ends with a scorecard whose alignment turns a
score into a probability. That probability is a good ranking device and
a fair estimate of the event rate **of the development sample**; it is
not yet a probability of default (PD) in the sense a capital or
provisioning model needs. Four things separate the two:

- the **default definition**: the target must be a default event built
  by a stated rule (days past due with material arrears, unlikeliness to
  pay, a probation before cure), not whatever flag happened to be in the
  table;
- the **long-run average**: the level of the PD must be anchored to the
  average one-year default rate observed over many cohorts, not to the
  event rate of one sample, which is a single draw of the cycle;
- **grades**: obligors are pooled into rating grades with a monotone PD,
  enough obligors and defaults to estimate it, and a stable
  distribution;
- the **margin of conservatism** and the **floor**: the grade PD carries
  an explicit add-on for estimation error and for known deficiencies,
  and it is never reported below the floor of its asset class.

Every step below leaves a record: the merges and repairs of the grades,
the entries of the margin ledger, the parameter table used for the
floor. The names follow the public frameworks (the Basel Framework of
the BCBS, the EBA guidelines on PD and LGD estimation, Resolução BCB
303/2023) only where they explain a name; the package is a technical
tool and the frameworks are tables of numbers it reads, not prose it
interprets.

``` r

library(scorecraft)
library(data.table)
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, n_boot = 20)
```

## 1. The default flag and the default-rate series

`scr_demo_panel` is a monthly panel: 600 obligors over 36 months with
days past due, arrears, exposure, a restructuring flag and a behavioural
score.
[`scr_default()`](https://evandeilton.github.io/scorecraft/reference/scr_default.md)
runs the definition of default over it as a small state machine per
obligor: a trigger (`dpd >= 90` with arrears above both the absolute and
the relative materiality thresholds) opens an event, the event closes
after three consecutive months without a trigger (twelve when the
obligor was restructured during the event). The row-level flags are the
product; the events table and the ledger document what the rule did.

``` r

d <- scr_default(scr_demo_panel, id = "id", date = "ref_date", dpd = "dpd",
                 arrears = "arrears", exposure = "exposure",
                 restructured = "restructured", config = cfg)
d
#> <scr_default> 600 units x 21,600 rows | 176 events | level obligor
#>   rule: dpd >= 90 with material arrears | probation 3 months (12 after restructuring)
#>   triggers: dpd 100.0% | median 5 months in default | cured 87.5%
head(d$events, 4)
#>    event_id     id      start        end trigger months cured
#>      <char> <char>     <Date>     <Date>  <char>  <int> <int>
#> 1:  O0003#1  O0003 2024-10-01 2025-05-01     dpd      8     1
#> 2:  O0011#1  O0011 2025-08-01 2025-11-01     dpd      4     1
#> 3:  O0013#1  O0013 2023-05-01 2023-08-01     dpd      4     1
#> 4:  O0016#1  O0016 2023-05-01 2023-08-01     dpd      4     1
d$ledger$detail
#> [1] "dpd >= 90 and arrears >= 100 and arrears/exposure > 0.01; probation 3 (12 after restructuring); level obligor"
```

[`scr_default_rate()`](https://evandeilton.github.io/scorecraft/reference/scr_default_rate.md)
turns the flagged panel into one-year default rates by cohort: at every
cohort start the non-defaulted obligors form the population and the
outcome is a default within the next twelve months. The long-run average
is the arithmetic mean of the cohort rates; the benchmark is the larger
of the last five years’ mean and the whole period’s mean, and a flag is
raised when the average sits below it. The panel covers less than two
years of complete windows, so the print says plainly that the average is
not a long-run one yet.

``` r

dr <- scr_default_rate(d, by = "quarter", config = cfg)
dr
#> <scr_dr> 8 quarterly cohorts over 1.7 years | horizon 12 months
#>   default rate: mean 9.63% | weighted 9.64% | min 9.03% | max 10.28% | sd 0.42%
#>   long-run average 9.63% vs benchmark 9.63% (max of last-5-years 9.63% and all-years 9.63%)
#>   note: fewer than five years of cohorts; the average is not a long-run one yet
dr$table
#>        cohort     n defaults         dr
#>        <Date> <int>    <int>      <num>
#> 1: 2023-01-01   600       59 0.09833333
#> 2: 2023-04-01   590       59 0.10000000
#> 3: 2023-07-01   572       55 0.09615385
#> 4: 2023-10-01   570       53 0.09298246
#> 5: 2024-01-01   572       53 0.09265734
#> 6: 2024-04-01   574       59 0.10278746
#> 7: 2024-07-01   565       51 0.09026549
#> 8: 2024-10-01   565       55 0.09734513
```

## 2. Calibrating the scorecard to the central tendency

The scorecard comes from `scr_demo` with the fast configuration. Its
hold-out event rate is 14.5 %, well above the 9.6 % long-run average of
the panel: a sample of the development window, not the cycle.

``` r

res <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                  date_col = "ref_date")
sc <- scr_scorecard(res)
sc
#> <scr_scorecard> target "default" | 12 variables | higher_is_safer
#>   scale: 600 points at odds 50:1 (safe:event), PDO 20 | alignment regression
#>   score = 491.1967 + -26.3189 * logit | base_points = 538
#>   train    n 2,800   AUC 0.7856 [0.7662, 0.8070]  KS 0.4411  Gini 0.5713
#>   holdout  n 1,400   AUC 0.7394 [0.7066, 0.7770]  KS 0.3889  Gini 0.4788
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
```

[`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md)
re-anchors the probability to the central tendency (CT) without touching
the points: it returns a **new** alignment `(I*, S*)` whose
`predict(..., type = "prob")` is the calibrated PD, while the scorecard
keeps its own alignment for the score. Passing the `scr_dr` as the
target uses its long-run average and records where the CT came from.

``` r

cal <- scr_calibrate(sc, target = dr)
cal
#> <scr_pd_calibration> method intercept | CT 9.632% (scr_dr long-run average (8 quarterly cohorts)) | sample rate 14.500% | n 1,400
#>   event ln(odds)* = -0.448504 +1.000000 * ln(odds)   [prior shift -0.464482]
#>   alignment: I 0.141187 -> 0.589690 | S -0.912143 -> -0.912143
#>   mean PD 13.699% -> 9.632% | AR observed 0.4788 -> 0.4788 | AR implied 0.5207 -> 0.5259
```

Four methods are available. `"intercept"` is the prior-correction shift
of King and Zeng, refined by a one-dimensional root so that the mean PD
equals the CT exactly; the slope is untouched, so every rank statistic
is untouched. `"logodds_ab"` and `"qmm"` fit both intercept and slope of
`ln(odds*) = a + b ln(odds)`, the first to a target accuracy ratio, the
second to the accuracy ratio implied by the PDs themselves. `"scaling"`
is the proportional rescaling `PD * CT / ybar`, projected back onto a
logit map. All four hit the CT; only the slope differs, and a monotone
map of the ln(odds) never changes the AUC of the hold-out.

``` r

ho <- sc$samples$holdout
auc_score <- sc$metrics[sample == "holdout", auc]
compare <- rbindlist(lapply(c("intercept", "logodds_ab", "qmm", "scaling"), function(m) {
  cm <- scr_calibrate(sc, target = dr, method = m)
  p  <- predict(cm$alignment, ho$link, type = "prob")
  data.table(method = m, mean_pd_before = cm$mean_pd_before, mean_pd_after = cm$mean_pd_after,
             slope_ratio = cm$slope_ratio, auc_before = auc_score,
             auc_after = scr_metrics(p, ho$y, ci = FALSE)$auc)
}))
compare
#>        method mean_pd_before mean_pd_after slope_ratio auc_before auc_after
#>        <char>          <num>         <num>       <num>      <num>     <num>
#> 1:  intercept      0.1369896    0.09631563   1.0000000   0.739406  0.739406
#> 2: logodds_ab      0.1369896    0.09631563   0.8847832   0.739406  0.739406
#> 3:        qmm      0.1369896    0.09631563   0.9869091   0.739406  0.739406
#> 4:    scaling      0.1369896    0.09631563   0.9475886   0.739406  0.739406
```

## 3. Rating grades

[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md)
cuts the production score into grades whose PD is monotone. The default
construction is `"geometric"`: a master scale is built between the 1st
and the 99th percentile of the calibrated PD, every grade doubling (or
multiplying by the ratio) the PD of the one before, and its PD
boundaries are converted into score cut points through the calibrated
alignment. Grade 1 is the safest, the highest scores under
`higher_is_safer`. Grades with fewer than `min_obligors` obligors or
`min_defaults` defaults are merged with the neighbour of closer default
rate; the sequence of grade PDs is then repaired by
pool-adjacent-violators when it is not monotone. Every merge is recorded
in `repairs`.

``` r

gr <- scr_grades(sc, cal, n_grades = 7, min_obligors = 30, min_defaults = 10)
gr
#> <scr_grades> target "default" | 5 grades (geometric) on holdout | PD source: lra | higher_is_safer
#>   concentration: HHI 0.241 | CV 0.452 | HI 0.116 | repairs 2 | calibrated to CT 9.632%
#>   grade label    score_lo  score_hi      n  share   def       dr  pd_mean    pd_be
#>   1     1+2+3      571.27       Inf    341  24.4%    13    3.81%    1.85%    3.81%
#>   2     4          548.82    571.27    382  27.3%    32    8.38%    5.01%    8.38%
#>   3     5          525.01    548.82    403  28.8%    72   17.87%   10.13%   17.87%
#>   4     6          497.66    525.01    208  14.9%    63   30.29%   20.46%   30.29%
#>   5     7            -Inf    497.66     66   4.7%    23   34.85%   39.43%   34.85%
#>   repair (min_counts): 1 -> 2 | n 42, defaults 1 (minimum 30 / 10)
#>   repair (min_counts): 1+2 -> 3 | n 139, defaults 4 (minimum 30 / 10)
gr$master_scale
#> <scr_master_scale> 7 grades (geometric) | ratio between midpoints 2.095
#>   grade  label         pd_lo     pd_mid      pd_hi
#>   1      1            0.000%     0.526%     0.761%
#>   2      2            0.761%     1.102%     1.595%
#>   3      3            1.595%     2.308%     3.341%
#>   4      4            3.341%     4.835%     6.999%
#>   5      5            6.999%    10.129%    14.661%
#>   6      6           14.661%    21.219%    30.712%
#>   7      7           30.712%    44.451%   100.000%
gr$repairs
#>          step merged   into                              reason
#>        <char> <char> <char>                              <char>
#> 1: min_counts      1      2  n 42, defaults 1 (minimum 30 / 10)
#> 2: min_counts    1+2      3 n 139, defaults 4 (minimum 30 / 10)
```

Seven grades were asked for and five survive: the two safest grades of
the scale hold too few defaults on the hold-out and are folded into the
third. Concentration is reported as the Herfindahl index of the grade
shares, the coefficient of variation of the shares and the
Herfindahl-based `hi` index, the three numbers the stability test of
section 6 compares against.

``` r

unlist(gr$concentration)
#>       hhi        cv        hi         k 
#> 0.2409357 0.4524142 0.1157005 5.0000000
```

A master scale can also be supplied, when the institution already has
one.
[`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md)
builds it from the first and last midpoints (or from supplied midpoints
or bands); `method = "supplied"` grades by its PD bands and keeps its
labels through the merges.

``` r

ms <- scr_master_scale(0.005, 0.40, n_grades = 8)
ms
#> <scr_master_scale> 8 grades (geometric) | ratio between midpoints 1.870
#>   grade  label         pd_lo     pd_mid      pd_hi
#>   1      1            0.000%     0.500%     0.684%
#>   2      2            0.684%     0.935%     1.279%
#>   3      3            1.279%     1.749%     2.391%
#>   4      4            2.391%     3.270%     4.472%
#>   5      5            4.472%     6.116%     8.363%
#>   6      6            8.363%    11.437%    15.641%
#>   7      7           15.641%    21.389%    29.250%
#>   8      8           29.250%    40.000%   100.000%
gs <- scr_grades(sc, cal, method = "supplied", master_scale = ms, min_defaults = 10)
gs$table[, .(grade, label, score_lo, score_hi, n, defaults, dr, pd_be)]
#>    grade   label score_lo score_hi     n defaults         dr      pd_be
#>    <int>  <char>    <num>    <num> <int>    <int>      <num>      <num>
#> 1:     1 1+2+3+4 562.5195      Inf   480       16 0.03333333 0.03333333
#> 2:     2       5 543.2569 562.5195   355       41 0.11549296 0.11549296
#> 3:     3       6 522.8067 543.2569   318       66 0.20754717 0.20754717
#> 4:     4       7 499.6677 522.8067   174       55 0.31609195 0.31609195
#> 5:     5       8     -Inf 499.6677    73       25 0.34246575 0.34246575
gs$repairs
#>          step merged   into                              reason
#>        <char> <char> <char>                              <char>
#> 1: min_counts      1      2  n 34, defaults 1 (minimum 30 / 10)
#> 2: min_counts    1+2      3 n 106, defaults 4 (minimum 30 / 10)
#> 3: min_counts  1+2+3      4 n 239, defaults 7 (minimum 30 / 10)
```

### The two-pass path: grade PDs from the cohort series

So far `pd_be` is the default rate of the grade on the hold-out, one
sample again. The grade PD should be the long-run average of the grade’s
own cohort default rates, and that series can only be built once the
grades exist. Hence two passes: grade the cohort panel with the cut
points of the first call, build the series by grade with
[`scr_default_rate()`](https://evandeilton.github.io/scorecraft/reference/scr_default_rate.md),
and pass it as `dr` to a second call with identical arguments. The cut
points are the same; only the source of `pd_be` changes, and the ledger
says so.

``` r

pnl <- merge(d$flags, as.data.table(scr_demo_panel)[, .(id, date = ref_date, score)],
             by = c("id", "date"))
pnl[, grade := predict(gr, score = score)]
drg <- scr_default_rate(pnl, id = "id", date = "date", default = "default",
                        grade = "grade", by = "quarter", config = cfg)
head(drg$table, 5)
#>        cohort  grade     n defaults         dr
#>        <Date> <char> <int>    <int>      <num>
#> 1: 2023-01-01      1   401       20 0.04987531
#> 2: 2023-01-01      2    73        6 0.08219178
#> 3: 2023-01-01      3    44        8 0.18181818
#> 4: 2023-01-01      4    54       12 0.22222222
#> 5: 2023-01-01      5    28       13 0.46428571
gr2 <- scr_grades(sc, cal, n_grades = 7, min_obligors = 30, min_defaults = 10, dr = drg)
identical(gr2$breaks, gr$breaks)
#> [1] TRUE
gr2$table[, .(grade, label, n, dr, pd_mean, pd_be, n_series, t_series)]
#>    grade  label     n         dr    pd_mean      pd_be n_series t_series
#>    <int> <char> <int>      <num>      <num>      <num>    <int>    <int>
#> 1:     1  1+2+3   341 0.03812317 0.01850543 0.04661908     3151        8
#> 2:     2      4   382 0.08376963 0.05006927 0.14443910      557        8
#> 3:     3      5   403 0.17866005 0.10129601 0.16957030      324        8
#> 4:     4      6   208 0.30288462 0.20460388 0.21934765      391        8
#> 5:     5      7    66 0.34848485 0.39432077 0.40823352      185        8
gr2$ledger[action == "grade_pd_source", detail]
#> [1] "grade PD from the long-run average of 8 cohorts (quarter)"
```

## 4. Margin of conservatism, floor and the PD model

[`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md)
appends entries to the margin-of-conservatism ledger of the grades.
Category `C`, the general estimation error, is quantified from the data:
`"ci_timeseries"` takes the one-sided `t` interval of the long-run
average over the cohort series, per grade; `"ci_binomial"` and
`"bootstrap"` work on the obligors when no series exists. Categories `A`
(data and methodological deficiencies) and `B` (changes in standards or
environment) are expert quantities: a value in PD units and a non-empty
reason are both mandatory. The ledger is append-only: `A` and `B`
entries accumulate, a new `C` supersedes the previous one, which stays
in the ledger with `active = FALSE`.

``` r

gm <- scr_moc(gr2, "C", method = "ci_timeseries", dr = drg)
gm <- scr_moc(gm, "A", value = 0.001,
              reason = "unlikeliness-to-pay trigger not available before 2024")
gm
#> <scr_grades> target "default" | 5 grades (geometric) on holdout | PD source: lra | higher_is_safer
#>   concentration: HHI 0.241 | CV 0.452 | HI 0.116 | repairs 2 | calibrated to CT 9.632%
#>   grade label    score_lo  score_hi      n  share   def       dr  pd_mean    pd_be
#>   1     1+2+3      571.27       Inf    341  24.4%    13    3.81%    1.85%    4.66%
#>   2     4          548.82    571.27    382  27.3%    32    8.38%    5.01%   14.44%
#>   3     5          525.01    548.82    403  28.8%    72   17.87%   10.13%   16.96%
#>   4     6          497.66    525.01    208  14.9%    63   30.29%   20.46%   21.93%
#>   5     7            -Inf    497.66     66   4.7%    23   34.85%   39.43%   40.82%
#>   repair (min_counts): 1 -> 2 | n 42, defaults 1 (minimum 30 / 10)
#>   repair (min_counts): 1+2 -> 3 | n 139, defaults 4 (minimum 30 / 10)
#>   margin of conservatism (active, mean over grades): C 248.2 bp | A 10.0 bp
```

[`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md)
assembles the PD model: `pd_moc = pd_be + A + B + C`, then the floor of
the asset class under the framework of `params`, and
`pd_final = max(pd_moc, floor)`.
[`scr_irb_params()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_params.md)
is a table of numbers selected by a preset; the floors are one of its
tables, editable, and an edited table is flagged in the ledger.

``` r

prm <- scr_irb_params("bcb")
prm$pd_floor
#>        asset_class floor
#>             <char> <num>
#> 1:       corporate 5e-04
#> 2:            bank 5e-04
#> 3:       sovereign    NA
#> 4: retail_mortgage 5e-04
#> 5: qrre_transactor 5e-04
#> 6:   qrre_revolver 1e-03
#> 7:    retail_other 5e-04
pd <- scr_pd(gm, params = prm, asset_class = "retail_other")
pd
#> <scr_pd> target "default" | bcb | retail_other | floor 0.05% | 5 grades | ttc
#>   calibration: intercept to CT 9.632% | grades: geometric, PD source lra | HHI 0.241
#>   grade  score_lo  score_hi      n    pd_be   moc_a   moc_b   moc_c   pd_moc pd_final floor
#>   1        571.27       Inf    341    4.66%    10.0     0.0    65.5    5.42%    5.42%      
#>   2        548.82    571.27    382   14.44%    10.0     0.0   383.2   18.38%   18.38%      
#>   3        525.01    548.82    403   16.96%    10.0     0.0   168.2   18.74%   18.74%      
#>   4        497.66    525.01    208   21.93%    10.0     0.0   262.8   24.66%   24.66%      
#>   5          -Inf    497.66     66   40.82%    10.0     0.0   361.1   44.53%   44.53%      
#>   portfolio: PD_BE 15.141% | MoC 235.0 bp (A/B/C in bp) | PD_final 17.491% | 0.0% of obligors at the floor
```

The floor does not bind on this portfolio, whose safest grade sits above
5 %. The table carries every intermediate column, so a validator can
follow the number from the sample default rate to the final PD:

``` r

pd$table[, .(grade, label, n, dr, pd_be, moc_a, moc_c, pd_moc, floor, pd_final, floor_applied)]
#>    grade  label     n         dr      pd_be moc_a       moc_c     pd_moc floor
#>    <int> <char> <int>      <num>      <num> <num>       <num>      <num> <num>
#> 1:     1  1+2+3   341 0.03812317 0.04661908 0.001 0.006554451 0.05417353 5e-04
#> 2:     2      4   382 0.08376963 0.14443910 0.001 0.038315668 0.18375476 5e-04
#> 3:     3      5   403 0.17866005 0.16957030 0.001 0.016817727 0.18738803 5e-04
#> 4:     4      6   208 0.30288462 0.21934765 0.001 0.026282240 0.24662989 5e-04
#> 5:     5      7    66 0.34848485 0.40823352 0.001 0.036112137 0.44534566 5e-04
#>      pd_final floor_applied
#>         <num>        <lgcl>
#> 1: 0.05417353         FALSE
#> 2: 0.18375476         FALSE
#> 3: 0.18738803         FALSE
#> 4: 0.24662989         FALSE
#> 5: 0.44534566         FALSE
```

## 5. Production: R and SQL agree

[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
scores new rows with the scorecard and adds the grade, the calibrated
individual PD and the grade PD;
[`predict()`](https://rdrr.io/r/stats/predict.html) does the same from a
vector of scores. The production SQL of the PD model is the SQL of the
scorecard plus one block: a `CASE` over the score cut points for the
grade and another for the final PD.

``` r

new <- head(scr_demo, 5)
scr_apply(pd, new)
#>       score score_points grade         pd     pd_be  pd_final
#>       <num>        <num> <int>      <num>     <num>     <num>
#> 1: 546.5330          546     3 0.07533388 0.1695703 0.1873880
#> 2: 562.3290          562     2 0.04500420 0.1444391 0.1837548
#> 3: 560.5217          559     2 0.04777441 0.1444391 0.1837548
#> 4: 507.0636          507     4 0.24239419 0.2193476 0.2466299
#> 5: 536.7619          536     3 0.10258165 0.1695703 0.1873880
predict(pd, score = c(480, 560, 640), type = "pd_final")
#> [1] 0.44534566 0.18375476 0.05417353
```

``` r

sql <- scr_sql(pd, table = "customers", dialect = "duckdb")
cat(tail(sql, 6), sep = "\n")
#> -- Block 4: rating grade and final PD from the score cut points (5 grades, higher_is_safer)
#> SELECT
#>     s.*,
#>     CASE WHEN score <= 497.65810792199238 THEN 5 WHEN score <= 525.006786354523 THEN 4 WHEN score <= 548.82434894947983 THEN 3 WHEN score <= 571.2740854703145 THEN 2 ELSE 1 END AS grade,
#>     CASE WHEN score <= 497.65810792199238 THEN 0.44534566116911861 WHEN score <= 525.006786354523 THEN 0.24662988720215417 WHEN score <= 548.82434894947983 THEN 0.1873880268001506 WHEN score <= 571.2740854703145 THEN 0.18375476313787917 ELSE 0.054173526552942053 END AS pd_final
#> FROM score_scr s;
```

When DuckDB is installed the SQL is run on a few hundred rows and
compared with
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md):
the score, the grade and the final PD are the same numbers.

``` r

con <- DBI::dbConnect(duckdb::duckdb(), config = list(threads = "1"))
DBI::dbWriteTable(con, "customers", head(scr_demo, 300))
got <- DBI::dbGetQuery(con, paste(sql, collapse = "\n"))
DBI::dbDisconnect(con, shutdown = TRUE)
exp <- scr_apply(pd, head(scr_demo, 300))
head(got[, c("score", "grade", "pd_final")], 3)
#>      score grade  pd_final
#> 1 546.5330     3 0.1873880
#> 2 562.3290     2 0.1837548
#> 3 560.5217     2 0.1837548
all.equal(got$score, exp$score)
#> [1] TRUE
identical(as.integer(got$grade), exp$grade)
#> [1] TRUE
all.equal(got$pd_final, exp$pd_final)
#> [1] TRUE
```

## 6. Validation on the cohort panel

[`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md)
runs the standard battery on a monthly panel with the default flag and
the grade at every month, building the cohorts exactly as
[`scr_default_rate()`](https://evandeilton.github.io/scorecraft/reference/scr_default_rate.md)
does. The panel is graded with the cut points of the PD model through
[`predict()`](https://rdrr.io/r/stats/predict.html), the same path the
production SQL follows.

- **Calibration**, per grade pooled over cohorts and per cohort: the
  Jeffreys test, the binomial test with its critical count, the normal
  `z`, the traffic light on the Jeffreys p-value; for the portfolio, the
  same tests on the totals, Hosmer-Lemeshow over the grades, the
  multi-period test over the cohort default rates and the Brier score.
- **Discrimination**: AUC, Gini and KS with a bootstrap interval on the
  score, and the `S` statistic against the development AUC.
- **Stability**: the PSI of the grade distribution per cohort against
  the development sample, the migration matrix pooled over the cohorts,
  and the concentration test on the coefficient of variation.

``` r

pnl[, grade := predict(pd, score = score)]
v <- scr_pd_validate(pd, pnl, id = "id", date = "date", default = "default",
                     grade = "grade", score = "score", by = "quarter")
v
#> <scr_pd_validation> target "default" | 8 quarterly cohorts, 12-month window | overall light: RED
#>   portfolio: N 4,608 | D 444 | DR 9.64% vs pd_final 11.12% | Jeffreys p 0.9995 | binomial p 0.9995 (critical 549) | HL chi2 12.51 (p 0.0058) | multi-period z -10.09
#>   grade       n     d       dr       pd    p_jeff   p_binom light 
#>   1        3151   147    4.67%    5.42%    0.9711    0.9737 green 
#>   2         557    80   14.36%   18.38%    0.9940    0.9949 green 
#>   3         324    55   16.98%   18.74%    0.7906    0.8110 green 
#>   4         391    86   21.99%   24.66%    0.8905    0.9014 green 
#>   5         185    76   41.08%   44.53%    0.8276    0.8459 green 
#>   discrimination (score): AUC 0.7564 [0.7308, 0.7723] vs initial 0.7394 | S -1.24, p 0.8925 | KS 0.4027
#>   stability: grade PSI 0.9634 (shift, adjusted shift) at cohort 2024-10-01 | MWB up - / down - | CV 1.245 vs 0.452 (p 0.1869)
```

The summary is one row per test with its statistic, p-value and light;
the overall light is the worst of them.

``` r

v$summary
#>                    test     level    statistic     p_value  light
#>                  <char>    <char>        <num>       <num> <char>
#>  1:            jeffreys portfolio   0.09635417 0.999469436  green
#>  2: jeffreys_grades_red     grade   0.00000000 0.790585046  green
#>  3:            binomial portfolio 549.00000000 0.999513515  green
#>  4:              normal portfolio  -3.21341063 0.999344157  green
#>  5:     hosmer_lemeshow portfolio  12.51211309 0.005819772    red
#>  6:        multi_period portfolio -10.09450041 1.000000000  green
#>  7:      auc_vs_initial portfolio  -1.23990837 0.892495357  green
#>  8:          psi_grades portfolio   0.96337125          NA    red
#>  9: migration_mwb_upper portfolio           NA          NA   <NA>
#> 10:    concentration_cv portfolio   1.24524312 0.186941092  green
```

Two reds, and both are readable. The one-sided tests are green on every
grade because the tested PD is `pd_final`, which carries the margin of
conservatism: the observed default rates sit below it, as they should.
Hosmer-Lemeshow is two-sided and charges that same conservatism as
miscalibration, which is why it is reported next to the one-sided tests
and not instead of them. The grade PSI is large because the panel is a
different population from the development sample: its behavioural score
puts two thirds of the obligors in grade 1 where the hold-out had a
quarter. That is exactly what the PSI is there to flag; a validator
would now ask whether the cut points belong on that population at all.

``` r

v$portfolio[, .(cohort, n, d, pd, dr, p_jeffreys, light)]
#>        cohort     n     d        pd         dr p_jeffreys  light
#>        <Date> <int> <int>     <num>      <num>      <num> <char>
#> 1: 2023-01-01   600    59 0.1152841 0.09833333  0.9053676  green
#> 2: 2023-04-01   590    59 0.1136764 0.10000000  0.8528388  green
#> 3: 2023-07-01   572    55 0.1101949 0.09615385  0.8589652  green
#> 4: 2023-10-01   570    53 0.1107401 0.09298246  0.9141923  green
#> 5: 2024-01-01   572    53 0.1105423 0.09265734  0.9163369  green
#> 6: 2024-04-01   574    59 0.1109179 0.10278746  0.7289322  green
#> 7: 2024-07-01   565    51 0.1093999 0.09026549  0.9304551  green
#> 8: 2024-10-01   565    55 0.1088252 0.09734513  0.8084906  green
head(v$stability$psi, 3)
#>        cohort     n       psi flag_fixed   critical flag_adjusted
#>        <Date> <int>     <num>     <char>      <num>        <char>
#> 1: 2023-01-01   600 0.8735703      shift 0.02258983         shift
#> 2: 2023-04-01   590 0.8909743      shift 0.02285785         shift
#> 3: 2023-07-01   572 0.9232355      shift 0.02336389         shift
```

### Migration

[`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md)
counts the obligors in grade `i` at the cohort start and grade `j`
twelve months later, with defaults and closed accounts in their own
columns, and reports the upper and lower matrix-weighted bandwidths, the
`z` of every off-diagonal cell against its neighbour closer to the
diagonal, and the mobility summary. The validation pools it over the
cohorts whose end date is observed. On this panel the matrix is
diagonal: the behavioural score of `scr_demo_panel` is constant per
obligor, so an obligor either stays in its grade or defaults, and the
bandwidths are undefined for want of a single move.

``` r

v$stability$migration
#> <scr_migration> 5 grades | 4,608 obligors | stable 100.0% | up 0.0% | down 0.0% | default 9.6% | closed 0.0%
#>   MWB upper - | MWB lower - | mean distance 0.000 | 0 cell(s) not decaying from the diagonal (z > 1.645)
#>   from        1       2       3       4       5 default  closed 
#>   1       95.3%    0.0%    0.0%    0.0%    0.0%    4.7%    0.0% 
#>   2        0.0%   85.6%    0.0%    0.0%    0.0%   14.4%    0.0% 
#>   3        0.0%    0.0%   83.0%    0.0%    0.0%   17.0%    0.0% 
#>   4        0.0%    0.0%    0.0%   78.0%    0.0%   22.0%    0.0% 
#>   5        0.0%    0.0%    0.0%    0.0%   58.9%   41.1%    0.0%
```

On a panel where grades move, the same function on two grade vectors
gives the full reading:

``` r

set.seed(2)
g0 <- pnl[date == as.Date("2023-01-01"), grade]
g1 <- pmin(5L, pmax(1L, g0 + sample(c(-1L, 0L, 0L, 0L, 1L), length(g0), TRUE)))
g1[sample(length(g1), 25)] <- NA
scr_migration(g0, g1, K = 5)
#> <scr_migration> 5 grades | 600 obligors | stable 71.0% | up 22.3% | down 6.8% | default 0.0% | closed 4.2%
#>   MWB upper 0.2718 | MWB lower 0.3250 | mean distance 0.290 | 0 cell(s) not decaying from the diagonal (z > 1.645)
#>   from        1       2       3       4       5 default  closed 
#>   1       71.8%   23.4%    0.0%    0.0%    0.0%    0.0%    4.7% 
#>   2       20.5%   57.5%   19.2%    0.0%    0.0%    0.0%    2.7% 
#>   3        0.0%   11.4%   70.5%   15.9%    0.0%    0.0%    2.3% 
#>   4        0.0%    0.0%   20.4%   53.7%   24.1%    0.0%    1.9% 
#>   5        0.0%    0.0%    0.0%   28.6%   64.3%    0.0%    7.1%
```

### The point-in-time view

The grade PDs above are through-the-cycle: the long-run average with a
margin.
[`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md)
is Vasicek’s one-factor bridge between that PD and the conditional PD of
a given state of the systematic factor `z` (negative for a stressed
year, positive for a benign one), with the asset correlation `rho`; the
map is invertible. `scr_pd(philosophy = "pit")` applies it before the
floor.

``` r

rho <- scr_irb_params("bcb")$correlation$retail_other[["lo"]]
pit <- scr_pd_pit_ttc(pd$table$pd_final, z = -1, rho = rho)
data.table(grade = pd$table$grade, pd_ttc = pd$table$pd_final, pd_pit_stressed = pit,
           back_to_ttc = scr_pd_pit_ttc(pit, z = -1, rho = rho, to = "ttc"))
#>    grade     pd_ttc pd_pit_stressed back_to_ttc
#>    <int>      <num>           <num>       <num>
#> 1:     1 0.05417353       0.0729115  0.05417353
#> 2:     2 0.18375476       0.2299188  0.18375476
#> 3:     3 0.18738803       0.2341278  0.18738803
#> 4:     4 0.24662989       0.3016069  0.24662989
#> 5:     5 0.44534566       0.5144882  0.44534566
pd_pit <- scr_pd(gm, params = prm, philosophy = "pit", rho = rho, z = -1)
pd_pit$table[, .(grade, pd_ttc, pd_pit, pd_final)]
#>    grade     pd_ttc    pd_pit  pd_final
#>    <int>      <num>     <num>     <num>
#> 1:     1 0.05417353 0.0729115 0.0729115
#> 2:     2 0.18375476 0.2299188 0.2299188
#> 3:     3 0.18738803 0.2341278 0.2341278
#> 4:     4 0.24662989 0.3016069 0.3016069
#> 5:     5 0.44534566 0.5144882 0.5144882
```

## 7. Deliverables

[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
writes the PD workbook and the SQL file. With the validation supplied
the workbook carries the test sheets; without it the sheets exist with
an availability row, never a fabricated number.

``` r

out <- file.path(tempdir(), "scorecraft-pd-vignette")
ex <- scr_export(pd, out, stamp = FALSE, validation = v)
#>   /tmp/Rtmpfd6Bfg/scorecraft-pd-vignette/pd_default.xlsx
#>   /tmp/Rtmpfd6Bfg/scorecraft-pd-vignette/sql_pd_default.sql
basename(unlist(ex$files))
#> [1] "pd_default.xlsx"    "sql_pd_default.sql"
openxlsx::getSheetNames(ex$files$pd)
#>  [1] "PD_Grades"                 "Master_Scale"             
#>  [3] "Calibration"               "MoC_Ledger"               
#>  [5] "Floors"                    "Grade_Series"             
#>  [7] "Validation_Calibration"    "Validation_Cohorts"       
#>  [9] "Validation_Discrimination" "Validation_Stability"     
#> [11] "Validation_Summary"        "Migration"                
#> [13] "Decision_Ledger"           "Model_Card"
```

## 8. What the ledger recorded

Nothing in the PD model depends on a number that was typed into a script
and forgotten. The margin ledger keeps every entry with its category,
method, value and reason, active or superseded; the grade repairs keep
every merge with the count that forced it; the decision ledger of the
model strings the stages together.

``` r

pd$moc_ledger[, .(id, category, method, level, grade, value, reason, active)]
#>        id category        method level grade       value
#>     <int>   <char>        <char> <num> <int>       <num>
#>  1:     1        C ci_timeseries  0.95     1 0.006554451
#>  2:     1        C ci_timeseries  0.95     2 0.038315668
#>  3:     1        C ci_timeseries  0.95     3 0.016817727
#>  4:     1        C ci_timeseries  0.95     4 0.026282240
#>  5:     1        C ci_timeseries  0.95     5 0.036112137
#>  6:     2        A        manual    NA     1 0.001000000
#>  7:     2        A        manual    NA     2 0.001000000
#>  8:     2        A        manual    NA     3 0.001000000
#>  9:     2        A        manual    NA     4 0.001000000
#> 10:     2        A        manual    NA     5 0.001000000
#>                                                    reason active
#>                                                    <char> <lgcl>
#>  1:      estimation error, ci_timeseries at 95% one-sided   TRUE
#>  2:      estimation error, ci_timeseries at 95% one-sided   TRUE
#>  3:      estimation error, ci_timeseries at 95% one-sided   TRUE
#>  4:      estimation error, ci_timeseries at 95% one-sided   TRUE
#>  5:      estimation error, ci_timeseries at 95% one-sided   TRUE
#>  6: unlikeliness-to-pay trigger not available before 2024   TRUE
#>  7: unlikeliness-to-pay trigger not available before 2024   TRUE
#>  8: unlikeliness-to-pay trigger not available before 2024   TRUE
#>  9: unlikeliness-to-pay trigger not available before 2024   TRUE
#> 10: unlikeliness-to-pay trigger not available before 2024   TRUE
pd$repairs
#>          step merged   into                              reason
#>        <char> <char> <char>                              <char>
#> 1: min_counts      1      2  n 42, defaults 1 (minimum 30 / 10)
#> 2: min_counts    1+2      3 n 139, defaults 4 (minimum 30 / 10)
pd$ledger[, .(action, detail)]
#>             action
#>             <char>
#> 1: grade_pd_source
#> 2:          grades
#> 3:           moc_C
#> 4:           moc_A
#> 5:        pd_floor
#> 6:        pd_model
#>                                                                                                                            detail
#>                                                                                                                            <char>
#> 1:                                                                      grade PD from the long-run average of 8 cohorts (quarter)
#> 2: 5 grades (geometric, from 7) on sample holdout | min obligors 30, min defaults 10 | 2 merge(s) | HHI 0.241, CV 0.452, HI 0.116
#> 3:                                               ci_timeseries | mean 248.2 bp | estimation error, ci_timeseries at 95% one-sided
#> 4:                                                  manual | mean 10.0 bp | unlikeliness-to-pay trigger not available before 2024
#> 5:                                                                                             PD floor 0.05% (retail_other, bcb)
#> 6:                                       5 grades | portfolio PD 15.141% -> 17.491% (MoC 235.0 bp) -> 17.491% | 0.0% at the floor
```
