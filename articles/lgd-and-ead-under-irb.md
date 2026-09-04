# LGD and EAD under IRB

The two IRB parameters after the PD follow the discipline of the
scorecard pipeline: a reference data set built with a funnel that names
every rule it applied, drivers binned on training cohorts and
revalidated with frozen bins on a hold-out, pools, a downturn and a
floor that land in a ledger with a reason, an R scoring function and a
SQL query that agree number for number, a validation battery with
traffic lights and a workbook. Part A walks the loss given default (LGD)
on the bundled default events and cash flows; part B walks the exposure
at default (EAD) on the bundled facility snapshots. Both use the light
configuration below: single thread, twenty bootstrap replicates, and a
lower minimum of defaults per CCF bin because the EAD panel is small.

``` r

library(scorecraft)
cfg <- scr_config(verbose = FALSE, nthread = 1, n_boot = 20, ccf_min_defaults = 20)
scr_verbose(FALSE)
```

## Part A: loss given default

### What a workout LGD is

A workout LGD is the economic loss of a default event over the exposure
at the default date: the exposure, less the recoveries, plus the direct
costs, the drawings after default and the indirect costs allocated to
the event, every cash flow discounted to the default date at the
reference rate in force at that date plus an add-on. A cure (the
facility returns to performing) is not a zero loss by decree: the
balance outstanding at the cure date enters as a recovery on that date,
so the cure carries its costs and the discount effect. Two defaults of
one facility closer than a cure window are one event. An incomplete
workout (still open at the observation date) receives the expected
further recovery read from the recovery profile of the closed defaults
of the same product; an open event older than the maximum workout period
is closed with no further recovery. The long-run average (LRA) is the
default-weighted mean over the events; the downturn LGD is the value
appropriate for an economic downturn, never below the LRA; and an own
estimate is subject to an input floor by asset class and collateral. The
`"type1"` and `"type3"` labels of the downturn methods below follow the
public supervisory guidance on downturn LGD estimation (observed impact,
and reference value plus add-on); the `"bcb"` parameter preset is the
Brazilian text (Resolução BCB 303/2023).

### The reference data set: `scr_workout()`

`scr_demo_lgd` holds 900 default events on three products, with the
drivers a workout model reads; `scr_demo_lgd_cashflows` is the long
table of their post-default cash flows; `scr_demo_rates` the monthly
reference rate.
[`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md)
discounts, merges, extrapolates and bounds, and returns the reference
data set (RDS) with one row per event.

``` r

wo <- scr_workout(scr_demo_lgd, scr_demo_lgd_cashflows, rates = scr_demo_rates, config = cfg)
wo
#> <scr_workout> 885 default events | 8 calendar years | observation date 2026-06-28
#>   cure rate 37.5% | incomplete 18.1% | mean discount rate 14.37%
#>   long-run average LGD: 40.5% default-weighted | 29.9% exposure-weighted | raw mean 40.5%
#>   auto         n 203   cure 36.5%   LRA 34.4%   (ew 35.9%)
#>   mortgage     n 237   cure 46.8%   LRA 26.3%   (ew 26.7%)
#>   unsecured    n 445   cure 33.0%   LRA 50.8%   (ew 51.3%)
#>   funnel MULTIPLE_DEFAULT_MERGED      15
#>   funnel OPEN_BEYOND_T_MAX_CLOSED     2
#>   funnel INCOMPLETE_EXTRAPOLATED      160
#>   funnel LGD_ABOVE_ONE                3
```

The funnel is the first deliverable: the thirty second defaults of the
demo were fifteen pairs closer than the nine-month cure window, merged
into their first spell, plus fifteen pairs far enough apart to stay two
events; two open events older than sixty months were closed with no
further recovery; 160 open events younger than that received an expected
further recovery; three events lost more than the exposure (costs on a
facility with no recovery) and were kept above one because
`lgd_cap_at_one` is off.

``` r

wo$funnel[, .(rule, n, action)]
#>                        rule     n
#>                      <char> <int>
#> 1:             NOT_IN_SCOPE     0
#> 2:  MULTIPLE_DEFAULT_MERGED    15
#> 3: CASHFLOW_WITHOUT_DEFAULT     0
#> 4: OPEN_BEYOND_T_MAX_CLOSED     2
#> 5:  INCOMPLETE_EXTRAPOLATED   160
#> 6:     NEGATIVE_LGD_FLOORED     0
#> 7:            LGD_ABOVE_ONE     3
#>                                                                                        action
#>                                                                                        <char>
#> 1:             excluded: EAD <= 0, missing default date or default after the observation date
#> 2:                          merged into the earlier default of the facility (window 9 months)
#> 3:                                          cash-flow rows dropped: no default event in scope
#> 4:                                open for 60 months or more: closed with no further recovery
#> 5: open workouts younger than t_max: expected further recovery added from the product profile
#> 6:                                                  floored at 0 in lgd_real (raw value kept)
#> 7:                                                      kept above 1 (lgd_cap_at_one = FALSE)
```

The long-run average is reported default-weighted, the regulatory
estimate, and exposure-weighted. They differ by ten points here because
the mortgages carry the exposure and the low LGD. The share of
incomplete workouts is the share of rows whose loss is partly an
extrapolation.

``` r

wo$summary$by_product
#>      product     n cure_rate       lra    lra_ew share_incomplete
#>       <char> <int>     <num>     <num>     <num>            <num>
#> 1:      auto   203 0.3645320 0.3443811 0.3585787       0.02463054
#> 2:  mortgage   237 0.4683544 0.2626056 0.2665364       0.13080169
#> 3: unsecured   445 0.3303371 0.5076497 0.5129146       0.27865169
wo$summary$share_incomplete
#> [1] 0.180791
```

The recovery profile is the cumulative discounted recovery rate of the
closed defaults by product and month in default; it is what the
extrapolation reads (`rho_tau` at the current age, `rho_t_max` at the
end), and what the in-default grid will read later.

``` r

wo$recovery_profile[month %in% c(6, 12, 24, 36, 60)]
#>       product month n_closed cum_recovery
#>        <char> <int>    <int>        <num>
#>  1:      auto     6      124   0.31759377
#>  2:      auto    12      124   0.54601720
#>  3:      auto    24      124   0.55029906
#>  4:      auto    36      124   0.55029906
#>  5:      auto    60      124   0.55029906
#>  6:  mortgage     6       95   0.02839870
#>  7:  mortgage    12       95   0.07399733
#>  8:  mortgage    24       95   0.46060628
#>  9:  mortgage    36       95   0.61970602
#> 10:  mortgage    60       95   0.62294590
#> 11: unsecured     6      174   0.23982228
#> 12: unsecured    12      174   0.30647093
#> 13: unsecured    24      174   0.33761553
#> 14: unsecured    36      174   0.34409119
#> 15: unsecured    60      174   0.34474541
#> 16:       all     6      393   0.10283559
#> 17:       all    12      393   0.18669388
#> 18:       all    24      393   0.46896001
#> 19:       all    36      393   0.58427160
#> 20:       all    60      393   0.58666059
#>       product month n_closed cum_recovery
#>        <char> <int>    <int>        <num>
head(wo$extrapolation[, .(default_id, product, months_in_default, rho_tau, rho_t_max, expected_further)], 4)
#>    default_id   product months_in_default   rho_tau rho_t_max expected_further
#>        <char>    <char>             <int>     <num>     <num>            <num>
#> 1:      D0001 unsecured                15 0.3079344 0.3447454       218.854993
#> 2:      D0003  mortgage                24 0.4606063 0.6229459     19987.125213
#> 3:      D0018 unsecured                35 0.3427772 0.3447454         4.182786
#> 4:      D0028 unsecured                23 0.3273125 0.3447454       113.773474
```

### Binning a bounded target: `scr_bin_continuous()`

The optimal-binning engine of the scorecard accepts binary targets only.
LGD and CCF are continuous and bounded, so the severity stage and the
CCF pools use a supervised binner of their own: candidate cut points at
quantiles, greedy merges of the adjacent pair whose merge loses the
least between-bin sum of squares until the target number of bins and the
size floors hold, then pool-adjacent violators on the bin means when
monotonicity is required. The result has exactly the shape of the
engine’s object: the `woe` slot carries the bin mean of the target and
the `iv` slot the bin’s share of the between-bin sum of squares, so the
total is the eta-squared of the driver and the same SQL emitter
reproduces the bin statistic in every dialect. Here it runs once, on the
worst delinquency before default, over the non-cured events, with the
2024 and later defaults as the hold-out.

``` r

nc <- wo$rds[is_cure == FALSE]
cb <- scr_bin_continuous(nc, "lgd_real", "prior_dpd_max",
                         train_idx = which(nc$year < 2024), holdout_idx = which(nc$year >= 2024))
cb
#> <scr_cbins> 1 driver(s) binned against 'lgd_real' (bin statistic: mean)
#>   prior_dpd_max            numerical   3 bins | eta2 0.136 | increasing | hold-out eta2 0.077, PSI 0.016 (stable)
cb$fit$results$prior_dpd_max$bin
#> [1] "(-Inf;30.000000]"      "(30.000000;60.000000]" "(60.000000;+Inf]"
cb$fit$results$prior_dpd_max$woe
#> [1] 0.5624174 0.6556032 0.7320278
```

The hold-out revalidation recomputes the bin means with the bins frozen,
reports the PSI of the bin shares with the sample-size-adjusted critical
value, and flags `UNSTABLE_HOLDOUT` when the hold-out means break the
training order.

``` r

cb$holdout[, .(bin, n_train, mean_train, n_holdout, mean_holdout)]
#>                      bin n_train mean_train n_holdout mean_holdout
#>                   <char>   <int>      <num>     <int>        <num>
#> 1:      (-Inf;30.000000]     225  0.5624174        89    0.5791883
#> 2: (30.000000;60.000000]      84  0.6556032        40    0.6655246
#> 3:      (60.000000;+Inf]      75  0.7320278        40    0.6913565
cb$summary[, .(feature, eta2, eta2_holdout, psi, psi_flag, holdout_ok)]
#>          feature      eta2 eta2_holdout        psi psi_flag holdout_ok
#>           <char>     <num>        <num>      <num>   <char>     <lgcl>
#> 1: prior_dpd_max 0.1356892   0.07655161 0.01569249   stable       TRUE
```

### The two-stage model: `scr_lgd()`

[`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md)
fits `LGD = P(cure) LGD_cure + (1 - P(cure)) E[LGD | no cure]`. The cure
stage is a binary model on `is_cure` with the scorecard machinery:
optimal binning on the training cohorts, WOE, hold-out revalidation, a
logistic regression on the WOE columns with the sign check. The severity
stage bins the same drivers against the realised LGD of the non-cures
with the continuous binner and fits a fractional logit on the bin means.
The split is by cohort of default: the last 30% of the default dates are
the hold-out.

