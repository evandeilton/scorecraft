# Stages 4 and 5: points scorecard, aligned to the declared scale

Fits a logistic regression on the WOE columns of the shortlist, checks
the sign of the coefficients, aligns the logit to the declared scale
with
[`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md)
(always) and distributes the points per bin. Measures the score on train
and hold-out with a bootstrap CI (always), builds the gains with bands
**frozen on train**, the score PSI and the CSI per variable (fixed and
n-adjusted thresholds), the calibration and the rank-order diagnostics.
Optionally fits a tree challenger on the same WOE columns, aligned to
the same scale, with an explicit `supports_scorecard = FALSE`: it
compares, it never produces points or reason codes.

## Usage

``` r
scr_scorecard(
  x,
  features = NULL,
  base_score = NULL,
  base_odds = NULL,
  pdo = NULL,
  direction = NULL,
  align_method = NULL,
  challenger = NULL,
  points_style = NULL,
  n_boot = NULL,
  seed = NULL
)
```

## Arguments

- x:

  An object from
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md).

- features:

  Variables of the scorecard. Defaults to
  [`scr_selected()`](https://evandeilton.github.io/scorecraft/reference/scr_selected.md).

- base_score, base_odds, pdo, direction:

  The scale; `NULL` uses the configuration of `x`. See
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md)
  and
  [`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md).

- align_method:

  `"regression"` or `"direct"`; `NULL` uses the configuration.

- challenger:

  `NULL`, `"xgboost"` or `"lightgbm"`; `NULL` uses the configuration.

- points_style:

  `"base_plus_deviation"` or `"distributed"`; `NULL` uses the
  configuration.

- n_boot:

  CI resamples; `NULL` uses the configuration.

- seed:

  Seed; `NULL` uses the configuration.

## Value

An `scr_scorecard` object. Main components: `features`, `coef`,
`sign_check`, `alignment` (an `scr_align` object), `points`,
`base_points`, `samples` (train and hold-out: `link`, `prob`, `score`,
`score_points`, `y`, `date`), `metrics`, `gains`, `stability` (`score`
and `variables`), `calibration`, `rank_order`, `challenger`,
`model_card` and `sql`. Also `scale` (`base_score`, `base_odds`, `pdo`,
`factor`, `offset`, `direction`, `odds_orientation`), `breaks` (the
score bands frozen on train), `monitoring_plan` (see
[`scr_monitoring_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_monitoring_plan.md)),
`holdout_bins`, `fit` and `ledger` (the frozen binning and
pre-processing that
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
and
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
reproduce) and, after a lab commit, `decisions` and `provenance`.

## Sign check

The engine's WOE is event-oriented, so every glm coefficient must be
positive. A variable with a non-positive coefficient (or above
`max_abs_coef` in absolute value) is explaining what another already
explained, with the sign reversed; it is removed and the model refitted,
one at a time, the most negative first, and each removal is recorded in
`sign_check`. The last remaining variable is never removed: it is kept
and flagged `NON_POSITIVE_COEF_KEPT_LAST`. The final shortlist of the
scorecard (`features`) is what
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
covers.

## Points per bin

With `score = a + b * logit` and `logit = alpha + sum(beta_j * woe_ij)`:
\$\$\mathrm{points}\_{ij} = b\\\beta_j\\\mathrm{woe}\_{ij},\qquad
\mathrm{base} = a + b\\\alpha.\$\$ `points_style = "distributed"`
spreads `base / k` over each characteristic (Siddiqi, 2006, chapter 6),
leaving `base_points = 0`. The exact points stay in `points_raw`;
`points` is the rounded version when `points_round = TRUE`. The exact
score (`score`) and the whole-points score (`score_points`) are both
returned by
[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
and both emitted by
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md).

## See also

Other stages:
[`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md),
[`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md),
[`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md),
[`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md),
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md),
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md),
[`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
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
head(sc$points[, c("variable", "bin", "woe", "points")])
#>       variable                   bin         woe points
#>         <char>                <char>       <num>  <num>
#> 1: vl_score_01      (-Inf;33.360000] -2.06253559     61
#> 2: vl_score_01 (33.360000;38.150000] -0.73104946     22
#> 3: vl_score_01 (38.150000;44.240000] -0.65810792     20
#> 4: vl_score_01 (44.240000;48.060000] -0.52261206     16
#> 5: vl_score_01 (48.060000;63.940000]  0.03978629     -1
#> 6: vl_score_01 (63.940000;72.610000]  0.70394095    -21
sc$metrics
#> Index: <sample>
#>     sample       direction     n events       auc    auc_lo    auc_hi        ks
#>     <char>          <char> <int>  <int>     <num>     <num>     <num>     <num>
#> 1:   train higher_is_safer  2800    399 0.7856428 0.7662170 0.8069608 0.4411466
#> 2: holdout higher_is_safer  1400    203 0.7394060 0.7066284 0.7770357 0.3889033
#>        ks_lo     ks_hi      gini   gini_lo   gini_hi n_boot level
#>        <num>     <num>     <num>     <num>     <num>  <int> <num>
#> 1: 0.4145334 0.4875854 0.5712856 0.5324341 0.6139216     20  0.95
#> 2: 0.3381932 0.4654704 0.4788120 0.4132569 0.5540713     20  0.95
sc$alignment
#> <scr_align> 600 points at odds 50:1 (safe:event), PDO 20 | higher_is_safer
#>   factor = 28.853901 | offset = 487.122876
#>   calibration: ln(odds) = 0.141187 + -0.912143 * raw  (adj. R2 = 0.9668, 10 bands)
#>   score = 491.196658 + -26.318891 * raw
```
