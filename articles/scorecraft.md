# scorecraft: from raw table to production SQL and monitoring

This vignette takes one target from a raw table to a scorecard, a
cut-off policy, production SQL checked against R, a monitoring run and
the deliverables. It runs on `scr_demo`, a synthetic table built with
the defects real data has: the sentinel `-999`, missing values,
constants, duplicates, a redundant pair, high cardinality, pure noise
and a column (`vl_late`) that degrades in the last period only. Two
companion vignettes go deeper:
[`vignette("coarse-classing", package = "scorecraft")`](https://evandeilton.github.io/scorecraft/articles/coarse-classing.md)
on manual binning with an audit trail, and
[`vignette("alignment-and-portfolio", package = "scorecraft")`](https://evandeilton.github.io/scorecraft/articles/alignment-and-portfolio.md)
on the points scale.

## 1. Configuration

One
[`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md)
object drives every stage. A preset fixes the admission rules of the
funnel;
[`scr_presets()`](https://evandeilton.github.io/scorecraft/reference/scr_presets.md)
lists them and
[`scr_config_keys()`](https://evandeilton.github.io/scorecraft/reference/scr_config_keys.md)
documents every key.

``` r

library(scorecraft)
library(data.table)
#> 
#> Attaching package: 'data.table'
#> The following object is masked from 'package:base':
#> 
#>     %notin%
scr_presets()[, c("preset", "target_max", "min_votes", "corr_cutoff", "iv_min")]
#>       preset target_max min_votes corr_cutoff iv_min
#> 1 aggressive         15         3         0.6   0.03
#> 2   moderate         25         2         0.7   0.02
#> 3       lazy         40         1         0.8   0.02
```

The overrides below only make the run light: one thread, two consensus
voters (elastic net and xgboost), a short boosting schedule and twenty
bootstrap resamples. A development run would keep the defaults.

``` r

cfg <- scr_config("moderate", objective = "risk", verbose = FALSE, nthread = 1,
                  use_glmnet = TRUE, use_ranger = FALSE, use_lightgbm = FALSE,
                  xgb_rounds = 60, n_boot = 20)
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
#>   bootstrap CI           20 resamples, 95%
#> 
#> Data
#>   sentinels              -999
#>   derived at the end     no (diagnostic only)
#>   hold-out               30.0%
#> 
#> Models
#>   enabled                glmnet, xgboost
#>   row cap                200,000
```

## 2. Selection and the funnel

[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
chains the split, the triage, the optimal binning with screening and
hold-out revalidation, the redundancy pruning and the consensus of the
models. Each stage is also exported on its own
([`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md)).
With `date_col` the split is out-of-time by whole periods: the last
periods form the hold-out. The sibling target `churn` is dropped so that
it cannot become a candidate.

``` r

res <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                  date_col = "ref_date")
res
#> <scr_result> target "default"
#>   4,200 rows (train 2,800 / hold-out 1,400) | split out-of-time at 2026-05-01
#>   event: 14.25% on train, 14.50% on hold-out | 0.9s
#>   convention: risk (target=1 is the bad case)
#> 
#> Funnel
#>   candidates        37 ############################
#>   1. triage         37 ############################
#>   2. binning        37 ############################
#>   3. screening      20 ###############
#>   4. hold-out       16 ############
#>   5. correlation    12 #########
#>   6. consensus      12 #########
#> 
#> Approved: 12
#>    1. vl_score_01                                  IV  0.346  KS 0.198
#>    2. vl_score_02                                  IV  0.172  KS 0.156
#>    3. vl_score_04                                  IV  0.124  KS 0.120
#>    4. ds_band                                      IV  0.081  KS 0.110
#>    5. vl_late                                      IV  0.071  KS 0.120
#>   ... (+7) - scr_selected() for the list
#> 
#> Models (hold-out)
#>   glmnet    AUC 0.7345 [0.7028, 0.7723]  KS 0.3842
#>   xgboost   AUC 0.7375 [0.7065, 0.7762]  KS 0.3695
#> 
#> Warnings
#>   - 3 derived flag(s) outside the deliverable by policy (allow_derived_final)
```

Binning works on the weight of evidence. For bin $`i`$ of a variable,
with $`e_i`$ events and $`n_i`$ non-events out of totals $`E`$ and
$`N`$,

``` math
\mathrm{WOE}_i = \ln\frac{e_i / E}{n_i / N}, \qquad
\mathrm{IV} = \sum_i \left(\frac{e_i}{E} - \frac{n_i}{N}\right)\mathrm{WOE}_i .
```

The WOE is the log of the event share over the non-event share, so a bin
riskier than average has a positive WOE. This is the opposite sign to
the good-over-bad convention of Siddiqi (2017); under it the logistic
coefficients on the WOE columns are expected to be positive, and the
sign check of the scorecard tests exactly that. The preset admits an IV
in $`[0.02, 1)`$ and warns from 0.5, where leakage is more likely than
signal.

The funnel is the audit trail: every input column, the stage it left at
and why. No candidate is dropped from the report.

``` r

table(scr_funnel(res, cols = "all")$exit_stage)
#> 
#>            00.config            01.triage         03.screening 
#>                    3                    7                   17 
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
#> 4:     ds_band 0.08054551 0.07804157 0.1100565 0.001317467            stable
#> 5:     vl_late 0.07109472 0.06384879 0.1201400 0.104196466             shift
#> 6:   ds_region 0.08464808 0.09714339 0.1141337 0.006365199            stable
```

`vl_late` is approved, but its PSI between train and hold-out is already
flagged as a shift. Section 8 shows where that comes from.

## 3. The scorecard

[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
fits a logistic regression on the WOE columns of the shortlist, checks
the signs and aligns the logit to the declared scale: 600 points at odds
of 50:1 (non-event to event), doubling every 20 points. How the
alignment and the points are computed is the subject of the alignment
vignette.

``` r

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
all(sc$sign_check$coef > 0)
#> [1] TRUE
scr_score_metrics(sc)[, .(sample, auc, auc_lo, auc_hi, ks, gini)]
#>     sample       auc    auc_lo    auc_hi        ks      gini
#>     <char>     <num>     <num>     <num>     <num>     <num>
#> 1:   train 0.7856428 0.7662170 0.8069608 0.4411466 0.5712856
#> 2: holdout 0.7394060 0.7066284 0.7770357 0.3889033 0.4788120
```

Every discrimination figure carries a bootstrap interval. The hold-out
figures, not the training ones, are the ones to quote.

## 4. Cut-off and strategy

### The sweep

[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md)
takes candidate cuts at quantiles of the score **on train** and applies
them **frozen** to the hold-out, so both samples answer the same
question at the same score.

``` r

ct <- scr_cutoff(sc, n_cuts = 8)
ct
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
ct$table[cut == ct$cuts[4], .(sample, cut, pct_safe, event_rate_safe, events_avoided_pct, ks_at_cut)]
#>     sample   cut  pct_safe event_rate_safe events_avoided_pct ks_at_cut
#>     <char> <num>     <num>           <num>              <num>     <num>
#> 1:   train   546 0.5560714      0.04881182          0.8095238 0.4263501
#> 2: holdout   546 0.5564286      0.06675225          0.7438424 0.3511941
```

`%safe` is the approval rate, `ev.safe` and `ev.risky` the event rates
on each side, and `ev.avoid` the share of all events that fall on the
risky side, the events the cut would decline. `KS` at the cut is the
distance between that share and the share of non-events declined with
them. The cut with the largest KS separates the populations best; it is
not the cut the business should necessarily choose.

### The strategy table

[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md)
gives each score band (the training deciles, frozen) an expected profit
per account,
$`EP = (1 - p)\,\text{revenue\_good} - p\,\text{loss\_bad}`$, with
break-even event rate `revenue_good / (revenue_good + loss_bad)`. With
1,080 per good account and 4,500 per bad one, break-even is 19.35%. A
band below break-even is approved, one up to 25% above it goes to
review, and the rest is declined; `decisions` imposes a policy by hand.

``` r

st <- scr_strategy(sc, revenue_good = 1080, loss_bad = 4500)
st
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
st$table[, .(band, event_rate = round(event_rate, 4), decision, cum_pct = round(cum_pct, 3), cum_profit)]
#>           band event_rate decision cum_pct cum_profit
#>         <char>      <num>   <char>   <num>      <num>
#>  1: (590, Inf]     0.0318  approve   0.112     141660
#>  2:  (577,590]     0.0323  approve   0.201     253260
#>  3:  (567,577]     0.0391  approve   0.292     363600
#>  4:  (558,567]     0.0738  approve   0.399     463140
#>  5:  (550,558]     0.1216  approve   0.504     522540
#>  6:  (542,550]     0.1126  approve   0.612     590760
#>  7:  (533,542]     0.1745  approve   0.719     606600
#>  8:  (524,533]     0.2662  decline   0.818     550260
#>  9:  (510,524]     0.2734  decline   0.909     493200
#> 10: [-Inf,510]     0.3543  decline   1.000     379260
```

The lowest approved band has an event rate of 17.4%, above the portfolio
rate of 14.5%, yet a positive expected profit: declining it would look
prudent and lose money. The cumulative profit peaks at that band.
`loss_bad` is a flat loss per bad account here; in an IRB setting it is
the product of the exposure at default and the loss given default,
modelled in the article on [LGD and
EAD](https://evandeilton.github.io/scorecraft/articles/lgd-and-ead-under-irb.html)
and combined in [expected loss and
capital](https://evandeilton.github.io/scorecraft/articles/expected-loss-and-capital.html).

## 5. Reject inference

The scorecard is fitted on accounts that were accepted and therefore
have an outcome. Classical reject inference (parcelling, augmentation,
extrapolation) assigns outcomes to the declined applicants, and it
cannot be validated on the data at hand: every method rests on an
assumption about the rejects that the accepts cannot test (Hand and
Henley, 1993).
[`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md)
therefore makes no such assignment. It states the population scope,
measures the coverage of each score band and reports a sensitivity band:
the event rate each band would have if the applicants without an outcome
were 2, 4 or 8 times worse than the accepted ones in the same band.

To see the coverage problem, the hold-out vintages play the booked
accounts and an old policy is simulated on the training rows: an older
score (the new one plus noise) declined its lowest 30%, and policy rules
declined a further 5% above that cut (high-side overrides). The declined
rows form the applicants without an outcome. The booked accounts also
contain applicants below the old cut (low-side overrides), which is why
the lowest bands keep some outcomes.

``` r

set.seed(11)
train <- scr_demo[res$split$train_idx, ]
old_score <- scr_apply(sc, train)$score + stats::rnorm(nrow(train), sd = 20)
declined <- old_score < stats::quantile(old_score, 0.30) | stats::runif(nrow(train)) < 0.05
ttd <- rbind(scr_demo[res$split$holdout_idx, ], train[declined, ])
booked <- rep(c(TRUE, FALSE), c(length(res$split$holdout_idx), sum(declined)))
rj <- scr_reject(sc, population = ttd, accepted = booked)
rj
#> <scr_reject> target "default" | multipliers 2x, 4x, 8x
#>   The full population has 2,323 rows, of which 1,400 (60.3%) have an observed outcome. The rest enter only the sensitivity band, under declared multipliers.
#>   observed event rate: 14.50%
#>   implied rate if the population without outcome is 2x worse: 28.28%
#>   implied rate if the population without outcome is 4x worse: 41.84%
#>   implied rate if the population without outcome is 8x worse: 46.29%
#>   bands with weak coverage: (590, Inf] (few_events), (577,590] (few_events), (567,577] (few_events), (558,567] (few_events), (550,558] (few_events), (542,550] (few_events), (533,542] (few_events)
rj$coverage[, .(band, n_dev, n_unknown, coverage = round(coverage, 2), coverage_flag)]
#>           band n_dev n_unknown coverage coverage_flag
#>         <char> <int>     <int>    <num>        <char>
#>  1: (590, Inf]   157        12     0.93    few_events
#>  2:  (577,590]   124        13     0.91    few_events
#>  3:  (567,577]   128        15     0.90    few_events
#>  4:  (558,567]   149        32     0.82    few_events
#>  5:  (550,558]   148        49     0.75    few_events
#>  6:  (542,550]   151        73     0.67    few_events
#>  7:  (533,542]   149       105     0.59    few_events
#>  8:  (524,533]   139       149     0.48            ok
#>  9:  (510,524]   128       213     0.38            ok
#> 10: [-Inf,510]   127       262     0.33            ok
```

Coverage falls from the safest band to the riskiest, which is where the
rejects sit. `few_events` marks bands with fewer than 30 events, where
the observed rate is itself fragile, and `no_outcome` bands with none.
The `TOTAL` rows of `rj$sensitivity` are the headline: the observed rate
and what it becomes under each declared multiplier. The analyst states
the multiplier the business is prepared to defend; the package does not
choose it.

## 6. Scoring and reasons

[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
reproduces in R what the production SQL does: the frozen pre-processing
(training median for missing and sentinel values, `"MISSING"` for absent
categories), the frozen bins and the points. Nothing is refitted.

``` r

new <- head(scr_demo, 5)
scr_apply(sc, new, what = "all")[, .(prob = round(prob, 4), score = round(score, 2), score_points,
                                     vl_score_01_woe = round(vl_score_01_woe, 3), vl_score_01_points)]
#>      prob  score score_points vl_score_01_woe vl_score_01_points
#>     <num>  <num>        <num>           <num>              <num>
#> 1: 0.1089 546.53          546           0.704                -21
#> 2: 0.0628 562.33          562          -0.658                 20
#> 3: 0.0670 560.52          559           0.040                 -1
#> 4: 0.3537 507.06          507           0.040                 -1
#> 5: 0.1504 536.76          536           0.040                 -1
```

`score` is exact (`a + b * logit`); `score_points` is the sum of the
whole points of each bin, which is what a points table on paper gives.
[`scr_reasons()`](https://evandeilton.github.io/scorecraft/reference/scr_reasons.md)
returns the decline reasons: the variables whose points fall furthest
below a reference, the mean points on the training population by default
(`reference = "max"` uses the best bin).

``` r

scr_reasons(sc, new, k = 2)
#>       reason_1 shortfall_1    reason_2 shortfall_2
#>         <char>       <num>      <char>       <num>
#> 1: vl_score_01   25.197857 vl_score_02   17.828571
#> 2: vl_score_04    9.052857     vl_late    5.716071
#> 3:     vl_late   13.716071 vl_score_07    7.605357
#> 4:   ds_region   13.807143     ds_band   11.932500
#> 5: vl_score_02   17.828571 vl_score_05    9.054286
```

## 7. Production SQL

[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
on a scorecard emits three blocks: a CTE with the pre-processing frozen
on train, a CTE with the WOE and bin index from the cut points at full
precision, and the final `SELECT` with the exact score, the points per
variable and the whole-points score. `what = "all"` adds the bin label
and the WOE of every variable next to its points, and `keep_columns`
carries key columns through untransformed, so the output can be joined
back to the customer. Fourteen dialects are supported; `file` writes the
script.

``` r

sql <- scr_sql(sc, table = "prd.customers", dialect = "databricks",
               what = "all", keep_columns = c("id", "ref_date"))
length(sql)
#> [1] 441
cat(grep("^-- (Scale|score =)", sql, value = TRUE), sep = "\n")
#> -- Scale: 600 points at odds 50:1 (safe:event), PDO 20 | higher_is_safer
#> -- score = 491.19665800103655 + -26.318891476654574 * logit | base_points = 538
i <- max(which(sql == "SELECT"))
cat(sql[i:(i + 6)], sep = "\n")
#> SELECT
#>     id,
#>     ref_date,
#>     538.30012744760336
#>       + -29.701043763446282 * vl_score_01_woe
#>       + -27.130718819754311 * vl_score_02_woe
#>       + -26.649286859941228 * vl_score_04_woe
```

The claim that R and SQL agree is tested in the package; here it is also
demonstrated. DuckDB runs in-process and executes the `duckdb` dialect
on `scr_demo`.

``` r

con <- DBI::dbConnect(duckdb::duckdb(), config = list(threads = "1"))
DBI::dbWriteTable(con, "scr_demo", scr_demo)
got <- DBI::dbGetQuery(con, paste(scr_sql(sc, table = "scr_demo", dialect = "duckdb", what = "all",
                                          keep_columns = "id"), collapse = "\n"))
DBI::dbDisconnect(con, shutdown = TRUE)
got <- got[order(got$id), ]
exp <- scr_apply(sc, scr_demo, what = "all")
all.equal(got$score, exp$score)
#> [1] TRUE
identical(as.numeric(got$score_points), as.numeric(exp$score_points))
#> [1] TRUE
all(vapply(sc$features, function(f) isTRUE(all.equal(got[[paste0(f, "_points")]], exp[[paste0(f, "_points")]])) &&
             isTRUE(all.equal(got[[paste0(f, "_woe")]], exp[[paste0(f, "_woe")]])), logical(1)))
#> [1] TRUE
```

The exact score agrees to floating-point precision; the whole points and
the WOE of every variable agree for every row.

## 8. Monitoring

[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md)
scores a new table with the frozen scorecard and recomputes, per period
of `date_col`, the score PSI against the training distribution on frozen
bands, the CSI of every variable with the signed points shift and, when
the target is present, the performance by vintage. It schedules nothing.
Here the new data are `scr_demo` itself: the first four periods are the
training vintages, the last two the hold-out.

``` r

mo <- scr_monitor(sc, scr_demo, date_col = "ref_date", target = "default", n_boot = 20)
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
#>     vl_late                      2026-06-01   CSI 0.4141  shift +1.89 pts
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
```

Every PSI carries two thresholds. `fixed` is the rule of thumb of 0.10
for a moderate shift and 0.25 for action (Siddiqi, 2017), which has no
statistical derivation and ignores how many rows produced the number.
`critical` is the sample-size-adjusted value at level `alpha`: with no
shift, the PSI over $`B`$ bands from $`n`$ base and $`m`$ comparison
rows behaves like $`(1/n + 1/m)\,\chi^2_{B-1}`$ (Yurdakul and Naranjo,
2020). With 2,800 training rows, 700 rows per period and ten bands the
critical value is about 0.03, so the fixed 0.10 would let a real shift
pass unflagged.

The CSI applies the same statistic to each variable’s bins. It is
unsigned; the `points_shift` gives the direction: the change in bin
shares weighted by the points of each bin, the amount by which the
variable moved the mean score. `vl_late` is stable for five periods and
then shifts far above both thresholds:

``` r

mo$csi[variable == "vl_late", .(period, csi = round(csi, 4), flag_fixed, flag_adjusted,
                                points_shift = round(points_shift, 2))]
#>        period    csi flag_fixed flag_adjusted points_shift
#>        <char>  <num>     <char>        <char>        <num>
#> 1: 2026-01-01 0.0089     stable        stable         0.48
#> 2: 2026-02-01 0.0118     stable        stable        -0.19
#> 3: 2026-03-01 0.0035     stable        stable        -0.01
#> 4: 2026-04-01 0.0034     stable        stable        -0.28
#> 5: 2026-05-01 0.0136     stable        stable        -0.34
#> 6: 2026-06-01 0.4141      shift         shift         1.89
```

A vintage with fewer events than the plan’s minimum (100) is marked
`insufficient events`: its AUC is shown but no verdict is drawn from it.
The first four vintages were used for training, so their higher AUC is
expected; the comparison that matters is between successive production
periods and the scorecard’s own hold-out interval. For grade migration
and the traffic lights of a PD model, see [PD calibration and rating
grades](https://evandeilton.github.io/scorecraft/articles/pd-calibration-and-grades.html).

### The monitoring plan

The thresholds are a contract, not a default buried in code.
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
stores it as `sc$monitoring_plan`,
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
writes it to the `Monitoring_Plan` sheet, and `scr_monitor(plan = )`
reads it back, from the table or from the workbook. Edit the plan and
the flags follow it:

``` r

plan <- sc$monitoring_plan
plan[plan$item != "threshold_source", ]
#>                          item
#> 1    psi_score_fixed_moderate
#> 2      psi_score_fixed_action
#> 3          psi_adjusted_alpha
#> 4 csi_variable_fixed_moderate
#> 5   csi_variable_fixed_action
#> 6                 score_bands
#> 7       min_events_per_period
#>                                                                          value
#> 1                                                                         0.10
#> 2                                                                         0.25
#> 3                                                                         0.05
#> 4                                                                         0.10
#> 5                                                                         0.25
#> 6 509.91 | 523.5 | 533.38 | 542.1 | 550.36 | 557.76 | 566.55 | 576.51 | 590.28
#> 7                                                                          100
plan$value[plan$item == "min_events_per_period"] <- "90"
mo2 <- scr_monitor(sc, scr_demo, date_col = "ref_date", target = "default", n_boot = 20, plan = plan)
data.table(period = mo$vintage$period, events = mo$vintage$events,
           status_default = mo$vintage$status, status_edited = mo2$vintage$status)
#>        period events status_default status_edited
#>        <char>  <int>         <char>        <char>
#> 1: 2026-01-01     99   insufficient            ok
#> 2: 2026-02-01    102             ok            ok
#> 3: 2026-03-01     96   insufficient            ok
#> 4: 2026-04-01    102             ok            ok
#> 5: 2026-05-01     98   insufficient            ok
#> 6: 2026-06-01    105             ok            ok
```

With the minimum lowered to 90 events, the three vintages that were
marked insufficient now receive a verdict. The change lives in the plan,
where a validator can see it, not in the code.

## 9. Deliverables

[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
writes the selection workbook, the SQL and a Markdown summary for an
`scr_result`, and the scorecard, validation and strategy workbooks plus
the SQL for an `scr_scorecard`. The objects computed above can be passed
in, so the workbooks carry what was read in this session. `stamp = TRUE`
(the default) writes into a new timestamped directory, so an earlier run
is never overwritten.

``` r

out <- file.path(tempdir(), "scorecraft-get-started")
files_res <- scr_export(res, out, stamp = FALSE)$files
files_sc  <- scr_export(sc, out, stamp = FALSE, cutoff = ct, strategy = st, reject = rj,
                        monitor = mo)$files
basename(unlist(c(files_res, files_sc)))
#> [1] "selection_default.xlsx"  "sql_woe_default.sql"    
#> [3] "summary_default.md"      "scorecard_default.xlsx" 
#> [5] "validation_default.xlsx" "strategy_default.xlsx"  
#> [7] "sql_score_default.sql"   "sql_woe_default.sql"
mo3 <- scr_monitor(sc, scr_demo, date_col = "ref_date", target = "default", n_boot = 20,
                   plan = files_sc$strategy)
identical(mo3$psi$flag_adjusted, mo$psi$flag_adjusted)
#> [1] TRUE
```

Every sheet is sanitised before it is written (a cell starting with `=`,
`+`, `-` or `@` cannot become a formula), and each workbook is verified
after writing.
[`?scr_export`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
lists the sheets.

## 10. Before go-live

1.  **Split and figures.** The split is out-of-time and the hold-out
    figures, with their intervals, are the ones quoted.
2.  **Policy.** The cut-off and the bands come from
    [`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md)
    and
    [`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md)
    with revenue and loss figures the business signed off, and the
    reject coverage and multiplier are written down with them.
3.  **SQL.** The script in production is the exported one, with `table`
    and `keep_columns` set, and its output was compared with
    [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
    on the same rows after deployment.
4.  **Reasons.**
    [`scr_reasons()`](https://evandeilton.github.io/scorecraft/reference/scr_reasons.md)
    is the source of decline reasons, with the reference stated in the
    policy.
5.  **Monitoring.** The monitoring plan is filed with the deliverables,
    and `scr_monitor(plan = )` runs on every new period.

## Appendix: from a database

In production the table lives in a warehouse.
[`scr_connect()`](https://evandeilton.github.io/scorecraft/reference/scr_connect.md)
opens a DBI connection: with a `dsn` through ODBC (forcing
`bigint = "numeric"`, so a BIGINT is not read as a high-cardinality
categorical), with a `driver` through any DBI driver. SQLite stands in
for the warehouse here. It has no date type, so `ref_date` is stored as
text, which the split reads as a date.

``` r

con <- scr_connect(driver = RSQLite::SQLite(), dbname = ":memory:")
d <- scr_demo
d$ref_date <- as.character(d$ref_date)
DBI::dbWriteTable(con, "dtm", d)
nrow(scr_fetch(con, "dtm", sample_frac = 0.5, seed = 42))
#> SQL: select * from dtm where ((abs(random()) % 1000000) / 1000000.0) <= 0.5
#> [1] 2035
nrow(scr_fetch(con, "dtm", max_rows = 1000))
#>   cap of 1,000 rows: fraction reduced from 1.0000 to 0.2381 (table has 4,200)
#> SQL: select * from dtm where ((abs(random()) % 1000000) / 1000000.0) <= 0.23809523809523808
#> [1] 995
```

[`scr_fetch()`](https://evandeilton.github.io/scorecraft/reference/scr_fetch.md)
samples **on the server**: the fraction becomes a `WHERE` clause on a
random expression chosen by the connection class, and `max_rows` lowers
the fraction so that the expected count fits under the cap. The query is
echoed while
[`scr_verbose()`](https://evandeilton.github.io/scorecraft/reference/scr_verbose.md)
is on.

[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md)
chains fetch and selection over several targets, dropping each sibling
target from the candidates and recording a failure on one target without
stopping the others. With `date_col` the split is out-of-time, as in
section 2, and the table name is recorded for the SQL.

``` r

rs <- scr_run(con, "dtm", targets = c("default", "churn"), config = cfg, drop = "id",
              date_col = "ref_date")
rs
#> <scr_runset> 2 target(s): 2 succeeded, 0 failed
#> 
#>   target           rows approved      AUC       KS
#>   default         4,200       12   0.7375   0.3695
#>   churn           4,200        9   0.7262   0.3288
c(split = rs$default$split$method, cutoff = rs$default$split$cutoff,
  table = rs$default$config$sql_table)
#>         split        cutoff         table 
#> "out-of-time"  "2026-05-01"         "dtm"
DBI::dbDisconnect(con)
```

## Next steps

- [`vignette("coarse-classing", package = "scorecraft")`](https://evandeilton.github.io/scorecraft/articles/coarse-classing.md):
  replacing optimal bins by business bands, with every decision in a
  ledger.
- [`vignette("alignment-and-portfolio", package = "scorecraft")`](https://evandeilton.github.io/scorecraft/articles/alignment-and-portfolio.md):
  the points scale, odds orientation, challengers and rescaling.
- From the scorecard to IRB risk parameters: [PD calibration and rating
  grades](https://evandeilton.github.io/scorecraft/articles/pd-calibration-and-grades.html),
  [LGD and
  EAD](https://evandeilton.github.io/scorecraft/articles/lgd-and-ead-under-irb.html)
  and [expected loss and
  capital](https://evandeilton.github.io/scorecraft/articles/expected-loss-and-capital.html).

## References

Hand, D. J. and Henley, W. E. (1993). Can reject inference ever work?
*IMA Journal of Mathematics Applied in Business and Industry*, 5(1),
45-55.

Siddiqi, N. (2017). *Intelligent Credit Scoring: Building and
Implementing Better Credit Risk Scorecards*, 2nd edition. Wiley.

Yurdakul, B. and Naranjo, J. (2020). Statistical properties of the
population stability index. *Journal of Risk Model Validation*, 14(4),
89-100.