``` r

drv <- c("product", "ltv", "prior_dpd_max", "months_on_book", "region")
m <- scr_lgd(wo, drivers = drv, config = cfg)
m
#> <scr_lgd> 885 defaults | train 620 / hold-out 265 (cohort split after 2024-01-01) | cure rate 37.5%
#>   cure stage: prior_dpd_max, months_on_book, region | severity stage (fractional_logit): product, prior_dpd_max, months_on_book | LGD of a cure 4.5%
#>   train    n 620   RMSE 0.2731  R2 0.241  Spearman 0.473  gAUC 0.672 [0.657, 0.686]  LCR 0.403
#>   holdout  n 265   RMSE 0.2655  R2 0.275  Spearman 0.536  gAUC 0.693 [0.644, 0.725]  LCR 0.460
#>   pools 3 | downturn type1 (provisional) | floor not applied
#>   pool   n     pred        LRA     LRA ew   MoC C    LGD DT   floor    final
#>   1    274    0.276     27.5%     23.1%   0.023     44.8%   0.000     44.8%
#>   2    170    0.415     40.0%     38.0%   0.038     58.8%   0.000     58.8%
#>   3    176    0.554     59.3%     42.8%   0.043     78.6%   0.000     78.6%
```

Each stage keeps its own audit trail. In the cure stage, a driver enters
the regression only if its training IV clears the minimum, its frozen
bins hold on the hold-out and its coefficient is positive.

``` r

m$cure$bins[, .(iv = sum(iv), iv_holdout = iv_holdout[1], holdout_ok = holdout_ok[1],
                selected = selected[1]), by = variable]
#>          variable         iv iv_holdout holdout_ok selected
#>            <char>      <num>      <num>     <lgcl>   <lgcl>
#> 1:        product 0.07245340 0.03531391      FALSE    FALSE
#> 2:            ltv 0.02874538 0.01015355      FALSE    FALSE
#> 3:  prior_dpd_max 0.12697029 0.68239837       TRUE     TRUE
#> 4: months_on_book 0.06033029 0.09515877       TRUE     TRUE
#> 5:         region 0.03748065 0.14064382       TRUE     TRUE
m$cure$sign_check
#> Index: <action>
#>          variable     coef action reason
#>            <char>    <num> <char> <char>
#> 1: months_on_book 1.218919   kept     OK
#> 2:  prior_dpd_max 1.128097   kept     OK
#> 3:         region 1.240103   kept     OK
```

