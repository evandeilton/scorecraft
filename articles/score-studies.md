# Score studies

A score is validated with an AUC, but it is used through cuts: who is
approved, who is reviewed, who gets the retention offer. The score
studies of `scorecraft` answer the questions that come with the cuts.
How does the event rate move along the score? Which few groups can be
named and defended? Is the score still fit on new data? What can be
promised about a group, and with what confidence? Where should the cut
be under a budget or a team’s capacity? How do two scores read on the
same customers relate?

Every study aggregates the scored rows once into a table of counts and
works on that table afterwards, so a study of millions of rows costs one
grouped pass plus work proportional to the number of distinct scores.
The one exception is the rank association of
[`scr_score_cross()`](https://evandeilton.github.io/scorecraft/reference/scr_score_cross.md),
which sorts the rows of the two scores once more.

## 1. Three scores on the demo data

The demo table carries a risk target (`default`) and a propensity target
(`churn`) on the same customers. A light configuration fits a credit
scorecard, a mirrored copy of it read as a fraud score (a higher score
means more risk), and a churn scorecard. The split is out-of-time on
`ref_date`, so both targets share the same hold-out rows.

``` r

library(scorecraft)
library(data.table)
cfg <- scr_config(verbose = FALSE, nthread = 1, use_glmnet = TRUE, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                  date_col = "ref_date")
credit <- scr_scorecard(res)
fraud <- scr_scorecard(res, direction = "higher_is_riskier")

cfg_churn <- scr_config(objective = "propensity", verbose = FALSE, nthread = 1, use_glmnet = TRUE,
                        use_ranger = FALSE, use_lightgbm = FALSE, xgb_rounds = 60, n_boot = 20)
res_churn <- scr_select(scr_demo, "churn", config = cfg_churn, drop = c("id", "default"),
                        date_col = "ref_date")
churn <- scr_scorecard(res_churn)
```

## 2. Credit: bands, tiers and lights

[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
cuts the score into bands of equal share **frozen on the training
sample** and reads them on the hold-out. Each band reports its event
rate with a Jeffreys interval, the lift over the overall rate, the
cumulative capture of events and the KS at its lower edge; the last
column is the Holm-adjusted p-value of a one-sided Fisher test that the
band is riskier than the band before it (a rank-order reversal).

``` r

b <- scr_bands(credit, n_bands = 10, n_boot = 50, seed = 1)
b
#> <scr_study_bands> target "default" | objective risk | higher_is_safer
#>   bands frozen on 'train', read on 'holdout' | 10 requested, 10 effective (uniform)
#>   sample             n    events     rate AUC [95% CI]           Gini     KS     IV     PSI  reversals
#>   train          2,800       399   14.25% 0.7856 [0.763, 0.805]  0.571  0.441  1.136       -         0
#>   holdout        1,400       203   14.50% 0.7394 [0.710, 0.763]  0.479  0.389  0.804  0.0069         0
#> 
#> Bands on 'holdout' (event-richest first; 95% Jeffreys interval of the rate)
#>   band score                        pct rate [lo, hi]                 lift  capture     KS p_rev_adj
#>      1 [-Inf, 509.8922)            9.1% 35.43% [27.52%, 44.00%]       2.44    22.2%  0.153         -
#>      2 [509.8922, 523.5026)        9.1% 27.34% [20.19%, 35.51%]       1.89    39.4%  0.248     1.000
#>      3 [523.5026, 533.3684)        9.9% 26.62% [19.81%, 34.39%]       1.84    57.6%  0.345     1.000
#>      4 [533.3684, 542.0923)       10.6% 17.45% [12.01%, 24.14%]       1.20    70.4%  0.370     1.000
#>      5 [542.0923, 550.3612)       10.8% 11.26% [6.96%, 17.03%]        0.78    78.8%  0.342     1.000
#>      6 [550.3612, 557.7648)       10.6% 12.16% [7.64%, 18.15%]        0.84    87.7%  0.322     1.000
#>      7 [557.7648, 566.5601)       10.6% 7.38% [3.99%, 12.41%]         0.51    93.1%  0.261     1.000
#>      8 [566.5601, 576.5187)        9.1% 3.91% [1.51%, 8.35%]          0.27    95.6%  0.183     1.000
#>      9 [576.5187, 590.2783)        8.9% 3.23% [1.10%, 7.49%]          0.22    97.5%  0.102     1.000
#>     10 [590.2783, Inf)            11.2% 3.18% [1.23%, 6.84%]          0.22   100.0%  0.000     1.000
```

The hold-out shows 0 significant reversal(s) of the rank order, and the
summary compares the AUC on train and on the hold-out with bootstrap
intervals. A band with a wide interval is a band with few events; the
interval, not the point rate, is what a policy should be read against.

Ten bands are too many to name in a credit policy.
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)
groups the score into a few tiers by an exact dynamic program: every
tier holds at least 5% of the volume and 20 events and non-events,
adjacent tiers differ by a one-sided Fisher test, and among the
segmentations that meet those constraints the one with the best binomial
likelihood wins. `round_to` moves the cuts to round numbers, and
`n_boot` refits on resampled counts to show how stable each cut is.

``` r

tr <- scr_tiers(credit, n_tiers = 5, round_to = 5, n_boot = 30, seed = 1)
tr
#> <scr_study_tiers> target "default" | measure risk | higher_is_safer
#>   optimal (deviance) | 5 tiers requested, 5 achieved | fitted on 'train' | cuts rounded to 5
#>   cuts: 500, 515, 540, 555
#>   sample             n    events     rate     IV     PSI  tiers  monotone  distinct
#>   train          2,800       399   14.25%  1.143       -      5       yes       yes
#>   holdout        1,400       203   14.50%  0.752  0.0014      5        no        no
#> 
#> Tiers on 'holdout' (event-richest first)
#>   tier label              score                        pct     rate [95% CI]               p_adj
#>      5 01.very high       [-Inf, 500)                 5.4%   33.33% [23.45%, 44.47%]       0.753
#>      4 02.high            [500, 515)                  7.5%   37.14% [28.35%, 46.63%]       0.007
#>      3 03.medium          [515, 540)                 23.6%   23.03% [18.74%, 27.80%]       0.001
#>      2 04.low             [540, 555)                 19.6%   11.64% [8.25%, 15.82%]        0.001
#>      1 05.very low        [555, Inf)                 43.9%    5.04% [3.52%, 6.98%]             -
#> 
#> Stability (30 resamples): tier agreement 84.5%, same tier count 96.7%
tr$stability$cuts
#>      cut    score   median      q25      q75       iqr n_same
#>    <int>    <num>    <num>    <num>    <num>     <num>  <num>
#> 1:     1 502.3609 504.4274 502.3609 506.1428  3.781886     29
#> 2:     2 516.0750 516.0750 516.0750 526.5455 10.470557     29
#> 3:     3 538.0089 539.6230 538.0089 542.0923  4.083412     29
#> 4:     4 555.0927 555.0927 552.8810 556.8089  3.927859     29
```

The tiers are fitted on train, so the hold-out tells whether they hold.
Its summary line reads `monotone` “no”: the tiers are monotone on train
by construction, but on the hold-out at least one pair of adjacent tiers
comes out in the wrong order. The p_adj column and the intervals of the
table say which pair, and whether the two tiers can be told apart at all
on new data. The interquartile range of each refitted cut, in score
points, shows which boundaries the data pins down and which ones a
different sample would move.

[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md)
turns the comparison of the hold-out with train into red, amber and
green lights for discrimination, calibration, stability and the
variables of the scorecard, each lit only when its confidence interval
or test shows a deviation.

``` r

rg <- scr_rag(credit, n_boot = 50, seed = 1)
rg$summary
#>     sample  group discrimination calibration stability variables overall reason
#>     <char> <char>         <char>      <char>    <char>    <char>  <char> <char>
#> 1: holdout    all          amber       green     green     amber   amber
```

## 3. Fraud: tail bands, action tiers and a daily capacity

A fraud score is read at its tail: the riskiest 2%, 5% or 10% of the
traffic, not its deciles. `spacing = "tail"` places the cuts at
cumulative shares counted from the event-rich end, here the high scores.

``` r

bf <- scr_bands(fraud, spacing = "tail", tail_probs = c(0.02, 0.05, 0.10, 0.20, 0.50), n_boot = 0)
bf$table[sample == "holdout", .(band, label, pct, rate, lift, capture)]
#>     band                label        pct       rate      lift    capture
#>    <int>               <char>      <num>      <num>     <num>      <num>
#> 1:     1      [490.1607, Inf) 0.01428571 0.35000000 2.4137931 0.03448276
#> 2:     2 [474.5723, 490.1607) 0.03785714 0.33962264 2.3422251 0.12315271
#> 3:     3 [464.3536, 474.5723) 0.03857143 0.37037037 2.5542784 0.22167488
#> 4:     4 [450.7431, 464.3536) 0.09142857 0.27343750 1.8857759 0.39408867
#> 5:     5 [423.8846, 450.7431) 0.31357143 0.18223235 1.2567748 0.78817734
#> 6:     6     [-Inf, 423.8846) 0.50428571 0.06090652 0.4200449 1.00000000
```

Three actions (pass, review, block) are three tiers; the labels follow
the event rate, lowest first.

``` r

tf <- scr_tiers(fraud, n_tiers = 3, labels = c("pass", "review", "block"))
tf$table[sample == "holdout", .(tier, label, score_lo, score_hi, pct, rate)]
#>     tier  label score_lo score_hi       pct       rate
#>    <int> <char>    <num>    <num>     <num>      <num>
#> 1:     3  block 458.1708      Inf 0.1321429 0.35675676
#> 2:     2 review 423.2734 458.1708 0.3728571 0.18390805
#> 3:     1   pass     -Inf 423.2734 0.4950000 0.05916306
```

How deep can the review queue go? A review team has a capacity per day.
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md)
accumulates the score from its event-rich end and, with a date column,
reads the selected volume of every date at each candidate cut. In the
demo the date is monthly, so the capacity is read per month: here at
most 80 cases on nine months in ten (`day_quantile = 0.9`), over the six
months of the whole table. The rates of this curve include the training
months and are therefore optimistic; the volumes, which is what a
capacity is about, are not.

