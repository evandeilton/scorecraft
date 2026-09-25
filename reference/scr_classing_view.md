# Inspect the current bins of a variable in the lab

Prints the current bins (optimal, or the accepted manual ones) with
train and hold-out side by side and a text bar chart of the event rate,
or, without `variable`, one line per variable of the lab.

## Usage

``` r
scr_classing_view(lab, variable = NULL)
```

## Arguments

- lab:

  An object from
  [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md).

- variable:

  A variable name, or `NULL` for the overview.

## Value

Invisibly, the bins table (`variable` given) or the overview table.

## See also

[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
for a complete session, from lab to scorecard.

Other classing:
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md),
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
[`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md),
[`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md),
[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md),
[`scr_decisions()`](https://evandeilton.github.io/scorecraft/reference/scr_decisions.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 40, n_boot = 10)
d <- scr_demo[, c("default", "ref_date", "ds_region", "ds_band", "vl_score_01",
                  "vl_score_02", "vl_score_05", "vl_score_10", "vl_hist_01")]
res <- scr_select(d, "default", config = cfg, date_col = "ref_date")
lab <- scr_coarse_classing(res)
scr_classing_view(lab)
#> <scr_classing> target "default" | 8 variables
#>   variable                     source    bins  IV train   IV hold     PSI verdict     shortlist
#>   ds_region                    optimal      5    0.0846    0.0971  0.0064 ACCEPTABLE  yes
#>   ds_band                      optimal      4    0.0805    0.0780  0.0013 ACCEPTABLE  yes
#>   vl_score_01                  optimal      7    0.3464    0.2877  0.0066 ACCEPTABLE  yes
#>   vl_score_02                  optimal      7    0.1721    0.1234  0.0053 ACCEPTABLE  yes
#>   vl_score_05                  optimal      5    0.0363    0.0289  0.0024 ACCEPTABLE  yes
#>   vl_score_10                  optimal      3    0.0282    0.0432  0.0024 ACCEPTABLE  yes
#>   vl_hist_01                   optimal      3    0.0029    0.0158  0.0012 REVIEW      -
#>   vl_hist_01__sp               optimal      2    0.0315    0.0069  0.0017 REVIEW      -
scr_classing_view(lab, "ds_region")
#> <scr_classing> ds_region (categorical) | current: optimal (jedi) | 5 bins | train IV 0.0846, hold-out IV 0.0971 (ratio 1.14)
#>   monotone: yes | min bin 7.9% | PSI 0.0064 (stable) | KS 0.114 | degenerate bins: 0 | verdict: ACCEPTABLE
#>    id  bin                                  n      %  events   rate      WOE      IV |  n.hold      %    rate WOE.hold
#>     1  CENTRE                             539  19.2%      57  10.6%   -0.341   0.020 |     301  21.5%   13.0%   -0.130
#>     2  EAST                             1,139  40.7%     144  12.6%   -0.139   0.008 |     551  39.4%   13.8%   -0.058
#>     3  WEST                               582  20.8%      82  14.1%   -0.014   0.000 |     269  19.2%   10.0%   -0.419
#>     4  NORTH                              318  11.4%      66  20.8%    0.453   0.027 |     178  12.7%   23.6%    0.599
#>     5  SOUTH                              222   7.9%      50  22.5%    0.557   0.030 |     101   7.2%   18.8%    0.312
#>   event rate by bin (train | hold-out)
#>     1  ########            10.6% | ##########          13.0%
#>     2  ##########          12.6% | ###########         13.8%
#>     3  ###########         14.1% | ########            10.0%
#>     4  ################    20.8% | ##################  23.6%
#>     5  #################   22.5% | ##############      18.8%
```