In the severity stage, `ltv` is removed by the sign check. Its bin means
fall with the loan-to-value because the ratio is zero for unsecured
facilities, which are the ones that lose most: the driver is the product
effect in disguise, and once `product` is in the regression its
coefficient turns negative.

``` r

m$severity$bins[, .(variable, bin, count, mean, mean_holdout, selected)]
#>           variable              bin count      mean mean_holdout selected
#>             <char>           <char> <int>     <num>        <num>   <lgcl>
#>  1:            ltv  (-Inf;0.479429]   220 0.7156562    0.7094439    FALSE
#>  2:            ltv  (0.479429;+Inf]   165 0.4828760    0.5173144    FALSE
#>  3: months_on_book (-Inf;27.000000]   207 0.6510963    0.6393596     TRUE
#>  4: months_on_book (27.000000;+Inf]   178 0.5749547    0.6104969     TRUE
#>  5:  prior_dpd_max (-Inf;30.000000]   225 0.5624174    0.5791883     TRUE
#>  6:  prior_dpd_max (30.000000;+Inf]   160 0.6910935    0.6786501     TRUE
#>  7:        product  mortgage%;%auto   175 0.4748150    0.5071735     TRUE
#>  8:        product        unsecured   210 0.7334583    0.7339459     TRUE
#>  9:         region            south   101 0.5719386    0.6365571    FALSE
#> 10:         region   central%;%west   118 0.6012325    0.6065112    FALSE
#> 11:         region     east%;%north   166 0.6530582    0.6369108    FALSE
m$severity$sign_check
#> Index: <action>
#>          variable      coef  action        reason
#>            <char>     <num>  <char>        <char>
#> 1: months_on_book  3.329868    kept            OK
#> 2:  prior_dpd_max  4.969159    kept            OK
#> 3:        product  4.431850    kept            OK
#> 4:            ltv -2.075296 removed SIGN_REVERSED
```

Metrics on both samples come with a bootstrap interval on Somers’ D (the
generalised AUC is `(D + 1) / 2`) and on the loss capture ratio.

``` r

m$metrics[, .(sample, n, rmse, r2, spearman, gauc, gauc_lo, gauc_hi, lcr)]
#>     sample     n      rmse        r2  spearman      gauc   gauc_lo   gauc_hi
#>     <char> <int>     <num>     <num>     <num>     <num>     <num>     <num>
#> 1:   train   620 0.2730699 0.2411368 0.4725775 0.6721247 0.6566138 0.6856745
#> 2: holdout   265 0.2655118 0.2751904 0.5359311 0.6925386 0.6437596 0.7253226
#>          lcr
#>        <num>
#> 1: 0.4030191
#> 2: 0.4603287
```

The pools cut the training predictions into quantile bands, merge the
bands with fewer than `lgd_min_defaults_bin` defaults into the neighbour
with the closer long-run average, then merge adjacent bands whose
averages break the increasing order. With 620 training defaults and a
minimum of 100 per pool, the seven target bands collapse to three. Per
pool: the default-weighted LRA, the exposure-weighted one, and the
category-C margin of conservatism, a one-sided 95% t interval on the
mean. The downturn column is provisional at this point (a type-3 add-on
by configuration) and the floor is zero until the next two calls run.

``` r

m$pools[, .(pool, pred_lo, pred_hi, n, lra, lra_ew, se, moc_c, lgd_dt, floor, lgd_final)]
#>     pool   pred_lo   pred_hi     n       lra    lra_ew         se      moc_c
#>    <int>     <num>     <num> <int>     <num>     <num>      <num>      <num>
#> 1:     1      -Inf 0.3769045   274 0.2749072 0.2306159 0.01382310 0.02281440
#> 2:     2 0.3769045 0.4526564   170 0.4002597 0.3802176 0.02289441 0.03786551
#> 3:     3 0.4526564       Inf   176 0.5926373 0.4275209 0.02595678 0.04292232
#>       lgd_dt floor lgd_final
#>        <num> <num>     <num>
#> 1: 0.4477216     0 0.4477216
#> 2: 0.5881253     0 0.5881253
#> 3: 0.7855596     0 0.7855596
```

### Downturn, floor and the in-default grid

[`scr_lgd_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_downturn.md)
quantifies the downturn per pool from user-supplied periods. Under
`"type1"` the downturn value is the realised LGD of the defaults whose
default date falls in the periods (a pool with fewer than ten such
defaults falls back to the add-on); the reference value, the mean of the
two worst calendar years of the pool, is reported as a challenger, not a
bound. The downturn LGD used for capital is
`min(1, max(LRA + MoC, DT + MoC))`. The reference rate of the demo rises
above thirteen per cent in 2022 and 2023, which is the reason recorded.

``` r

m <- scr_lgd_downturn(m, periods = data.frame(start = as.Date("2022-01-01"), end = as.Date("2023-12-31")),
                      reason = "reference rate above 13% in 2022-2023")
m$downturn$table[, .(pool, n, lra, moc_c, n_downturn, dt_observed, reference_value, method_used, lgd_dt, impact, below_reference)]
#>     pool     n       lra      moc_c n_downturn dt_observed reference_value
#>    <int> <int>     <num>      <num>      <int>       <num>           <num>
#> 1:     1   274 0.2749072 0.02281440        117   0.2923210       0.3071022
#> 2:     2   170 0.4002597 0.03786551         73   0.4681236       0.5277502
#> 3:     3   176 0.5926373 0.04292232         79   0.6312294       0.6842627
#>    method_used    lgd_dt     impact below_reference
#>         <char>     <num>      <num>          <lgcl>
#> 1:       type1 0.3151354 0.01741372           FALSE
#> 2:       type1 0.5059891 0.06786385            TRUE
#> 3:       type1 0.6741517 0.03859206            TRUE
```

Pools 2 and 3 sit below their reference value: the two worst years of
those pools were worse than the periods declared. The flag does not
change the estimate; it is there for the reviewer to answer.

[`scr_lgd_floor()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_floor.md)
reads the input floor from the parameter table of the framework. The
tables are numbers, editable and printable; an edit is detected and
recorded as `params_modified` in the ledger. The floor of a partly
secured pool blends the unsecured and the collateral floors with the
secured share: `0.30 * 0.6 + 0.10 * 0.4 = 0.22` here.

