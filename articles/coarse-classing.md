# Coarse classing: manual bins and manual variable choice with an audit trail

## Why manual coarse classing still matters

Optimal binning does one job well: it finds the cut points and the
groupings that maximise the information value of a variable subject to
the admission rules (minimum bin size, monotonicity, hold-out
stability). What it cannot know is how the business reads the variable.
A bureau score is communicated to underwriters in policy bands; a region
is priced as north and south, not as five states; an age is quoted in
decades. A scorecard whose bins cut at 33.36 and 48.06 is correct, but
nobody in the credit committee can explain it, and a bin nobody can
explain is a bin nobody will defend when the model is challenged.

There is also a stability argument. The optimal cut points are estimated
on one training window, and a handful of them sit on thin slices of the
distribution. Coarser, rounder bands lose a little information value on
train and often lose nothing on hold-out, while being far less likely to
drift when the population shifts. The lab in `scorecraft` lets the
analyst make exactly that trade, and shows the price of it on train and
hold-out before anything is committed.

What the lab refuses to do is let a manual decision enter silently.
Every proposal is compared against the optimal bins, every acceptance
carries a reason, every override of a blocking rule is a row in an
append-only ledger, and the automatic artefacts are frozen alongside the
manual ones. The scorecard, the R scoring function and the production
SQL consume the manual bins through the very same code path as the
optimal ones, so there is no second implementation to keep in step.

## A fast selection run

The lab opens on an
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
result. The configuration below is the quick one used in the package
tests: single thread, two consensus voters and a light bootstrap, enough
for a few seconds of run time on `scr_demo`.

``` r

library(scorecraft)
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg,
                  drop = c("id", "churn"), date_col = "ref_date")
scr_selected(res)
#>  [1] "vl_score_01" "vl_score_02" "vl_score_04" "ds_faixa"    "vl_tardio"  
#>  [6] "ds_regiao"   "vl_score_06" "vl_score_07" "vl_score_05" "ds_canal"   
#> [11] "vl_hist_04"  "vl_score_10"
```

## Opening the lab