``` r

d_fraud <- data.frame(score = scr_apply(fraud, scr_demo)$score, y = scr_demo$default,
                      month = scr_demo$ref_date)
op_f <- scr_operating(d_fraud, objective = "risk", direction = "higher_is_riskier",
                      max_per_day = 80, date = "month")
op_f
#> <scr_operating> target "y" | objective risk | higher_is_riskier | side event (from the high scores, score >= cut)
#>   sample 'all' | 4188 score values | 6 dates | economics: none
#>   constraints: max_per_day 80
#> 
#> Optimum: cut 463.0245 | depth 10.4% (n 438) | rate 42.9% [38.3%, 47.6%] | capture 31.2% | value -
#>   binding: max_per_day | shadow price - per additional case | next marginal rate 33.6%
#> 
#> Curve (selected rows)
#>     depth          cut      n_sel rate [lo, hi]             capture   lift  marginal          value     day_q feasible
#>      1.0%     497.4886         42 66.7% [51.7%, 79.4%]         4.7%   4.65     45.6%              -       8.5      yes
#>      5.0%     475.1601        210 47.6% [40.9%, 54.4%]        16.6%   3.32     42.1%              -      39.0      yes
#>     10.0%     463.7915        420 42.9% [38.2%, 47.6%]        29.9%   2.99     33.6%              -      78.0      yes
#>     10.4%     463.0245        438 42.9% [38.3%, 47.6%]        31.2%   2.99     33.6%              -      80.0      yes  <- optimum
#>     20.0%      450.096        840 34.4% [31.3%, 37.7%]        48.0%   2.40     22.6%              -     152.0       no
#>     50.0%     423.8132      2,100 23.8% [22.0%, 25.7%]        83.1%   1.66     10.3%              -     358.5       no
#>    100.0%         -Inf      4,200 14.3% [13.3%, 15.4%]       100.0%   1.00      0.0%              -     700.0       no
```