``` r

p <- scr_irb_params("bcb")
p$lgd_floor
#>        asset_class unsecured financial receivables real_estate other_physical
#>             <char>     <num>     <num>       <num>       <num>          <num>
#> 1:       corporate      0.25         0         0.1        0.10           0.15
#> 2: retail_mortgage        NA        NA          NA        0.05             NA
#> 3:            qrre      0.50        NA          NA          NA             NA
#> 4:    retail_other      0.30         0         0.1        0.10           0.15
m <- scr_lgd_floor(m, params = p, asset_class = "retail_other", secured_share = 0.4)
m$floors$table
#>     pool     n    lgd_dt floor_unsecured floor_secured secured_share floor
#>    <int> <int>     <num>           <num>         <num>         <num> <num>
#> 1:     1   274 0.3151354             0.3           0.1           0.4  0.22
#> 2:     2   170 0.5059891             0.3           0.1           0.4  0.22
#> 3:     3   176 0.6741517             0.3           0.1           0.4  0.22
#>    lgd_final binding
#>        <num>  <lgcl>
#> 1: 0.3151354   FALSE
#> 2: 0.5059891   FALSE
#> 3: 0.6741517   FALSE
m
#> <scr_lgd> 885 defaults | train 620 / hold-out 265 (cohort split after 2024-01-01) | cure rate 37.5%
#>   cure stage: prior_dpd_max, months_on_book, region | severity stage (fractional_logit): product, prior_dpd_max, months_on_book | LGD of a cure 4.5%
#>   train    n 620   RMSE 0.2731  R2 0.241  Spearman 0.473  gAUC 0.672 [0.657, 0.686]  LCR 0.403
#>   holdout  n 265   RMSE 0.2655  R2 0.275  Spearman 0.536  gAUC 0.693 [0.644, 0.725]  LCR 0.460
#>   pools 3 | downturn type1 (final) | floor retail_other, binding in 0.0% of the defaults
#>   pool   n     pred        LRA     LRA ew   MoC C    LGD DT   floor    final
#>   1    274    0.276     27.5%     23.1%   0.023     31.5%   0.220     31.5%
#>   2    170    0.415     40.0%     38.0%   0.038     50.6%   0.220     50.6%
#>   3    176    0.554     59.3%     42.8%   0.043     67.4%   0.220     67.4%
```