[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
covers every variable that reached binning, not only the consensus
shortlist, so a variable failed by screening can be rebinned and forced
in later with a reason. `author` is free text recorded in the ledger; it
defaults to the system user.

``` r

lab <- scr_coarse_classing(res, author = "analyst")
lab
#> <scr_classing> target "default" | opened 2026-09-04 13:09 by analyst | 37 variables | 0 proposals: 0 accepted, 0 discarded
#>   final choice: 12 variables | consensus 12 | force: (none) | drop: (none)
```

Without a variable,
[`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md)
prints one line per variable: its current source (optimal or manual),
the number of bins, the train and hold-out IV, the PSI and a verdict
computed with the same rules a proposal will face. The last column says
whether the variable is currently in the final shortlist.

``` r

ov <- scr_classing_view(lab)
#> <scr_classing> target "default" | 37 variables
#>   variable                     source    bins  IV train   IV hold     PSI verdict     shortlist
#>   vl_score_01                  optimal      7    0.3464    0.2877  0.0066 ACCEPTABLE  yes
#>   vl_score_02                  optimal      7    0.1721    0.1234  0.0053 ACCEPTABLE  yes
#>   vl_score_03                  optimal      3    0.0576    0.0517  0.0003 REVIEW      -
#>   vl_score_04                  optimal      7    0.1243    0.1177  0.0032 ACCEPTABLE  yes
#>   vl_score_05                  optimal      5    0.0363    0.0289  0.0024 ACCEPTABLE  yes
#>   vl_score_06                  optimal      7    0.0483    0.0794  0.0049 ACCEPTABLE  yes
#>   vl_score_07                  optimal      6    0.0505    0.0705  0.0071 ACCEPTABLE  yes
#>   vl_score_08                  optimal      3    0.0149    0.0055  0.0026 REVIEW      -
#>   vl_score_09                  optimal      3    0.0072    0.0001  0.0012 REVIEW      -
#>   vl_score_10                  optimal      3    0.0282    0.0432  0.0024 ACCEPTABLE  yes
#>   vl_score_11                  optimal      6    0.0781    0.0177  0.0064 REVIEW      -
#>   vl_score_12                  optimal      6    0.0717    0.0321  0.0061 REVIEW      -
#>   vl_hist_01                   optimal      3    0.0029    0.0158  0.0012 REVIEW      -
#>   vl_hist_01__sp               optimal      2    0.0315    0.0069  0.0017 REVIEW      -
#>   vl_hist_02                   optimal      5    0.0075    0.0730  0.0033 REVIEW      -
#>   vl_hist_02__sp               optimal      2    0.0296    0.0464  0.0000 ACCEPTABLE  -
#>   vl_hist_03                   optimal      3    0.0205    0.0092  0.0013 REVIEW      -
#>   vl_hist_03__sp               optimal      2    0.0357    0.0764  0.0006 ACCEPTABLE  -
#>   vl_hist_04                   optimal      3    0.0332    0.0809  0.0047 ACCEPTABLE  yes
#>   vl_hist_04__sp               optimal      2    0.0642    0.1053  0.0058 ACCEPTABLE  -
#>   vl_parcial_01                optimal      5    0.0045    0.0144  0.0051 REVIEW      -
#>   vl_parcial_01__sp            optimal      2    0.0020    0.0036  0.0002 REVIEW      -
#>   vl_parcial_02                optimal      4    0.0036    0.0111  0.0013 REVIEW      -
#>   vl_parcial_02__sp            optimal      2    0.0031    0.0062  0.0002 REVIEW      -
#>   vl_tardio                    optimal      7    0.0711    0.0638  0.1042 ACCEPTABLE  yes
#>   vl_ruido_01                  optimal      3    0.0031    0.0079  0.0015 REVIEW      -
#>   vl_ruido_02                  optimal      6    0.0084    0.0231  0.0062 REVIEW      -
#>   vl_ruido_03                  optimal      5    0.0188    0.0173  0.0039 REVIEW      -
#>   vl_ruido_04                  optimal      3    0.0053    0.0192  0.0004 REVIEW      -
#>   vl_ruido_05                  optimal      3    0.0018    0.0020  0.0050 REVIEW      -
#>   vl_ruido_06                  optimal      6    0.0024    0.0501  0.0032 REVIEW      -
#>   vl_redundante                optimal      7    0.1743    0.1071  0.0065 ACCEPTABLE  -
#>   ds_regiao                    optimal      5    0.0846    0.0971  0.0064 ACCEPTABLE  yes
#>   ds_faixa                     optimal      4    0.0805    0.0780  0.0013 ACCEPTABLE  yes
#>   ds_canal                     optimal      3    0.0279    0.0438  0.0003 ACCEPTABLE  yes
#>   ds_optin                     optimal      3    0.0065    0.0032  0.0019 REVIEW      -
#>   vl_hist_05__sp               optimal      2    0.0191    0.0428  0.0006 REVIEW      -
```

With a variable, the view is the bin table with train and hold-out side
by side, plus a text bar chart of the event rate. `vl_score_01` is a
numeric with seven optimal bins; `ds_regiao` is a categorical with one
bin per state.

``` r

scr_classing_view(lab, "vl_score_01")
#> <scr_classing> vl_score_01 (numerical) | current: optimal (jedi) | 7 bins | train IV 0.3464, hold-out IV 0.2877 (ratio 0.86)
#>   monotone: yes | min bin 5.2% | PSI 0.0066 (stable) | KS 0.198 | degenerate bins: 0 | verdict: ACCEPTABLE
#>    id  bin                                  n      %  events   rate      WOE      IV |  n.hold      %    rate WOE.hold
#>     1  (-Inf;33.360000]                   145   5.2%       3   2.1%   -2.063   0.106 |      69   4.9%    4.3%   -1.317
#>     2  (33.360000;38.150000]              162   5.8%      12   7.4%   -0.731   0.024 |      76   5.4%    3.9%   -1.417
#>     3  (38.150000;44.240000]              366  13.1%      29   7.9%   -0.658   0.045 |     171  12.2%    7.6%   -0.723
#>     4  (44.240000;48.060000]              301  10.8%      27   9.0%   -0.523   0.024 |     158  11.3%   10.8%   -0.341
#>     5  (48.060000;63.940000]            1,343  48.0%     198  14.7%    0.040   0.001 |     664  47.4%   15.2%    0.056
#>     6  (63.940000;72.610000]              338  12.1%      85  25.1%    0.704   0.076 |     201  14.4%   22.4%    0.531
#>     7  (72.610000;+Inf]                   145   5.2%      45  31.0%    0.996   0.071 |      61   4.4%   34.4%    1.130
#>   event rate by bin (train | hold-out)
#>     1  #                    2.1% | ##                   4.3%
#>     2  ####                 7.4% | ##                   3.9%
#>     3  ####                 7.9% | ####                 7.6%
#>     4  #####                9.0% | ######              10.8%
#>     5  ########            14.7% | ########            15.2%
#>     6  #############       25.1% | ############        22.4%
#>     7  ################    31.0% | ##################  34.4%
```

``` r

scr_classing_view(lab, "ds_regiao")
#> <scr_classing> ds_regiao (categorical) | current: optimal (jedi) | 5 bins | train IV 0.0846, hold-out IV 0.0971 (ratio 1.14)
#>   monotone: yes | min bin 7.9% | PSI 0.0064 (stable) | KS 0.114 | degenerate bins: 0 | verdict: ACCEPTABLE
#>    id  bin                                  n      %  events   rate      WOE      IV |  n.hold      %    rate WOE.hold
#>     1  MG                                 539  19.2%      57  10.6%   -0.341   0.020 |     301  21.5%   13.0%   -0.130
#>     2  SP                               1,139  40.7%     144  12.6%   -0.139   0.008 |     551  39.4%   13.8%   -0.058
#>     3  RJ                                 582  20.8%      82  14.1%   -0.014   0.000 |     269  19.2%   10.0%   -0.419
#>     4  BA                                 318  11.4%      66  20.8%    0.453   0.027 |     178  12.7%   23.6%    0.599
#>     5  RS                                 222   7.9%      50  22.5%    0.557   0.030 |     101   7.2%   18.8%    0.312
#>   event rate by bin (train | hold-out)
#>     1  ########            10.6% | ##########          13.0%
#>     2  ##########          12.6% | ###########         13.8%
#>     3  ###########         14.1% | ########            10.0%
#>     4  ################    20.8% | ##################  23.6%
#>     5  #################   22.5% | ##############      18.8%
```

## Proposing bins

[`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md)
takes exactly one instruction per call. For a numeric variable the
instruction is `breaks` (absolute interior cut points), `merge`
(adjacent bin ids) or `split` (`c(id, at)`). For a categorical it is
`groups` (a list of character vectors, optionally named), `merge` (bin
ids), `missing_to` (which bin receives the `"MISSING"` category) or
`other_to` (the catch-all bin for every training category not listed). A
proposal is a value: nothing changes in the lab until it is accepted.

### Numeric: breaks, merge, split

Suppose underwriting quotes `vl_score_01` in the bands below 40, 40 to
55, 55 to 70 and above 70.

``` r

p_breaks <- scr_classing_propose(lab, "vl_score_01", breaks = c(40, 55, 70))
p_breaks
#> <scr_classing_proposal> P001 vl_score_01 | breaks = c(40, 55, 70) | 2026-09-04 13:09
#>                         optimal     manual      delta
#>   n_bins                      7          4         -3
#>   iv_train               0.3464     0.2993    -0.0471
#>   iv_holdout             0.2877     0.2740    -0.0137
#>   iv_ratio               0.8649     0.9236     0.0587
#>   ks                     0.1981     0.2472     0.0490
#>   psi                    0.0066     0.0032    -0.0034
#>   min_bin_pct            0.0518     0.0786     0.0268
#>   largest_bin_pct        0.4796     0.4307    -0.0489
#>   n_degenerate                0          0          0
#>   monotonic                   1          1          0
#>   manual bins (train | hold-out)
#>     1  (-Inf;40.000000]                   405  14.5%   5.9%  -0.970 |     193  13.8%   5.2%  -1.133
#>     2  (40.000000;55.000000]            1,206  43.1%  10.0%  -0.399 |     588  42.0%  11.4%  -0.277
#>     3  (55.000000;70.000000]              969  34.6%  19.6%   0.384 |     520  37.1%  18.1%   0.263
#>     4  (70.000000;+Inf]                   220   7.9%  29.1%   0.904 |      99   7.1%  32.3%   1.035
#>   Verdict: ACCEPTABLE - no warning raised.
```

The header repeats the instruction. The comparison table has one row per
metric and three columns: the optimal bins, the proposal and the
difference. Here the four policy bands cost about 0.05 of IV on train
and about 0.014 on hold-out, while the IV ratio (hold-out over train),
the KS and the smallest bin all improve, and the PSI halves. Below the
table are the manual bins themselves with count, share, event rate and
WOE on train and on hold-out. No warning was raised, so the verdict is
`ACCEPTABLE`.

`merge` and `split` are relative to the *current* bins of the variable
and resolve to absolute cut points, which is what the header shows.

``` r

p_merge <- scr_classing_propose(lab, "vl_score_01", merge = c(1, 2))
p_merge$entry$cutpoints
#> [1] 38.15 44.24 48.06 63.94 72.61
p_split <- scr_classing_propose(lab, "vl_score_01",
                                split = c(1, res$fit$results$vl_score_01$cutpoints[1] - 5))
p_split
#> <scr_classing_proposal> P003 vl_score_01 | split = c(1, 28.36) | 2026-09-04 13:09
#>                         optimal     manual      delta
#>   n_bins                      7          8          1
#>   iv_train               0.3464     0.3561     0.0098
#>   iv_holdout             0.2877     0.2895     0.0018
#>   iv_ratio               0.8649     0.8745     0.0097
#>   ks                     0.1981     0.1981     0.0000
#>   psi                    0.0066     0.0067     0.0001
#>   min_bin_pct            0.0518     0.0211    -0.0307
#>   largest_bin_pct        0.4796     0.4796     0.0000
#>   n_degenerate                0          0          0
#>   monotonic                   1          0         -1
#>   manual bins (train | hold-out)
#>     1  (-Inf;28.360000]                    59   2.1%   3.4%  -1.555 |      27   1.9%   7.4%  -0.751
#>     2  (28.360000;33.360000]               86   3.1%   1.2%  -2.648 |      42   3.0%   2.4%  -1.939
#>     3  (33.360000;38.150000]              162   5.8%   7.4%  -0.731 |      76   5.4%   3.9%  -1.417
#>     4  (38.150000;44.240000]              366  13.1%   7.9%  -0.658 |     171  12.2%   7.6%  -0.723
#>     5  (44.240000;48.060000]              301  10.8%   9.0%  -0.523 |     158  11.3%  10.8%  -0.341
#>     6  (48.060000;63.940000]            1,343  48.0%  14.7%   0.040 |     664  47.4%  15.2%   0.056
#>     7  (63.940000;72.610000]              338  12.1%  25.1%   0.704 |     201  14.4%  22.4%   0.531
#>     8  (72.610000;+Inf]                   145   5.2%  31.0%   0.996 |      61   4.4%  34.4%   1.130
#>   Warnings
#>     - NOT_MONOTONIC
#>   Verdict: REVIEW - advisory warnings only; accept with a reason or discard.
```

The split proposal is a `REVIEW`: the new first bin holds 2% of the
training rows and breaks the monotone pattern of the event rate, so the
engine’s `NOT_MONOTONIC` rule fires. A `REVIEW` verdict is advisory: the
proposal can be accepted with a reason or discarded. Note that the three
proposals above all print as `P001`: a proposal takes the next free id
at the moment it is made, and the id is only reserved when the proposal
is accepted or discarded. Competing proposals made against the same
untouched lab therefore share an id, and once one of them is acted on
the lab refuses the others (it will not act twice on `P001`). The idiom
to remember is *propose, decide, propose*: proposals made side by side
are for comparison, and the one to be kept is remade right before it is
decided.

### Categorical: groups, other_to, missing_to

Pricing works with two regions. Names given to the groups are display
labels; the bin label stored in the entry is the categories joined by
the configuration’s separator, exactly as the binning engine writes it.

``` r

p_groups <- scr_classing_propose(lab, "ds_regiao",
                                 groups = list(south = c("BA", "RS"),
                                               north = c("SP", "RJ", "MG")))
p_groups
#> <scr_classing_proposal> P004 ds_regiao | groups = list(south = c("BA", "RS"), north = c("SP", "RJ", "MG")) | 2026-09-04 13:09
#>                         optimal     manual      delta
#>   n_bins                      5          2         -3
#>   iv_train               0.0846     0.0739    -0.0107
#>   iv_holdout             0.0971     0.0786    -0.0186
#>   iv_ratio               1.1432     1.0568    -0.0864
#>   ks                     0.1141     0.1141     0.0000
#>   psi                    0.0064     0.0003    -0.0061
#>   min_bin_pct            0.0793     0.1929     0.1136
#>   largest_bin_pct        0.4068     0.8071     0.4004
#>   n_degenerate                0          0          0
#>   monotonic                   1          1          0
#>   manual bins (train | hold-out)
#>     1  BA | RS                            540  19.3%  21.5%   0.499 |     279  19.9%  21.9%   0.501
#>     2  SP | RJ | MG                     2,260  80.7%  12.5%  -0.149 |   1,121  80.1%  12.7%  -0.156
#>   Warnings
#>     - IV_LOSS_VS_OPTIMAL
#>   Verdict: REVIEW - advisory warnings only; accept with a reason or discard.
```

Every training category must land somewhere. Listing them all is one
option; the other is to name a catch-all bin with `other_to`, which is
also how a reviewer says “everything else goes here”. The result is the
same grouping, and the entry records that the second bin is the
catch-all (`is_other`).

``` r

p_other <- scr_classing_propose(lab, "ds_regiao",
                                groups = list(south = c("BA", "RS"), rest = "SP"),
                                other_to = "rest")
p_other$entry$bin
#> [1] "BA%;%RS"      "SP%;%RJ%;%MG"
p_other$entry$manual$is_other
#> [1] FALSE  TRUE
```

`ds_optin` carries a `"MISSING"` category, which the optimal binning
kept on its own. `missing_to` folds it into another bin.

``` r

p_missing <- scr_classing_propose(lab, "ds_optin", missing_to = 1)
p_missing
#> <scr_classing_proposal> P006 ds_optin | missing_to = 1 | 2026-09-04 13:09
#>                         optimal     manual      delta
#>   n_bins                      3          2         -1
#>   iv_train               0.0065     0.0000    -0.0065
#>   iv_holdout             0.0032     0.0023    -0.0008
#>   iv_ratio               0.4676  8743.8015  8743.3339
#>   ks                     0.0237     0.0004    -0.0233
#>   psi                    0.0019     0.0017    -0.0001
#>   min_bin_pct            0.0975     0.4414     0.3439
#>   largest_bin_pct        0.4611     0.5586     0.0975
#>   n_degenerate                0          0          0
#>   monotonic                   1          1          0
#>   manual bins (train | hold-out)
#>     1  SIM | MISSING                    1,564  55.9%  14.3%   0.001 |     753  53.8%  13.9%  -0.046
#>     2  NAO                              1,236  44.1%  14.2%  -0.001 |     647  46.2%  15.1%   0.051
#>   Warnings
#>     - IV_BELOW_MIN
#>     - IV_LOW_ON_HOLDOUT
#>     - IV_LOSS_VS_OPTIMAL
#>   Verdict: REVIEW - advisory warnings only; accept with a reason or discard.
```

### Reading the warnings and the verdict

Every proposal is screened with the eight engine rules on train,
revalidated on hold-out with the bins frozen, and checked against a few
lab-specific rules. Codes fall into two tiers.

- **Warnings** (advisory) give a `REVIEW` verdict: the engine screening
  codes (`NOT_MONOTONIC`, `SMALL_BIN`, `IV_BELOW_MIN`, `IV_SUSPECT`, …),
  the hold-out codes (`IV_DROPS_ON_HOLDOUT`, `IV_LOW_ON_HOLDOUT`,
  `PSI_UNSTABLE`, …) and `IV_LOSS_VS_OPTIMAL`, raised when the hold-out
  IV falls more than `lab_max_iv_loss` (10% by default) below the
  optimal one. The `ds_regiao` grouping is a `REVIEW` for exactly that
  reason: two regions lose about a fifth of the hold-out IV of five
  states.
- **Blocking** codes give a `BLOCKED` verdict: an empty bin, a
  degenerate bin (no events or no non-events, unless the lab was opened
  with `laplace > 0`), a bin below `lab_min_bin_pct_hard` (0.5%) and a
  manual IV crossing `iv_max`, the leakage ceiling. The lab must not be
  the place where leakage is manufactured.

`ACCEPTABLE` means no code at all. The verdict, the codes and the reason
travel with the decision into the ledger.

## Accepting, discarding and the blocked path

`reason` is mandatory, at least five characters, and it is the audit
trail: write what a reviewer would need to read a year from now. Both
verbs return the updated lab, so the idiom is to reassign.

``` r

lab <- scr_classing_accept(lab, p_breaks, reason = "policy bands 40/55/70 used by underwriting")
#>   vl_score_01: P001 accepted (ACCEPTABLE) - 4 bins, hold-out IV 0.2740
```

The categorical proposals of the previous section were made against the
untouched lab and share the id just consumed, so the grouping is remade
(it now takes `P002`) and accepted in turn.

``` r

p_groups <- scr_classing_propose(lab, "ds_regiao",
                                 groups = list(south = c("BA", "RS"),
                                               north = c("SP", "RJ", "MG")))
p_groups$id
#> [1] "P007"
lab <- scr_classing_accept(lab, p_groups, reason = "north/south is what pricing uses")
#>   ds_regiao: P007 accepted (REVIEW) - 2 bins, hold-out IV 0.0786
```

The `ds_optin` proposal erased what little signal the variable had
(`IV_BELOW_MIN`), so it is discarded, with a reason, and the variable
keeps its optimal bins. A discarded proposal is a ledger row too.

``` r

p_missing <- scr_classing_propose(lab, "ds_optin", missing_to = 1)
lab <- scr_classing_discard(lab, p_missing, reason = "folding MISSING into SIM erases the signal")
```

A blocking rule cannot be accepted through the normal path. A break at
-5000 on `vl_score_04`, whose minimum is above 16, leaves the first bin
empty:

``` r

p_blocked <- scr_classing_propose(lab, "vl_score_04", breaks = c(-5000, 50))
p_blocked$verdict
#> [1] "BLOCKED"
p_blocked$blocking
#> [1] "EMPTY_BIN"
```

``` r

scr_classing_accept(lab, p_blocked, reason = "we need this band for the policy")
#> Error:
#> ! scr_classing_accept(): proposal P009 is BLOCKED (EMPTY_BIN). Pass override = TRUE to accept it anyway; the override is recorded.
```

The override path is `override = TRUE`. It exists because there are
legitimate reasons to carry a band the training data does not populate
(a policy floor that will bind on a future population, for example), but
it is never silent: the ledger receives an `override` row naming the
blocking codes, followed by the `accept` row. Here it is exercised on a
copy of the lab so that the session carries on without the empty bin.

``` r

lab_override <- scr_classing_accept(lab, p_blocked, reason = "deliberate policy floor at -5000",
                                    override = TRUE)
#>   vl_score_04: P009 accepted (BLOCKED) - 3 bins, hold-out IV 0.0010
scr_decisions(lab_override)[variable == "vl_score_04", .(seq, action, proposal_id, verdict, warnings, reason)]
#>      seq   action proposal_id verdict
#>    <int>   <char>      <char>  <char>
#> 1:     4 override        P009 BLOCKED
#> 2:     5   accept        P009 BLOCKED
#>                                                                            warnings
#>                                                                              <char>
#> 1:                                                                        EMPTY_BIN
#> 2: NOT_MONOTONIC;SMALL_BIN;IV_DROPS_ON_HOLDOUT;IV_LOW_ON_HOLDOUT;IV_LOSS_VS_OPTIMAL
#>                              reason
#>                              <char>
#> 1: deliberate policy floor at -5000
#> 2: deliberate policy floor at -5000
```

## Choosing the variables

[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md)
builds the final list as `(consensus shortlist + force) - drop`,
optionally intersected with `keep`. `force` is allowed for any variable
that reached binning, with two exceptions that need `override = TRUE`: a
variable failed for `IV_SUSPICIOUS` (the leakage ceiling) and a derived
`__sp` flag when `allow_derived_final = FALSE`. `reason` is one string
for every variable named, or a character vector named by variable.

`vl_score_10` is in the consensus shortlist but will not be available at
decision time; `vl_score_03` was failed by screening for `NOT_MONOTONIC`
but policy requires it on the card.

``` r

scr_funnel(res, cols = "all")[feature %in% c("vl_score_10", "vl_score_03"),
                              .(feature, exit_stage, screen_reason)]
#>        feature   exit_stage screen_reason
#>         <char>       <char>        <char>
#> 1: vl_score_10  07.approved            OK
#> 2: vl_score_03 03.screening NOT_MONOTONIC
lab <- scr_classing_choose(lab, drop = "vl_score_10", force = "vl_score_03",
                           reason = c(vl_score_10 = "not available at decision time",
                                      vl_score_03 = "policy: bureau band must be scored"))
```

## The session summary and the ledger

Printing the lab summarises the session: the variables touched with bins
and IV before and after, the verdicts, the reasons, the discards and the
final choice.

``` r

lab
#> <scr_classing> target "default" | opened 2026-09-04 13:09 by analyst | 37 variables | 9 proposals: 2 accepted, 1 discarded
#>   variable                   action      bins          IV train       IV hold-out verdict     reason
#>   vl_score_01                accepted  7->4     0.3464->0.2993     0.2877->0.2740   ACCEPTABLE  policy bands 40/55/70 used by underwriti
#>   ds_regiao                  accepted  5->2     0.0846->0.0739     0.0971->0.0786   REVIEW      north/south is what pricing uses
#>   ds_optin                   discard  P008: folding MISSING into SIM erases the sign
#>   final choice: 12 variables | consensus 12 | force: vl_score_03 | drop: vl_score_10
```

[`scr_decisions()`](https://evandeilton.github.io/scorecraft/reference/scr_decisions.md)
returns the ledger: one row per decision, append-only, with the author,
the timestamp, the instruction, the metrics before and after, the
verdict, the codes and the reason. The same function reads the ledger
from the committed result and from the scorecard fitted on it.

``` r

scr_decisions(lab)[, .(seq, variable, action, proposal_id, verdict, reason)]
#>      seq    variable  action proposal_id    verdict
#>    <int>      <char>  <char>      <char>     <char>
#> 1:     1 vl_score_01  accept        P001 ACCEPTABLE
#> 2:     2   ds_regiao  accept        P007     REVIEW
#> 3:     3    ds_optin discard        P008     REVIEW
#> 4:     4 vl_score_03   force        <NA>       <NA>
#> 5:     5 vl_score_10    drop        <NA>       <NA>
#>                                        reason
#>                                        <char>
#> 1: policy bands 40/55/70 used by underwriting
#> 2:           north/south is what pricing uses
#> 3: folding MISSING into SIM erases the signal
#> 4:         policy: bureau band must be scored
#> 5:             not available at decision time
```

## The spec round trip: a reviewer edits in a spreadsheet

Not every reviewer works in R.
[`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md)
writes the classing as a long table, one row per bin of every variable,
optimal and manual. The authoritative columns a reviewer may edit are
`lower` and `upper` for numerics, `categories` and `is_other` for
categoricals, and `reason`; everything else (counts, rates, WOE) is
context and is regenerated on read. Open ends are written as empty
cells. A `.xlsx` path writes a workbook through openxlsx; a `.csv` path
needs nothing.

``` r

spec <- scr_classing_spec(lab)
spec
#> <scr_classing_spec> 149 bins | 37 variables (2 manual)
#>     variable    type bin_id             bin_label lower upper categories
#>  vl_score_01 numeric      1      (-Inf;40.000000]    NA 40.00       <NA>
#>  vl_score_01 numeric      2 (40.000000;55.000000] 40.00 55.00       <NA>
#>  vl_score_01 numeric      3 (55.000000;70.000000] 55.00 70.00       <NA>
#>  vl_score_01 numeric      4      (70.000000;+Inf] 70.00    NA       <NA>
#>  vl_score_02 numeric      1      (-Inf;40.880000]    NA 40.88       <NA>
#>  vl_score_02 numeric      2 (40.880000;42.700000] 40.88 42.70       <NA>
#>  vl_score_02 numeric      3 (42.700000;48.660000] 42.70 48.66       <NA>
#>  vl_score_02 numeric      4 (48.660000;64.440000] 48.66 64.44       <NA>
#>  vl_score_02 numeric      5 (64.440000;70.580000] 64.44 70.58       <NA>
#>  vl_score_02 numeric      6 (70.580000;75.170000] 70.58 75.17       <NA>
#>  vl_score_02 numeric      7      (75.170000;+Inf] 75.17    NA       <NA>
#>  vl_score_03 numeric      1      (-Inf;73.310000]    NA 73.31       <NA>
#>  is_other  source                                     reason
#>     FALSE  manual policy bands 40/55/70 used by underwriting
#>     FALSE  manual policy bands 40/55/70 used by underwriting
#>     FALSE  manual policy bands 40/55/70 used by underwriting
#>     FALSE  manual policy bands 40/55/70 used by underwriting
#>     FALSE optimal                                       <NA>
#>     FALSE optimal                                       <NA>
#>     FALSE optimal                                       <NA>
#>     FALSE optimal                                       <NA>
#>     FALSE optimal                                       <NA>
#>     FALSE optimal                                       <NA>
#>     FALSE optimal                                       <NA>
#>     FALSE optimal                                       <NA>
#>   ... (+137 rows)
spec_file <- file.path(tempdir(), "classing_default.csv")
scr_classing_spec(lab, file = spec_file)
#> classing spec written to /tmp/RtmpjlpDgb/classing_default.csv
```

A reviewer opens the file, moves the first cut of `vl_score_01` from 40
to 42 and writes why in `reason`. Done in R, as it would be done in a
spreadsheet cell by cell:

``` r

sheet <- read.csv(spec_file, stringsAsFactors = FALSE)
i1 <- sheet$variable == "vl_score_01" & sheet$bin_id == 1
sheet$upper[i1]  <- 42
sheet$reason[sheet$variable == "vl_score_01"] <- "reviewer: first cut moved to 42 to match the bureau band"
write.csv(sheet, spec_file, row.names = FALSE, na = "")
```

[`scr_classing_read()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md)
validates the file before anything else happens: `bin_id` must run from
1 to k without gaps, `upper` must be finite and strictly increasing
except on the last bin, and the `lower` of every bin must equal the
`upper` of the one before it. The edit above touched only `upper`, so
the file is refused with a named reason.

``` r

scr_classing_read(spec_file)
#> Error:
#> ! scr_classing_read(): invalid spec
#>   - vl_score_01: `lower` of bin i must equal `upper` of bin i-1 (contiguity)
```

Fixing the neighbouring `lower` makes the spec contiguous again.

``` r

sheet$lower[sheet$variable == "vl_score_01" & sheet$bin_id == 2] <- 42
write.csv(sheet, spec_file, row.names = FALSE, na = "")
spec_back <- scr_classing_read(spec_file)
```

[`scr_classing_import()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md)
compares the file with the lab’s current bins and turns every variable
that differs into a proposal, with the same checks and the same
comparison as a proposal made by hand. The reviewer’s reason arrives as
`imported_reason`; nothing is accepted on the analyst’s behalf.

``` r

imported <- scr_classing_import(lab, spec_back)
names(imported)
#> [1] "vl_score_01"
imported$vl_score_01$imported_reason
#> [1] "reviewer: first cut moved to 42 to match the bureau band"
imported$vl_score_01
#> <scr_classing_proposal> P010 vl_score_01 | breaks = c(42, 55, 70) | 2026-09-04 13:09
#>                         optimal    current     manual      delta
#>   n_bins                      7          4          4         -3
#>   iv_train               0.3464     0.2993     0.2990    -0.0474
#>   iv_holdout             0.2877     0.2740     0.2631    -0.0246
#>   iv_ratio               0.8649     0.9236     0.8867     0.0218
#>   ks                     0.1981     0.2472     0.2472     0.0490
#>   psi                    0.0066     0.0032     0.0035    -0.0031
#>   min_bin_pct            0.0518     0.0786     0.0786     0.0268
#>   largest_bin_pct        0.4796     0.4307     0.3904    -0.0893
#>   n_degenerate                0          0          0          0
#>   monotonic                   1          1          1          0
#>   manual bins (train | hold-out)
#>     1  (-Inf;42.000000]                   518  18.5%   6.4%  -0.893 |     242  17.3%   6.2%  -0.943
#>     2  (42.000000;55.000000]            1,093  39.0%  10.2%  -0.375 |     539  38.5%  11.5%  -0.266
#>     3  (55.000000;70.000000]              969  34.6%  19.6%   0.384 |     520  37.1%  18.1%   0.263
#>     4  (70.000000;+Inf]                   220   7.9%  29.1%   0.904 |      99   7.1%  32.3%   1.035
#>   Verdict: ACCEPTABLE - no warning raised.
```

The comparison now has a fourth column, `current`, because the variable
already carries an accepted manual proposal. Accepting the imported one
supersedes it, and the ledger records both facts.

``` r

lab <- scr_classing_accept(lab, imported$vl_score_01, reason = imported$vl_score_01$imported_reason)
#>   vl_score_01: P010 accepted (ACCEPTABLE) - 4 bins, hold-out IV 0.2631
scr_decisions(lab)[variable == "vl_score_01", .(seq, action, proposal_id, instruction, verdict)]
#>      seq    action proposal_id            instruction    verdict
#>    <int>    <char>      <char>                 <char>     <char>
#> 1:     1    accept        P001 breaks = c(40, 55, 70) ACCEPTABLE
#> 2:     6 supersede        P001                   <NA>       <NA>
#> 3:     7    accept        P010 breaks = c(42, 55, 70) ACCEPTABLE
```

## Committing the lab: what changed

[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md)
returns a new `scr_result`. The input result is not modified. Inside the
new one, the accepted manual entries replace the optimal ones in `fit`,
the screening and hold-out rows of those variables are recomputed with
the same pipeline functions, the final shortlist is the one implied by
the choice, and the funnel, gains, SQL and summary are rebuilt.

``` r

res2 <- scr_classing_apply(lab)
res2
#> <scr_result> target "default"
#>   4,200 rows (train 2,800 / hold-out 1,400) | split out-of-time at 2026-05-01
#>   event: 14.25% on train, 14.50% on hold-out | 1.4s
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
#>   7. manual         12 #########
#> 
#> Approved: 12
#>    1. vl_score_01                                  IV  0.299  KS 0.247
#>    2. vl_score_02                                  IV  0.172  KS 0.156
#>    3. vl_score_04                                  IV  0.124  KS 0.120
#>    4. ds_faixa                                     IV  0.081  KS 0.110
#>    5. vl_tardio                                    IV  0.071  KS 0.120
#>   ... (+7) - scr_selected() for the list
#> 
#> Models (hold-out)
#>   glmnet    AUC 0.7345 [0.7028, 0.7723]  KS 0.3842
#>   xgboost   AUC 0.7375 [0.7065, 0.7762]  KS 0.3695
#> 
#> Warnings
#>   - 3 derived flag(s) outside the deliverable by policy (allow_derived_final)
#> 
#> Coarse classing: 2 manual bin(s), 1 forced in, 1 dropped, 7 decision(s) by analyst - scr_decisions()
```

[`scr_selected()`](https://evandeilton.github.io/scorecraft/reference/scr_selected.md)
on the new result returns the final list; the automatic one is still
there under `which = "consensus"`.

``` r

scr_selected(res2)
#>  [1] "vl_score_01" "vl_score_02" "vl_score_04" "ds_faixa"    "vl_tardio"  
#>  [6] "ds_regiao"   "vl_score_06" "vl_score_07" "vl_score_05" "ds_canal"   
#> [11] "vl_hist_04"  "vl_score_03"
scr_selected(res2, "consensus")
#>  [1] "vl_score_01" "vl_score_02" "vl_score_04" "ds_faixa"    "vl_tardio"  
#>  [6] "ds_regiao"   "vl_score_06" "vl_score_07" "vl_score_05" "ds_canal"   
#> [11] "vl_hist_04"  "vl_score_10"
setdiff(scr_selected(res2), scr_selected(res2, "consensus"))
#> [1] "vl_score_03"
setdiff(scr_selected(res2, "consensus"), scr_selected(res2))
#> [1] "vl_score_10"
```

The funnel gains two columns. `provenance` says what the lab did to each
variable (`auto`, `manual:rebin`, `manual:add`, `manual:drop`, or
`manual:rebin+add` / `manual:rebin+drop` when both happened) and
`manual_reason` carries the reason. A dropped variable exits at a new
stage, `08.manual_drop`; a forced one is `07.approved` even though the
consensus never selected it.

``` r

touched <- c("vl_score_01", "ds_regiao", "vl_score_03", "vl_score_10")
scr_funnel(res2, cols = "all")[feature %in% touched,
                               .(feature, exit_stage, provenance, manual_reason)]
#>        feature     exit_stage   provenance
#>         <char>         <char>       <char>
#> 1: vl_score_01    07.approved manual:rebin
#> 2:   ds_regiao    07.approved manual:rebin
#> 3: vl_score_03    07.approved   manual:add
#> 4: vl_score_10 08.manual_drop  manual:drop
#>                                               manual_reason
#>                                                      <char>
#> 1: reviewer: first cut moved to 42 to match the bureau band
#> 2:                         north/south is what pricing uses
#> 3:                       policy: bureau band must be scored
#> 4:                           not available at decision time
```

The automatic fit is frozen as `fit_auto`, so the optimal cut points
remain available next to the manual ones for as long as the result
lives.

``` r

res2$fit_auto$results$vl_score_01$cutpoints
#> [1] 33.36 38.15 44.24 48.06 63.94 72.61
res2$fit$results$vl_score_01$cutpoints
#> [1] 42 55 70
res2$fit$summary[res2$fit$summary$feature %in% c("vl_score_01", "ds_regiao"),
                 c("feature", "algorithm", "n_bins", "total_iv")]
#>        feature algorithm n_bins   total_iv
#> 1  vl_score_01    manual      4 0.29898958
#> 33   ds_regiao    manual      2 0.07392963
```

## Refitting the scorecard

[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
on the committed result fits the logistic regression on the WOE columns
of the final list, the manual ones included, and aligns the score
exactly as before. The points of a manually binned variable are
distributed over its four policy bands.

``` r

sc <- scr_scorecard(res2)
sc
#> <scr_scorecard> target "default" | 12 variables | higher_is_safer
#>   scale: 600 points at odds 50:1 (safe:event), PDO 20 | alignment regression
#>   score = 489.9126 + -27.0744 * logit | base_points = 539
#>   train    n 2,800   AUC 0.7845 [0.7681, 0.8026]  KS 0.4390  Gini 0.5690
#>   holdout  n 1,400   AUC 0.7348 [0.7007, 0.7736]  KS 0.3598  Gini 0.4697
#>   score PSI (hold-out): 0.0070 - fixed: stable | adjusted (0.0181): stable
#> 
#> Points (first rows)
#>   vl_score_01                  (-Inf;42.000000]             -0.893      28
#>   vl_score_01                  (42.000000;55.000000]        -0.375      12
#>   vl_score_01                  (55.000000;70.000000]         0.384     -12
#>   vl_score_01                  (70.000000;+Inf]              0.904     -28
#>   vl_score_02                  (-Inf;40.880000]             -0.824      23
#>   vl_score_02                  (40.880000;42.700000]        -0.770      21
#>   vl_score_02                  (42.700000;48.660000]        -0.228       6
#>   vl_score_02                  (48.660000;64.440000]        -0.093       3
#>   ... (+50 rows)
sc$points[variable == "vl_score_01", .(variable, bin, woe, points)]
#>       variable                   bin        woe points
#>         <char>                <char>      <num>  <num>
#> 1: vl_score_01      (-Inf;42.000000] -0.8929622     28
#> 2: vl_score_01 (42.000000;55.000000] -0.3753944     12
#> 3: vl_score_01 (55.000000;70.000000]  0.3836922    -12
#> 4: vl_score_01      (70.000000;+Inf]  0.9037063    -28
sc$points[variable == "ds_regiao", .(variable, bin, woe, points)]
#>     variable          bin        woe points
#>       <char>       <char>      <num>  <num>
#> 1: ds_regiao      BA%;%RS  0.4985359    -15
#> 2: ds_regiao SP%;%RJ%;%MG -0.1492097      5
```

The model card states the provenance in words: which binning algorithms
the card mixes, whether the shortlist came from the consensus or from
the lab, how many manual bins it carries and which variables were forced
in or dropped. The ledger travels into the scorecard as well.

``` r

str(sc$model_card[c("binning_algorithm", "shortlist_source", "n_manual_bins",
                    "manual_bins", "forced_in", "manual_dropped", "n_decisions")])
#> List of 7
#>  $ binning_algorithm: chr "manual, jedi"
#>  $ shortlist_source : chr "manual"
#>  $ n_manual_bins    : int 2
#>  $ manual_bins      : chr "vl_score_01, ds_regiao"
#>  $ forced_in        : chr "vl_score_03"
#>  $ manual_dropped   : chr "vl_score_10"
#>  $ n_decisions      : int 7
nrow(scr_decisions(sc))
#> [1] 7
```

## Production: R and SQL follow the manual bins

Nothing downstream needs to know that a bin was drawn by hand.
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
scores new rows in R with the frozen pre-processing and the frozen bins;
the points for `vl_score_01` fall in one of the four policy bands and
the points for `ds_regiao` in one of the two regions.

``` r

new <- head(scr_demo, 5)
new[, c("vl_score_01", "ds_regiao")]
#>   vl_score_01 ds_regiao
#> 1       71.94        SP
#> 2       39.02        RJ
#> 3       57.39        MG
#> 4       57.38        BA
#> 5       54.20        RJ
scr_apply(sc, new, what = "points")[, .(score, score_points, vl_score_01_points, ds_regiao_points)]
#>       score score_points vl_score_01_points ds_regiao_points
#>       <num>        <num>              <num>            <num>
#> 1: 544.1540          545                -28                5
#> 2: 575.3205          576                 28                5
#> 3: 519.6014          521                -12                5
#> 4: 494.8139          495                -12              -15
#> 5: 555.5494          557                 12                5
```

[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
emits the same thing for the database. The header carries the provenance
line; for the two variables touched, the lines below show the frozen
pre-processing, the WOE `CASE` on the manual cut points and groupings
with full precision, and the bin-index `CASE` on the same cuts. The tail
composes the whole points from that index.

``` r

sql <- scr_sql(sc, table = "prd.customers", dialect = "databricks")
sql_lines <- unlist(strsplit(sql, "\n", fixed = TRUE))
cat(grep("^-- Provenance", sql_lines, value = TRUE), sep = "\n")
#> -- Provenance: 2 manually binned (vl_score_01, ds_regiao), 1 forced in (vl_score_03), 1 dropped (vl_score_10) - see the decision ledger
cat(grep("WHEN (vl_score_01|ds_regiao) ", sql_lines, value = TRUE), sep = "\n")
#>     CASE WHEN vl_score_01 IS NULL OR vl_score_01 IN (-999) THEN 52.75 ELSE vl_score_01 END AS vl_score_01,
#>     WHEN vl_score_01 IS NULL THEN 0
#>     WHEN vl_score_01 <= 42 THEN -0.8929621501396132
#>     WHEN vl_score_01 > 42 AND vl_score_01 <= 55 THEN -0.37539440893887893
#>     WHEN vl_score_01 > 55 AND vl_score_01 <= 70 THEN 0.3836922056211275
#>     WHEN vl_score_01 > 70 THEN 0.9037062554415245
#>     WHEN ds_regiao IS NULL THEN 0
#>     WHEN ds_regiao IN ('BA', 'RS') THEN 0.4985359152057967
#>     WHEN ds_regiao IN ('SP', 'RJ', 'MG') THEN -0.1492097461959896
#>     WHEN vl_score_01 IS NULL THEN NULL
#>     WHEN vl_score_01 <= 42 THEN 1
#>     WHEN vl_score_01 > 42 AND vl_score_01 <= 55 THEN 2
#>     WHEN vl_score_01 > 55 AND vl_score_01 <= 70 THEN 3
#>     WHEN vl_score_01 > 70 THEN 4
#>     WHEN ds_regiao IS NULL THEN NULL
#>     WHEN ds_regiao IN ('BA', 'RS') THEN 1
#>     WHEN ds_regiao IN ('SP', 'RJ', 'MG') THEN 2
cat(tail(sql, 8), sep = "\n")
#>       CASE vl_score_06_idx WHEN 1 THEN 9 WHEN 2 THEN 4 WHEN 3 THEN -3 WHEN 4 THEN -4 WHEN 5 THEN -5 WHEN 6 THEN -10 WHEN 7 THEN -15 ELSE 0 END AS vl_score_06_points,
#>       CASE vl_score_07_idx WHEN 1 THEN 15 WHEN 2 THEN 7 WHEN 3 THEN 6 WHEN 4 THEN 1 WHEN 5 THEN -2 WHEN 6 THEN -8 ELSE 0 END AS vl_score_07_points,
#>       CASE vl_score_05_idx WHEN 1 THEN 7 WHEN 2 THEN -3 WHEN 3 THEN -9 WHEN 4 THEN -9 WHEN 5 THEN -15 ELSE 0 END AS vl_score_05_points,
#>       CASE ds_canal_idx WHEN 1 THEN 9 WHEN 2 THEN 4 WHEN 3 THEN -5 ELSE 0 END AS ds_canal_points,
#>       CASE vl_hist_04_idx WHEN 1 THEN 19 WHEN 2 THEN 9 WHEN 3 THEN -3 ELSE 0 END AS vl_hist_04_points,
#>       CASE vl_score_03_idx WHEN 1 THEN 3 WHEN 2 THEN -22 WHEN 3 THEN -19 ELSE 0 END AS vl_score_03_points
#>   FROM woe_scr
#> ) pts;
```

That the two paths agree number for number, including a value sitting
exactly on a manual cut point, is verified by the package tests, which
run the generated SQL in DuckDB and compare it with
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
on the same rows. This vignette does not need a database to run.

## Governance

The lab is designed so that a reviewer can reconstruct every manual
decision from the deliverables alone.

- **What the ledger records.** One row per decision, in order: `accept`,
  `discard`, `supersede`, `restore` (a `reset = TRUE` proposal taking a
  variable back to its optimal bins), `override`, `force`, `drop` and
  `keep`. Each row carries the author, the timestamp, the instruction as
  typed, the number of bins and the train and hold-out IV before and
  after, the PSI, the verdict, the codes and the reason. The ledger is
  append-only and travels unchanged from the lab into the result, into
  the scorecard and into the `.xlsx` workbooks written by
  [`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md),
  next to the classing spec.
- **What is blocked.** An empty bin, a degenerate bin without smoothing,
  a bin below the hard minimum share, a manual IV above the leakage
  ceiling, a category left unassigned, a proposal without a reason, a
  `force` of a variable that never reached binning. The first four block
  a proposal (`BLOCKED`); the last three are errors that never produce a
  proposal at all.
- **What needs an override.** Accepting a `BLOCKED` proposal, forcing a
  variable failed for `IV_SUSPICIOUS`, and forcing a derived `__sp` flag
  under `allow_derived_final = FALSE`. An override is not a way round
  the rule; it is a documented exception, with its own ledger row, that
  the model card and the SQL header will point to.

Everything a manual decision touches remains reproducible: the optimal
artefacts are frozen alongside, the manual bins are recomputed on the
training rows with the engine’s own WOE formula, and the scorecard, the
R scoring and the SQL read them through the same contract as any optimal
bin.