Without economics the optimum is the deepest cut that fits the capacity,
and `binding` names the constraint that stops it. The curve shows what
the capacity costs: the optimum captures 31.2% of the defaults, and the
next score value beyond it still has a smoothed default rate of 33.6%,
against an overall rate of 14.3%.

## 4. Churn: anchored tiers, claims and a budget

Under propensity the event is the outcome sought, and tiers can be
anchored on event rates that mean something to the business: below 15%,
around the overall churn rate and above 50%.

``` r

ta <- scr_tiers(churn, method = "anchored", anchors = c(0.15, "overall", 0.5))
ta
#> <scr_study_tiers> target "churn" | measure propensity | higher_is_riskier
#>   anchored | 4 tiers requested, 4 achieved | fitted on 'train'
#>   cuts: 432.3465, 456.9944, 486.6599
#>   sample             n    events     rate     IV     PSI  tiers  monotone  distinct
#>   train          2,800       797   28.46%  0.761       -      4       yes       yes
#>   holdout        1,400       424   30.29%  0.692  0.0008      4       yes       yes
#> 
#> Tiers on 'holdout' (event-richest first)
#>   tier label              score                        pct     rate [95% CI]               p_adj
#>      4 01.high            [486.6599, Inf)            13.9%   65.46% [58.58%, 71.89%]       0.000
#>      3 02.medium high     [456.9944, 486.6599)       34.1%   34.38% [30.22%, 38.73%]       0.001
#>      2 03.medium low      [432.3465, 456.9944)       31.7%   24.32% [20.51%, 28.47%]       0.000
#>      1 04.low             [-Inf, 432.3465)           20.4%    8.77% [5.90%, 12.47%]            -
```