The floor binds in none of the three pools on this data, and that fact
is what the ledger records.
[`scr_elbe()`](https://evandeilton.github.io/scorecraft/reference/scr_elbe.md)
derives the in-default grid: for every pool and every age since default,
the expected loss best estimate (ELBE) is the mean realised LGD of the
training defaults still in workout at that age, and the in-default LGD
adds the unexpected-loss increment `(LGD_DT - LRA)` scaled by the share
of the recoveries still to come, read from the recovery profile. At age
zero the ELBE equals the LRA and the in-default LGD equals the downturn
LGD; the consistency table checks exactly that. The jump at six months
is the cures leaving the set of open events.

``` r

e <- scr_elbe(m)
e
#> <scr_elbe> 3 pools x 5 reference ages (months since default: 0, 6, 12, 24, 36) | t_max 60
#>   consistency at tau = 0: ELBE equals the LRA and the in-default LGD equals the downturn LGD
#>   in-default LGD by pool and age
#>   pool       m0      m6     m12     m24     m36
#>   1       31.5%   50.8%   50.0%   51.4%   54.3%
#>   2       50.6%   70.9%   70.3%   67.3%   69.3%
#>   3       67.4%   84.5%   84.5%   81.6%   82.6%
e$consistency
#>     pool       lra    lgd_dt    elbe_0 lgd_in_default_0     ok
#>    <int>     <num>     <num>     <num>            <num> <lgcl>
#> 1:     1 0.2749072 0.3151354 0.2749072        0.3151354   TRUE
#> 2:     2 0.4002597 0.5059891 0.4002597        0.5059891   TRUE
#> 3:     3 0.5926373 0.6741517 0.5926373        0.6741517   TRUE
```

### Production: `scr_apply()` and `scr_sql()`

[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
scores new rows with the frozen bins of both stages and returns the cure
probability, the severity, the predicted LGD, the pool and the pool
parameters.

``` r

new <- head(scr_demo_lgd, 5)
ap <- scr_apply(m, new, what = "all")
ap
#>       p_cure  severity  lgd_pred  pool   lgd_lra    lgd_dt lgd_final
#>        <num>     <num>     <num> <int>     <num>     <num>     <num>
#> 1: 0.3838348 0.7822633 0.4991442     3 0.5926373 0.6741517 0.6741517
#> 2: 0.3157596 0.4370276 0.3131328     1 0.2749072 0.3151354 0.3151354
#> 3: 0.1881175 0.5331106 0.4412239     2 0.4002597 0.5059891 0.5059891
#> 4: 0.2283024 0.5331106 0.4215954     2 0.4002597 0.5059891 0.5059891
#> 5: 0.4774548 0.7095159 0.3920757     2 0.4002597 0.5059891 0.5059891
```

[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
emits the same computation for the database: the bin statistics of both
stages, the two logits, the predicted LGD, the pool `CASE` on the pool
boundaries (snapped to the midpoint between adjacent predictions, so
that floating-point noise cannot flip a pool between R and SQL), the
pool parameters and the floored result.

``` r

sql <- scr_sql(m, table = "prd.defaults", dialect = "duckdb")
sql_lines <- unlist(strsplit(sql, "\n", fixed = TRUE))
cat(grep("AS pool$|AS lgd_dt,$|AS lgd_floor$|AS lgd_final$", sql_lines, value = TRUE), sep = "\n")
#>     CASE WHEN lgd_pred <= 0.37690454385294914 THEN 1 WHEN lgd_pred <= 0.45265644452998083 THEN 2 ELSE 3 END AS pool
#>     CASE pool WHEN 1 THEN 0.31513536760296268 WHEN 2 THEN 0.50598910528854668 WHEN 3 THEN 0.67415168383886248 ELSE 0.67415168383886248 END AS lgd_dt,
#>     CASE pool WHEN 1 THEN 0.22 WHEN 2 THEN 0.22 WHEN 3 THEN 0.22 ELSE 0.22 END AS lgd_floor
#>     GREATEST(lgd_dt, lgd_floor) AS lgd_final
```

When `duckdb` is installed the query runs on the same five rows and
reproduces
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md).

``` r

con <- suppressMessages(DBI::dbConnect(duckdb::duckdb(), config = list(threads = "1")))
DBI::dbWriteTable(con, "defaults_t", new)
got <- DBI::dbGetQuery(con, paste(scr_sql(m, table = "defaults_t", dialect = "duckdb"), collapse = "\n"))
DBI::dbDisconnect(con, shutdown = TRUE)
got[, c("lgd_pred", "pool", "lgd_dt", "lgd_floor", "lgd_final")]
#>    lgd_pred pool    lgd_dt lgd_floor lgd_final
#> 1 0.4991442    3 0.6741517      0.22 0.6741517
#> 2 0.3131328    1 0.3151354      0.22 0.3151354
#> 3 0.4412239    2 0.5059891      0.22 0.5059891
#> 4 0.4215954    2 0.5059891      0.22 0.5059891
#> 5 0.3920757    2 0.5059891      0.22 0.5059891
identical(as.integer(got$pool), ap$pool)
#> [1] TRUE
all.equal(got$lgd_final, ap$lgd_final)
#> [1] TRUE
```

### Validation and export

[`scr_lgd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_validate.md)
runs on the hold-out (or on new data) against the training reference:
calibration per pool and for the portfolio (one-sided t-test where
under-estimation is the failure, loss shortfall, coverage of the
realised mean by the downturn LGD), discrimination against the training
gAUC, stability of the pool and driver-bin distributions, and the
homogeneity within and heterogeneity between pools. The lights use the
p-value thresholds of `pd_lights` and the fixed PSI thresholds.

``` r

v <- scr_lgd_validate(m)
v
#> <scr_lgd_validation> sample holdout | n 265
#>   calibration: realised 41.7% vs estimate 39.1% | t 1.33 p 0.092 [green] | loss shortfall -1.1% | downturn covers: TRUE
#>   discrimination: gAUC 0.693 [0.644, 0.725] vs initial 0.672 (S -0.98, p 0.837) [green] | Spearman 0.536 | LCR 0.460
#>   stability: pool PSI 0.0056 (stable; adjusted stable) | drivers: prior_dpd_max_cure 0.009, months_on_book_cure 0.001, region_cure 0.029, product_sev 0.001, prior_dpd_max_sev 0.001, months_on_book_sev 0.002
#>   calibration_portfolio_t        green  
#>   calibration_pools_t            amber  
#>   loss_shortfall                 amber  
#>   downturn_coverage              green  
#>   gauc_vs_initial                green  
#>   psi_pools                      green  
#>   psi_drivers                    green  
#>   homogeneity_within_pools       red    
#>   heterogeneity_between_pools    green
v$calibration[, .(pool, n, lgd_est, real_mean, real_ew, p, light, dt_covers)]
#>     pool     n   lgd_est real_mean   real_ew          p  light dt_covers
#>    <int> <int>     <num>     <num>     <num>      <num> <char>    <lgcl>
#> 1:     1   127 0.2749072 0.2720949 0.2688960 0.55023471  green      TRUE
#> 2:     2    68 0.4002597 0.4463789 0.4701465 0.10555718  green      TRUE
#> 3:     3    70 0.5926373 0.6495472 0.5502930 0.04033446  amber      TRUE
```

The red light on homogeneity is the price of three pools: a Welch test
between the two halves of each pool, split at its median prediction,
finds that the halves still differ, so the pools are not yet
homogeneous. That is what the battery is for; the fix is more defaults
or a lower minimum per pool, and either is a ledger row.

[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
writes one workbook with the RDS funnel and summaries, the recovery
profile, the bins and coefficients of both stages, the sign checks, the
pools, the downturn and its periods, the floors, the in-default grid,
the validation blocks, the model card and the ledger, plus the SQL file.

``` r

out <- file.path(tempdir(), "irb-vignette")
basename(unlist(scr_export(m, out, stamp = FALSE, validation = v, elbe = e)$files))
#> [1] "lgd_model.xlsx"    "sql_lgd_model.sql"
```

## Part B: exposure at default

### Realised conversion factors

Write `R` for the reference date, `D` for the default date, `E` for the
drawn amount and `L` for the limit. The realised credit conversion
factor of a default event is the share of the undrawn amount at the
reference date that was drawn by the default date,
`CCF = (E_D - E_R) / (L_R - E_R)`, and the realised EAD is the drawn
amount at the default date, never capped at the limit. The reference
date is one horizon before the default (twelve months here under the
fixed approach; the start of the calendar cohort under the cohort
approach). The CCF is only meaningful while the undrawn part is
material: when the utilisation at the reference date is at or above
`ccf_u_star`, when nothing is undrawn, or when the facility is over its
limit, the denominator is small or negative and the row is routed to the
limit factor `LF = E_D / L_R` instead of being dropped; a facility with
no usable limit uses the exposure factor `E_D / E_R`. Two floors apply
at different places: the realised CCF is floored at zero for the
averages (a facility that repaid before default; the raw value is kept),
and the applied CCF of an own estimate is floored at a fraction of the
standardised CCF, one half of `ccf_sa_ccf` here, while the predicted EAD
is never below the drawn amount.

### The reference data set: `scr_ead_data()`

`scr_demo_ead` is a panel of 1,200 revolving facilities over thirty
months with a 0/1 default flag; every run of ones opens a default event
at its first month.
[`scr_ead_data()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_data.md)
finds the reference snapshot of every event, computes the realised
measure and applies the funnel rules.

``` r

ed <- scr_ead_data(scr_demo_ead, facility_id = "facility_id", obligor_id = "obligor_id",
                   date_col = "ref_date", limit = "limit", drawn = "drawn", defaulted = "defaulted",
                   drivers = c("product", "months_on_book", "dpd"), config = cfg)
ed
#> <scr_ead_data> 197 rows from 197 default events | 1,200 facilities x 34,811 snapshots
#>   horizon: fixed (12 months) | measure: auto (u* = 0.95) | reference dates 2023-01-01 to 2024-06-01 (1.4 years)
#>   ULF: LRA simple 0.3248 | exposure-weighted 0.2889 | n = 189
#>   LF rows 4.1% | above one 7.4% | negative (raw) 23.8% | fast defaults 19.8%
#>   funnel:
#>     FAST_DEFAULT             kept              25 (12.7%)
#>     OVER_LIMIT_AT_REF        routed_to_lf       7 (3.6%)
#>     NEGATIVE_CCF_FLOORED     floored           45 (22.8%)
#>     CCF_ABOVE_ONE            kept              14 (7.1%)
#>     OK                       kept             106 (53.8%)
#>   note: fewer than five years of reference dates; the average is not a long-run one yet
```

The funnel keeps everything it can and names what it did: a facility
younger than the horizon is kept from its first snapshot and flagged
`FAST_DEFAULT`; an over-limit facility is routed to the limit factor; a
negative realised CCF (the facility repaid before defaulting) is floored
at zero; a CCF above one (a limit raised or a drawing beyond the limit)
is kept as observed because no cap is configured.

``` r

ed$funnel
#>                    rule       action     n      share
#>                  <char>       <char> <int>      <num>
#> 1:         FAST_DEFAULT         kept    25 0.12690355
#> 2:    OVER_LIMIT_AT_REF routed_to_lf     7 0.03553299
#> 3: NEGATIVE_CCF_FLOORED      floored    45 0.22842640
#> 4:        CCF_ABOVE_ONE         kept    14 0.07106599
#> 5:                   OK         kept   106 0.53807107
head(ed$rds[, .(facility_id, ref_date, default_date, utilisation_ref, ead_realised, measure, ccf_raw, ccf, rule)])
#>    facility_id   ref_date default_date utilisation_ref ead_realised measure
#>         <char>     <Date>       <Date>           <num>        <num>  <char>
#> 1:       F0031 2023-01-01   2023-08-01          0.5200          400     ulf
#> 2:       F0062 2023-01-01   2023-11-01          0.4600          220     ulf
#> 3:       F0093 2023-01-01   2023-07-01          0.6485        14020     ulf
#> 4:       F0103 2023-01-01   2023-12-01          0.3400          140     ulf
#> 5:       F0108 2023-01-01   2024-01-01          0.1300          360     ulf
#> 6:       F0109 2023-01-01   2023-08-01          0.3650         7920     ulf
#>        ccf_raw       ccf                 rule
#>          <num>     <num>               <char>
#> 1: -0.25000000 0.0000000 NEGATIVE_CCF_FLOORED
#> 2: -0.03703704 0.0000000 NEGATIVE_CCF_FLOORED
#> 3:  0.14935989 0.1493599         FAST_DEFAULT
#> 4: -0.09090909 0.0000000 NEGATIVE_CCF_FLOORED
#> 5:  0.26436782 0.2643678                   OK
#> 6:  0.46456693 0.4645669         FAST_DEFAULT
```

The summary gives the simple and the exposure-weighted averages by
cohort of reference date and by measure, with a total row. The large
lines draw a smaller share of their undrawn amount, so the
exposure-weighted CCF sits below the simple one. Two cohorts and 1.4
years of reference dates is not a long run yet, and the print says so.

``` r

ed$summary
#>    cohort measure     n ccf_simple    ccf_ew ead_realised share_above_one
#>    <char>  <char> <int>      <num>     <num>        <num>           <num>
#> 1:   2023      lf     7  0.8726786 0.8623423        47860      0.57142857
#> 2:   2023     ulf   146  0.3007913 0.2631065       574650      0.07534247
#> 3:   2024      lf     1  1.0400000 1.0400000          520      1.00000000
#> 4:   2024     ulf    43  0.4063661 0.3498382       214470      0.06976744
#> 5:    ALL      lf     8  0.8935938 0.8639286        48380      0.62500000
#> 6:    ALL     ulf   189  0.3248110 0.2888929       789120      0.07407407
```

### Pools and downturn: `scr_ead()` and `scr_ead_downturn()`

[`scr_ead()`](https://evandeilton.github.io/scorecraft/reference/scr_ead.md)
splits by reference date (the most recent dates are the hold-out), bins
every candidate driver against the realised CCF on the training rows
with the continuous binner, revalidates the frozen bins on the hold-out,
and admits a driver only when it passes four named rules: enough
defaults in every bin, separation of the bin means (an F-test), the
training order preserved on the hold-out, and a stable bin distribution.
The cells of the cross of the admitted drivers are ordered by predicted
CCF and merged into pools with at least `ccf_min_defaults` each; rows in
the limit-factor measure form their own pool `LF`.

``` r

m_ead <- scr_ead(ed, drivers = c("utilisation_ref", "product", "months_on_book", "dpd"), config = cfg)
m_ead
#> <scr_ead> 2 pool(s) + LF from 197 reference rows | fixed horizon (12 months) | measure auto
#>   split by reference date: train 126 | hold-out 71 (from 2023-11-01) | drivers admitted: utilisation_ref
#>   floor 0.2000 (= 0.5 x SA-CCF 0.4) | MoC alpha 0.05 | downturn none
#>   pool  meas       n      lra   lra_ew      moc   ccf_dt    final    floor  applied
#>   P1    ulf       98   0.2857   0.2459   0.0603   0.2857   0.3459   0.2000   0.3459
#>   P2    ulf       23   0.4963   0.3785   0.1301   0.4963   0.6264   0.2000   0.6264
#>   LF    lf         5   0.8884   0.8726   0.1411   0.8884   1.0295      row   1.0295
#>   train    n   126 | RMSE 0.3628 | MAE 0.2884 | gAUC 0.5582 [0.5068, 0.5935] | EAD adequacy 0.8485 | CEAR 0.1181
#>   holdout  n    71 | RMSE 0.4035 | MAE 0.2728 | gAUC 0.5708 [0.5392, 0.6340] | EAD adequacy 0.7905 | CEAR 0.4077
m_ead$drivers[, .(feature, n_bins, eta2, direction, p_anova, eta2_holdout, psi_flag, admitted, reason)]
#>            feature n_bins       eta2       direction    p_anova eta2_holdout
#>             <char>  <int>      <num>          <char>      <num>        <num>
#> 1: utilisation_ref      2 0.04934431      decreasing 0.01433303   0.03634314
#> 2:         product      3 0.02890852 ordered_by_mean 0.17715296   0.05268658
#> 3:  months_on_book      4 0.08125227      decreasing 0.01893577   0.07602372
#> 4:             dpd      1 0.00000000            none         NA   0.00000000
#>    psi_flag admitted        reason
#>      <char>   <lgcl>        <char>
#> 1:   stable     TRUE            OK
#> 2:   stable    FALSE NO_SEPARATION
#> 3: moderate    FALSE NOT_MONOTONIC
#> 4:   stable    FALSE NO_SEPARATION
```

Only the utilisation at the reference date is admitted: the product does
not separate the means, the months on book reverse their order on the
hold-out and the days past due collapse to one bin. Two pools follow the
two utilisation bins, the lower utilisation drawing the larger share of
its undrawn amount. Per pool: the long-run average, `moc_est`, a
one-sided normal estimation-error margin at `ccf_moc_alpha`;
`ccf_final = max(lra, ccf_dt) + moc_est`; the floor `0.5 * 0.40 = 0.20`;
and `ccf_applied = max(ccf_final, ccf_floor)`. The `LF` pool has no
scalar floor because its floor depends on the utilisation of the row.

``` r

m_ead$pools[, .(pool, measure, n, lra, lra_ew, se, moc_est, ccf_dt, ccf_final, ccf_floor, ccf_applied, floor_binding)]
#>      pool measure     n       lra    lra_ew         se    moc_est    ccf_dt
#>    <char>  <char> <int>     <num>     <num>      <num>      <num>     <num>
#> 1:     P1     ulf    98 0.2856519 0.2458889 0.03663230 0.06025477 0.2856519
#> 2:     P2     ulf    23 0.4962957 0.3785191 0.07912126 0.13014290 0.4962957
#> 3:     LF      lf     5 0.8884167 0.8726214 0.08576962 0.14107847 0.8884167
#>    ccf_final ccf_floor ccf_applied floor_binding
#>        <num>     <num>       <num>        <lgcl>
#> 1: 0.3459067       0.2   0.3459067         FALSE
#> 2: 0.6264386       0.2   0.6264386         FALSE
#> 3: 1.0294951        NA   1.0294951         FALSE
```

[`scr_ead_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_downturn.md)
takes the periods and a mandatory reason. Under `"type1"` the downturn
value of a pool is `max(lra, observed)`, the default-weighted realised
CCF of the events whose default date falls in the periods; the applied
CCF is recomputed and the ledger records periods, method and reason.

``` r

m_ead <- scr_ead_downturn(m_ead, periods = data.frame(start = as.Date("2024-01-01"), end = as.Date("2024-12-01")),
                          reason = "2024 is the stress year of the demo panel")
m_ead$downturn$table
#>      pool       lra n_downturn dt_observed  dt_type3    ccf_dt ccf_final
#>    <char>     <num>      <int>       <num>     <num>     <num>     <num>
#> 1:     P1 0.2856519         91   0.2912069 0.4356519 0.2912069 0.3514617
#> 2:     P2 0.4962957         25   0.4628707 0.6462957 0.4962957 0.6264386
#> 3:     LF 0.8884167          7   0.8726786 1.0384167 0.8884167 1.0294951
#>    ccf_applied
#>          <num>
#> 1:   0.3514617
#> 2:   0.6264386
#> 3:   1.0294951
```

### Production, validation and export

[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
needs the limit, the drawn amount and the raw drivers of the admitted
set; the utilisation is derived. It returns the pool, the measure, the
applied CCF, the model EAD, the floor EAD (`drawn + 0.20 * undrawn`),
the predicted EAD as the greatest of the drawn amount, the model and the
floor, and whether the floor is the binding term. The five rows below
include an over-limit facility, which goes to `LF` and where the drawn
amount binds, and an undrawn one.

``` r

new_ead <- scr_demo_ead[scr_demo_ead$ref_date == as.Date("2025-06-01") &
                        scr_demo_ead$facility_id %in% c("F0001", "F0002", "F0004", "F0186", "F0615"), ]
new_ead[, c("facility_id", "product", "limit", "drawn")]
#>       facility_id product limit drawn
#> 30          F0001    card 12000  7070
#> 60          F0002    card  3000   320
#> 120         F0004    line 62500 29660
#> 5434        F0186    card  8000     0
#> 17907       F0615    card  3500  3680
ap_ead <- scr_apply(m_ead, new_ead)
ap_ead
#>      pool measure utilisation undrawn ccf_applied ead_model ead_floor
#>    <char>  <char>       <num>   <num>       <num>     <num>     <num>
#> 1:     P1     ulf   0.5891667    4930   0.3514617  8802.706      8056
#> 2:     P2     ulf   0.1066667    2680   0.6264386  1998.855       856
#> 3:     P1     ulf   0.4745600   32840   0.3514617 41202.001     36228
#> 4:     P2     ulf   0.0000000    8000   0.6264386  5011.509      1600
#> 5:     LF      lf   1.0514286       0   1.0294951  3603.233      3680
#>    ead_predicted ead_floor_binding
#>            <num>            <lgcl>
#> 1:      8802.706             FALSE
#> 2:      1998.855             FALSE
#> 3:     41202.001             FALSE
#> 4:      5011.509             FALSE
#> 5:      3680.000             FALSE
```

The floor never binds here because every applied CCF is above 0.20; the
column is there for the pool where it would. The SQL has four blocks:
utilisation and undrawn amount, the driver bin index from the frozen cut
points, the pool from the cells with the `LF` branch, and the applied
CCF with the predicted EAD as a `GREATEST` of the three terms.

``` r

sql_ead <- scr_sql(m_ead, table = "prd.facilities", dialect = "duckdb")
sql_ead_lines <- unlist(strsplit(sql_ead, "\n", fixed = TRUE))
cat(grep("AS pool$", sql_ead_lines, value = TRUE), sep = "\n")
#>     CASE WHEN undrawn <= 0 OR utilisation >= 0.95 THEN 'LF' WHEN (utilisation_idx = 1) THEN 'P2' WHEN (utilisation_idx = 2) THEN 'P1' ELSE 'P2' END AS pool
cat(tail(sql_ead_lines, 10), sep = "\n")
#> )
#> SELECT
#>     limit_amt, drawn_amt, utilisation, undrawn, pool, ccf_applied,
#>     CASE WHEN pool = 'LF' THEN GREATEST(drawn_amt, ccf_applied * limit_amt, drawn_amt + 0.2 * undrawn) ELSE GREATEST(drawn_amt, drawn_amt + ccf_applied * undrawn, drawn_amt + 0.2 * undrawn) END AS ead_predicted
#> FROM (
#>   SELECT
#>     *,
#>     CASE pool WHEN 'P1' THEN 0.3514616719732182 WHEN 'P2' THEN 0.62643859458525963 WHEN 'LF' THEN 1.0294951378084123 ELSE NULL END AS ccf_applied
#>   FROM pool_ead
#> ) ead;
```

``` r

con <- suppressMessages(DBI::dbConnect(duckdb::duckdb(), config = list(threads = "1")))
DBI::dbWriteTable(con, "facilities_t", new_ead)
got_ead <- DBI::dbGetQuery(con, paste(scr_sql(m_ead, table = "facilities_t", dialect = "duckdb"), collapse = "\n"))
DBI::dbDisconnect(con, shutdown = TRUE)
got_ead[, c("pool", "ccf_applied", "ead_predicted")]
#>   pool ccf_applied ead_predicted
#> 1   P1   0.3514617      8802.706
#> 2   P2   0.6264386      1998.855
#> 3   P1   0.3514617     41202.001
#> 4   P2   0.6264386      5011.509
#> 5   LF   1.0294951      3680.000
identical(got_ead$pool, ap_ead$pool)
#> [1] TRUE
all.equal(got_ead$ead_predicted, ap_ead$ead_predicted)
#> [1] TRUE
```

[`scr_ead_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_validate.md)
compares realised and predicted on the hold-out per pool and in total:
the one-sided t-test of realised above predicted, the EAD adequacy ratio
(realised over predicted EAD), the gAUC against the development value,
the back-test by cohort and the stability of the pool and bin
distributions. The numeric limits of the lights are a convention of the
package and the summary says so in its last column.

``` r

v_ead <- scr_ead_validate(m_ead)
v_ead
#> <scr_ead_validation> 71 rows (holdout)
#>   pool        n  realised predicted        t        p  light  adequacy  light
#>   P1         50    0.2763    0.3515   -1.260   0.8931 green     0.7884 green 
#>   P2         18    0.4536    0.6264   -1.987   0.9684 green     0.7915 green 
#>   LF          3    0.9022    1.0295   -0.924   0.7734 green     0.7288 green 
#>   TOTAL      71    0.3232    0.4242   -2.015   0.9760 green     0.7884 green 
#>   gAUC 0.5708 [0.5392, 0.6340] vs development 0.5582 (p 0.6239) | Spearman 0.2580 | CEAR 0.4077
#>   stability: pool PSI 0.0308 (stable) | utilisation_ref PSI 0.0319 (stable)
#>   lights: calibration_t_total green | ead_adequacy_total green | gauc_vs_development green | pool_psi green
v_ead$summary[, .(test, statistic, p, light)]
#>                   test   statistic         p  light
#>                 <char>       <num>     <num> <char>
#> 1: calibration_t_total -2.01492331 0.9760359  green
#> 2:  ead_adequacy_total  0.78841686        NA  green
#> 3: gauc_vs_development -0.31578204 0.6239160  green
#> 4:            pool_psi  0.03078423        NA  green
v_ead$backtest[, .(cohort, n, realised, predicted, p, adequacy, light_adequacy)]
#>    cohort     n  realised predicted         p adequacy light_adequacy
#>    <char> <int>     <num>     <num>     <num>    <num>         <char>
#> 1:   2023    27 0.1802738 0.4064571 0.9999845 0.633809          green
#> 2:   2024    44 0.4063661 0.4345942 0.6506991 0.866456          green
```

Every light is green because the estimate sits above the realised values
on the hold-out: the margin and the downturn push the applied CCF up,
and an adequacy ratio below one means the predicted EAD covers the
realised one. The workbook carries the funnel, the summaries, the driver
bins and the admission table, the pools and the cells, the downturn and
the margin, the hold-out metrics, the validation blocks, the model card
and the ledger, next to the SQL file.

``` r

basename(unlist(scr_export(m_ead, out, stamp = FALSE, validation = v_ead)$files))
#> [1] "ead_ccf.xlsx"    "sql_ead_ccf.sql"
```

## What both ledgers recorded

Neither parameter can be reconstructed from its pool table alone; the
ledger is the part of the object that says why the numbers are what they
are. The LGD ledger starts in the workout (discounting, cure treatment,
merged defaults, extrapolation, cost allocation, bounds), continues with
the split, the note of each stage and the driver the sign check removed,
the pool merges, the provisional downturn and the final one with its
periods and reason, and the floor with the framework, the asset class
and the secured share.

``` r

m$ledger[, .(action, detail, reason)]
#>                  action
#>                  <char>
#>  1:         discounting
#>  2:      cure_treatment
#>  3:   multiple_defaults
#>  4: incomplete_workouts
#>  5:     cost_allocation
#>  6:              bounds
#>  7:               split
#>  8:          cure_stage
#>  9:      severity_stage
#> 10: severity_sign_check
#> 11:          pool_merge
#> 12:            downturn
#> 13:            downturn
#> 14:               floor
#>                                                                                                         detail
#>                                                                                                         <char>
#>  1:                            reference rate at default + add-on 5.00%, monthly compounding over whole months
#>  2:        outstanding at the cure date (ead net of cash recovered) as an artificial recovery on the cure date
#>  3:                                               15 event(s) merged: gap below 9 months or overlapping spells
#>  4:      160 open event(s) extrapolated from the product recovery profile (lambda = 1); 2 closed at t_max = 60
#>  5:                                                                          indirect costs 0 allocated by ead
#>  6:                                                                    floor at zero: TRUE | cap at one: FALSE
#>  7:                                                           cohort split, hold-out 30.0%, cut-off 2024-01-01
#>  8:                                                                                                         OK
#>  9:                                                                                       fractional_logit: OK
#> 10:                                                                                                        ltv
#> 11:                                 4 band(s) below 100 defaults merged into the neighbour with the closer LRA
#> 12:                         provisional: type 3 add-on 15.0%; run scr_lgd_downturn() with the downturn periods
#> 13:                                    type1; add-on 15.0%; periods 2022-01-01 to 2023-12-31; mean impact 4.1%
#> 14: bcb retail_other: unsecured 30.0%, real_estate 10.0%, secured share 40.0%; binding in 0.0% of the defaults
#>                                    reason
#>                                    <char>
#>  1:                                      
#>  2:                                      
#>  3:                                      
#>  4:                                      
#>  5:                                      
#>  6:                                      
#>  7:                                      
#>  8:                                      
#>  9:                                      
#> 10:            SIGN_REVERSED_OR_TOO_LARGE
#> 11:                          MIN_DEFAULTS
#> 12:                      DOWNTURN_PENDING
#> 13: reference rate above 13% in 2022-2023
#> 14:
```

The EAD ledger has one row per step: how the reference data set was
built (horizon, measure rule, floors, where post-default drawings are
booked, the default level), how the pools were fitted (the admitted
drivers, the margin, the floor arithmetic) and the downturn with its
periods and reason.

``` r

m_ead$ledger[, .(step, action, reason)]
#>              step action                                    reason
#>            <char> <char>                                    <char>
#> 1: reference_data  build                             configuration
#> 2:          pools    fit                             configuration
#> 3:       downturn  type1 2024 is the stress year of the demo panel
```

Both ledgers travel unchanged into the `Decision_Ledger` sheet of the
workbook, and the SQL header of each model states the stages, the
downturn status and the floor it was generated with.