[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md)
turns such statements into tests. Each claim names a group (a tier, a
band or a score range), a direction and a rate; it is tested on the
hold-out with an exact one-sided binomial test, Holm-adjusted across the
claims, and reported with its one-sided Jeffreys bound. A claim is
“supported” when the data show it, “refuted” when they show the opposite
and “not proven” otherwise.

``` r

claims <- data.frame(
  name = c("high tier churns", "top of the score", "low tier is quiet"),
  label = c("high", NA, "low"), score_lo = c(NA, 480, NA),
  op = c(">=", ">=", "<="), rate = c(0.50, 0.60, 0.15))
cl <- scr_claims(ta, claims)
cl
#> <scr_claims> target "churn" | objective propensity | sample 'holdout' | level 95% (one-sided) | adjustment holm | average
#>   claim                    group                              n     rate    bound claimed       p_adj  verdict
#>   high tier churns         high                             194    65.5%    59.7% >= 50.0%     0.0000  supported
#>   top of the score         score >= 480                     278    60.4%    55.5% >= 60.0%     0.4675  not proven
#>   low tier is quiet        low                              285     8.8%    11.8% <= 15.0%     0.0024  supported
#> 
#> On 'holdout' (n = 194), rows in tier 'high' had an event rate of 65.5% (95% one-sided lower bound
#>   59.7%); the claim 'high tier churns' (rate >= 50%) is supported.
#> On 'holdout' (n = 278), rows with score >= 480 had an event rate of 60.4% (95% one-sided lower
#>   bound 55.5%); the claim 'top of the score' (rate >= 60%) is not proven.
#> On 'holdout' (n = 285), rows in tier 'low' had an event rate of 8.8% (95% one-sided upper bound
#>   11.8%); the claim 'low tier is quiet' (rate <= 15%) is supported.
```

The claim on the top of the score shows the difference between a point
rate and a statement: the observed rate is 60.4% against a claim of 60%,
so the one-sided lower bound sits below the claim and the claim is not
proven.

A rate of a group is an average. `type = "floor"` tests the claim on the
weakest end of the group instead: the reference rows of the group are
cut into ten pre-bins (`floor_bins`), a monotone fit of their rates
along the score (pool adjacent violators) finds the end where the claim
is hardest to meet (the lowest rates for a “rate \>= r” claim, the
highest for “rate \<= r”), and the claim is tested on the hold-out rows
of that end. A dip inside the group is averaged with its neighbors by
the fit, and the pre-bins set the resolution, so the floor speaks for
the weakest tenth or more of the group, not for each customer.

``` r

fl <- scr_claims(ta, claims, type = "floor")
fl$table[, .(name, group, score_lo, score_hi, n, rate, bound, verdict)]
#>                 name        group score_lo score_hi     n      rate     bound
#>               <char>       <char>    <num>    <num> <num>     <num>     <num>
#> 1:  high tier churns         high 486.6599 496.8521    79 0.5569620 0.4645748
#> 2:  top of the score score >= 480 480.0000 483.7317    46 0.4782609 0.3604868
#> 3: low tier is quiet          low 430.0975 432.3465    18 0.2222222 0.4082341
#>       verdict
#>        <char>
#> 1: not proven
#> 2: not proven
#> 3: not proven
```

An average can be supported while its floor is not: on the tier “high”,
the average claim is supported but its floor is not proven, because the
customers at the low end of the tier churn less than the tier as a
whole.

A retention campaign has a gain per event reached (a churner who gets
the offer; how many of them stay is part of that gain), a cost per
contact and a budget.
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md)
maximizes the value of the campaign along the score within the budget
and reports the shadow price, what one more contact beyond the optimum
would be worth.

``` r

op_c <- scr_operating(churn, gain_event = 100, cost_select = 20, budget = 3000)
op_c$optimum[, .(cut, depth, n_sel, rate_sel, value, binding, shadow_price)]
#>         cut     depth n_sel  rate_sel value binding shadow_price
#>       <num>     <num> <num>     <num> <num>  <char>        <num>
#> 1: 492.3036 0.1042857   146 0.6986301  7280  budget     37.14286
```

The binding constraint is the budget, and the shadow price of 37.1 per
contact is positive: the next contacts would still pay, so the budget,
not the score, limits the campaign.

## 5. Credit and churn on the same customers

The two scorecards score the same hold-out rows.
[`scr_score_cross()`](https://evandeilton.github.io/scorecraft/reference/scr_score_cross.md)
crosses their tiers, reports the event rate of both targets in every
cell, the rank association of the scores, and the overlap of the
customers each score puts first.

``` r

ho <- scr_demo[res$split$holdout_idx, ]
d_x <- data.frame(credit = scr_apply(credit, ho)$score, churn = scr_apply(churn, ho)$score,
                  default = ho$default, churned = ho$churn)
cx <- scr_score_cross(d_x, "credit", "churn", y_a = "default", y_b = "churned",
                      objective_b = "propensity", cuts_a = tr, cuts_b = ta)
cx
#> <scr_score_cross> A "credit" (risk, higher_is_safer) | B "churn" (propensity, higher_is_riskier)
#>   1,400 rows | outcomes: default, churned | bands: A tiers, B tiers
#>   association (raw scores): Spearman -0.432, Kendall tau-b -0.299 | oriented to the event-rich ends: 0.432, 0.299
#> 
#> Share of rows
#>   A \ B                           B1        B2        B3        B4     total
#>   A1 very low                  13.4%     17.1%     11.1%      2.4%     43.9%
#>   A2 low                        3.2%      7.1%      7.6%      1.8%     19.6%
#>   A3 medium                     2.9%      6.4%      9.7%      4.6%     23.6%
#>   A4 high                       0.8%      0.6%      4.0%      2.1%      7.5%
#>   A5 very high                  0.1%      0.4%      1.7%      3.1%      5.4%
#>   total                        20.4%     31.7%     34.1%     13.9%    100.0%
#> 
#> Event rate of "default"
#>   A \ B                           B1        B2        B3        B4     total
#>   A1 very low                   2.7%      5.0%      7.1%      9.1%      5.0%
#>   A2 low                        8.9%     12.1%      9.4%     24.0%     11.6%
#>   A3 medium                    10.0%     18.9%     25.0%     32.8%     23.0%
#>   A4 high                      18.2%     33.3%     42.9%     34.5%     37.1%
#>   A5 very high                 50.0%     33.3%     37.5%     30.2%     33.3%
#>   total                         5.6%     10.4%     18.4%     27.3%     14.5%
#> 
#> Event rate of "churned"
#>   A \ B                           B1        B2        B3        B4     total
#>   A1 very low                   6.4%     18.8%     19.4%     60.6%     17.4%
#>   A2 low                       15.6%     27.3%     39.6%     56.0%     32.7%
#>   A3 medium                    12.5%     30.0%     37.5%     60.9%     37.0%
#>   A4 high                       0.0%     44.4%     42.9%     79.3%     48.6%
#>   A5 very high                 50.0%     83.3%     70.8%     72.1%     72.0%
#>   total                         8.8%     24.3%     34.4%     65.5%     30.3%
#>   B bands: B1 low, B2 medium low, B3 medium high, B4 high
#> 
#> Overlap (each score selects from its event-rich end)
#>    depth  share_a  share_b       n_a       n_b      both    A only    B only  Jaccard
#>     5.0%     5.0%     5.0%        70        70        17        53        53    0.138
#>    10.0%    10.0%    10.0%       140       140        45        95        95    0.191
#>    20.0%    20.0%    20.0%       280       280       125       155       155    0.287
#> 
#> Event rate of each set (B only = swap-in, A only = swap-out)
#>    depth outcome              A         B      both    A only    B only
#>     5.0% churned          71.4%     75.7%     76.5%     69.8%     75.5%
#>    10.0% churned          64.3%     69.3%     77.8%     57.9%     65.3%
#>    20.0% churned          52.9%     60.4%     68.0%     40.6%     54.2%
#>     5.0% default          34.3%     30.0%     35.3%     34.0%     28.3%
#>    10.0% default          35.7%     27.9%     31.1%     37.9%     26.3%
#>    20.0% default          31.4%     25.7%     32.8%     30.3%     20.0%
```

The oriented association (Spearman 0.43) is positive: the customers the
credit score calls risky tend to be those the churn score calls likely
to leave. The overlap table says how far that goes at the top of each
score, and the rates of the “A only” and “B only” sets say what changes
when one list is replaced by the other.

## 6. Production

Bands and tiers are assigned to new scores in R and in SQL from the same
frozen cuts, and every study writes a workbook. A tier label carries its
order in front, `01` for the tier with the highest event rate, so that
the labels sort from the event-richest tier in a report or an
`ORDER BY`; the tiers table has the same value in `tier_label`, and
`numbered = FALSE` returns the plain labels.

``` r

head(scr_apply(tr, c(495, 520, 560)))
#>    score  tier   tier_label
#>    <num> <int>       <char>
#> 1:   495     5 01.very high
#> 2:   520     3    03.medium
#> 3:   560     1  05.very low
sql <- scr_sql(tr, table = "scored", dialect = "postgres")
substr(sql[9], 1, 80)
#> [1] "    CASE WHEN s.score IS NULL THEN NULL WHEN s.score < 500 THEN 5 WHEN s.score <"
substr(sql[10], 1, 80)
#> [1] "    CASE WHEN s.score IS NULL THEN NULL WHEN s.score < 500 THEN '01.very high' W"
```

[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
writes `study_tiers_<target>.xlsx`, `claims_<target>.xlsx`,
`operating_<target>.xlsx` and `score_cross_<a>_<b>.xlsx` for the objects
above.
