# Scale alignment across targets, engines and conventions

``` r

library(scorecraft)
library(data.table)
```

## 1. Why “700 points” means nothing on its own

A points score is a linear function of a log-odds. Which log-odds, in
which orientation, and through which map, is what gives the number its
meaning. Two scorecards can both print “700” for a customer and disagree
completely about that customer’s risk unless both raw scores were taken
to the **same scale** by the **same procedure**. That is the whole
subject of this vignette.

### The scale is one statement

`base_score`, `base_odds` and `pdo` are not three independent knobs;
they are a single sentence: *at `base_score` points the odds are
`base_odds`, and every `pdo` points they double*. From that sentence
follow two constants,

``` math
\mathrm{factor} = \frac{\mathrm{pdo}}{\ln 2}, \qquad
\mathrm{offset} = \mathrm{base\_score} - \mathrm{factor} \cdot \ln(\mathrm{base\_odds}),
```

and the map from log-odds to points,
$`\mathrm{score} = \mathrm{offset} + \mathrm{factor} \cdot \ln(\mathrm{odds})`$.
The textbook example is 600 points at odds 50:1 with a PDO of 20
(Siddiqi, 2006); it is an example, not a standard published by anyone.

``` r

factor <- 20 / log(2)
offset <- 600 - factor * log(50)
c(factor = factor, offset = offset)
#>   factor   offset 
#>  28.8539 487.1229
```

### The orientation trap

The word *odds* changes meaning between the two literatures. Under
`objective = "risk"` the event is the bad case, more points are safer,
and `base_odds` is **non-event:event** (`safe:event`). Under
`objective = "propensity"` the event is the good case, more points mean
a higher chance of the event, and `base_odds` is **event:non-event**
(`event:safe`). Feeding the same number `50` to both conventions is the
most common sign error in scorecard work, and it is silent: nothing
fails, the points simply mean something else.

[`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md)
records `odds_orientation` on the object precisely so that this can
never be implicit. Let us see the trap on a simulated, well-calibrated
event logit.

``` r

set.seed(2026)
n   <- 4000
raw <- stats::rnorm(n, mean = stats::qlogis(0.12), sd = 1.2)   # event logit
y   <- stats::rbinom(n, 1, stats::plogis(raw))                 # calibrated outcome
```

With `method = "direct"` the model is trusted as calibrated: the
log-odds *is* the raw logit, in the orientation the direction implies
(`S = -1` under `higher_is_safer`, `+1` under `higher_is_riskier`,
`I = 0`).

``` r

al_risk <- scr_align(raw, y, base_score = 600, base_odds = 50, pdo = 20,
                     direction = "higher_is_safer", method = "direct")
al_risk
#> <scr_align> 600 points at odds 50:1 (safe:event), PDO 20 | higher_is_safer
#>   factor = 28.853901 | offset = 487.122876
#>   calibration: direct (model assumed calibrated; I = 0.000, S = -1)
#>   score = 487.122876 + -28.853901 * raw
```

The same `50`, passed under the propensity convention, states that at
600 points the event is fifty times *more* likely than not. The
equivalent statement in that orientation is `base_odds = 1/50`.

``` r

al_prop_wrong <- scr_align(raw, y, base_score = 600, base_odds = 50, pdo = 20,
                           direction = "higher_is_riskier", method = "direct")
al_prop_right <- scr_align(raw, y, base_score = 600, base_odds = 1 / 50, pdo = 20,
                           direction = "higher_is_riskier", method = "direct")

# what does "600 points" mean under each object? Invert score = a + b * raw
prob_at <- function(al, score) predict(al, (score - al$a) / al$b, type = "prob")
data.table(
  object      = c("risk 50 (safe:event)", "propensity 50 (event:safe)", "propensity 1/50 (event:safe)"),
  orientation = c(al_risk$odds_orientation, al_prop_wrong$odds_orientation, al_prop_right$odds_orientation),
  p_event_at_600 = round(c(prob_at(al_risk, 600), prob_at(al_prop_wrong, 600), prob_at(al_prop_right, 600)), 4)
)
#>                          object orientation p_event_at_600
#>                          <char>      <char>          <num>
#> 1:         risk 50 (safe:event)  safe:event         0.0196
#> 2:   propensity 50 (event:safe)  event:safe         0.9804
#> 3: propensity 1/50 (event:safe)  event:safe         0.0196
```

Under the correct pair of statements the two scales are mirror images of
each other around 600, and both return the same event probability for
the same customer; under the wrong pair, “600 points” is a 2% customer
on one card and a 98% customer on the other.

``` r

head(data.table(
  raw   = round(raw, 3),
  p_true = round(stats::plogis(raw), 4),
  score_risk = round(predict(al_risk, raw), 1),
  score_prop = round(predict(al_prop_right, raw), 1),
  p_risk = round(predict(al_risk, raw, type = "prob"), 4),
  p_prop = round(predict(al_prop_right, raw, type = "prob"), 4)
), 5)
#>       raw p_true score_risk score_prop p_risk p_prop
#>     <num>  <num>      <num>      <num>  <num>  <num>
#> 1: -1.368 0.2030      526.6      673.4 0.2030 0.2030
#> 2: -3.288 0.0360      582.0      618.0 0.0360 0.0360
#> 3: -1.825 0.1388      539.8      660.2 0.1388 0.1388
#> 4: -2.094 0.1097      547.5      652.5 0.1097 0.1097
#> 5: -2.792 0.0577      567.7      632.3 0.0577 0.0577
all.equal(predict(al_risk, raw) + predict(al_prop_right, raw), rep(1200, n))
#> [1] TRUE
```

Now the default, `method = "regression"`. On a calibrated logit it
should recover an intercept near 0 and a slope near `-1` (the sign of
the direction), and it does. The slope sits a little below 1 in
magnitude because the regression runs on band means: averaging the logit
inside a band is not the same as taking the logit of the band’s event
rate, and the difference attenuates the slope slightly. That is a
property of any banded calibration, not a defect of this one.

``` r

al_reg <- scr_align(raw, y, base_score = 600, base_odds = 50, pdo = 20,
                    direction = "higher_is_safer")
al_reg
#> <scr_align> 600 points at odds 50:1 (safe:event), PDO 20 | higher_is_safer
#>   factor = 28.853901 | offset = 487.122876
#>   calibration: ln(odds) = 0.082592 + -0.915197 * raw  (adj. R2 = 0.9787, 10 bands)
#>   score = 489.505966 + -26.406998 * raw
```

## 2. The two-step regression alignment

`method = "regression"` does not trust the raw score to be a log-odds.
It measures how the raw score maps to the *empirical* log-odds and
composes that map with the PDO map:

1.  band the raw score by quantiles on the reference data (`n_bands`,
    default 10);
2.  in every band, compute the empirical log-odds with Laplace
    smoothing, in the orientation the direction implies;
3.  regress the band log-odds on the band mean of the raw score,
    weighted by band size:
    $`\ln(\mathrm{odds}) = I + S \cdot \mathrm{raw}`$;
4.  compose with the scale:
    $`\mathrm{score} = \mathrm{offset} + \mathrm{factor}\,(I + S \cdot \mathrm{raw}) = a + b \cdot \mathrm{raw}`$.

The bands are kept on the object, so the regression can be audited row
by row.

``` r

al_reg$calibration$bands
#>               band   n events    raw_mean    ln_odds ln_odds_fit
#> 1     [-Inf,-3.53] 400     10 -4.07429239  3.6160527 3.811370945
#> 2    (-3.53,-3.01] 400     14 -3.24729758  3.2829832 3.054507943
#> 3    (-3.01,-2.63] 400     28 -2.81324430  2.5703330 2.657263770
#> 4    (-2.63,-2.31] 400     37 -2.47321872  2.2714384 2.346073457
#> 5    (-2.31,-2.01] 400     48 -2.16009650  1.9834868 2.059505001
#> 6    (-2.01,-1.71] 400     53 -1.85637134  1.8710830 1.781536714
#> 7    (-1.71,-1.39] 400     61 -1.55681460  1.7084368 1.507383339
#> 8   (-1.39,-0.995] 400     86 -1.20975072  1.2908397 1.189751591
#> 9  (-0.995,-0.429] 400    125 -0.72959054  0.7862819 0.750310530
#> 10   (-0.429, Inf] 400    222  0.08708293 -0.2203385 0.002893594
c(intercept = al_reg$calibration$intercept, slope = al_reg$calibration$slope,
  adj_r2 = al_reg$calibration$r2)
#>   intercept       slope      adj_r2 
#>  0.08259161 -0.91519679  0.97874564
```

How to read the three numbers:

- **intercept** $`I`$: the log-odds at `raw = 0`, in the scale’s
  orientation. A value away from 0 means the raw score is shifted
  relative to the population it is being aligned on (a prior shift, a
  reweighted sample, a model fitted on a different base rate).
- **slope** $`S`$: how many log-odds units the empirical odds move per
  unit of raw score. Its **sign** must agree with the direction (`-1`
  expected under `higher_is_safer`, `+1` under `higher_is_riskier`);
  [`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md)
  warns when it does not. Its **magnitude** measures over- or
  under-confidence: $`|S| < 1`$ means the raw logit spreads more than
  the data support, $`|S| > 1`$ that it is too timid.
- **adj. R2**: how well a straight line explains the band log-odds. A
  low value means the raw score is not linear in log-odds, and a linear
  alignment will be systematically wrong in the tails; that is a signal
  to inspect the bands, not to trust the map.

Why not always use `"direct"`? Because raw scores are rarely calibrated
on the population they are deployed to. Shrink and shift the simulated
logit and compare the two methods:

``` r

raw_bad <- 0.6 * raw - 1            # over-timid and shifted
al_bad_direct <- scr_align(raw_bad, y, method = "direct")
al_bad_reg    <- scr_align(raw_bad, y)
al_bad_reg$calibration[c("intercept", "slope", "r2")]
#> $intercept
#> [1] -1.442736
#> 
#> $slope
#> [1] -1.525328
#> 
#> $r2
#> [1] 0.9787456
data.table(
  method = c("direct", "regression"),
  mean_predicted = c(mean(predict(al_bad_direct, raw_bad, type = "prob")),
                     mean(predict(al_bad_reg,    raw_bad, type = "prob"))),
  observed = mean(y)
)
#>        method mean_predicted observed
#>        <char>          <num>    <num>
#> 1:     direct      0.1174596    0.171
#> 2: regression      0.1714736    0.171
```

The true map is
$`\ln(\mathrm{odds}_{\mathrm{safe:event}}) = -(1 + \mathrm{raw\_bad}) / 0.6`$,
so intercept and slope should both be near $`-1.67`$. The regression
lands at about $`-1.4`$ and $`-1.5`$, attenuated by the banding as above
but in the right place, and its mean predicted probability matches the
observed event rate; the direct map reports whatever the raw score
claims, here a third too low. This is why
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
always aligns and defaults to `"regression"`.

## 3. Two targets, two conventions, one scale

The bundled `scr_demo` table carries two binary targets: `default`, a
risk target, and `churn`, which we shall treat as a propensity target
(the campaign wants to reach customers who *will* churn). Each is
selected with the other target dropped, so that neither becomes a
candidate for the other.

``` r

cfg_risk <- scr_config(objective = "risk", verbose = FALSE, nthread = 1, use_ranger = FALSE,
                       use_lightgbm = FALSE, xgb_rounds = 60, n_boot = 20)
cfg_prop <- scr_config(objective = "propensity", verbose = FALSE, nthread = 1, use_ranger = FALSE,
                       use_lightgbm = FALSE, xgb_rounds = 60, n_boot = 20)

res_risk <- scr_select(scr_demo, "default", config = cfg_risk, drop = c("id", "churn"),
                       date_col = "ref_date")
res_prop <- scr_select(scr_demo, "churn", config = cfg_prop, drop = c("id", "default"),
                       date_col = "ref_date")

sc_risk <- scr_scorecard(res_risk)
sc_prop <- scr_scorecard(res_prop)
```

Both scorecards declare the same scale, 600/50/20, but the two alignment
objects differ in direction and in odds orientation, and therefore in
the sign of the map from logit to points.

``` r

sc_risk$alignment
#> <scr_align> 600 points at odds 50:1 (safe:event), PDO 20 | higher_is_safer
#>   factor = 28.853901 | offset = 487.122876
#>   calibration: ln(odds) = 0.141187 + -0.912143 * raw  (adj. R2 = 0.9668, 10 bands)
#>   score = 491.196658 + -26.318891 * raw
sc_prop$alignment
#> <scr_align> 600 points at odds 50:1 (event:safe), PDO 20 | higher_is_riskier
#>   factor = 28.853901 | offset = 487.122876
#>   calibration: ln(odds) = 0.004026 + 1.008929 * raw  (adj. R2 = 0.9904, 10 bands)
#>   score = 487.239034 + 29.111532 * raw
c(risk = sc_risk$odds_orientation, propensity = sc_prop$odds_orientation)
#>         risk   propensity 
#> "safe:event" "event:safe"
```

[`scr_score_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_score_metrics.md)
reports the AUC **in the direction of the scale**: above 0.5 whenever
the score ranks correctly in its own convention. The `direction` column
is carried on the table so the reader knows which way the score was
read.

``` r

scr_score_metrics(sc_risk)[, .(sample, direction, auc, auc_lo, auc_hi, ks)]
#>     sample       direction       auc    auc_lo    auc_hi        ks
#>     <char>          <char>     <num>     <num>     <num>     <num>
#> 1:   train higher_is_safer 0.7856428 0.7662170 0.8069608 0.4411466
#> 2: holdout higher_is_safer 0.7394060 0.7066284 0.7770357 0.3889033
scr_score_metrics(sc_prop)[, .(sample, direction, auc, auc_lo, auc_hi, ks)]
#>     sample         direction       auc    auc_lo    auc_hi        ks
#>     <char>            <char>     <num>     <num>     <num>     <num>
#> 1:   train higher_is_riskier 0.7404593 0.7218347 0.7547629 0.3715330
#> 2: holdout higher_is_riskier 0.7285271 0.7107000 0.7557903 0.3276755
```

Compare the mean score by outcome on hold-out. Under risk, events score
lower; under propensity, events score higher. The same points scale,
read the other way round.

``` r

rbind(
  sc_risk$samples$holdout[, .(scorecard = "default (risk)", n = .N, mean_score = round(mean(score), 1)), by = y],
  sc_prop$samples$holdout[, .(scorecard = "churn (propensity)", n = .N, mean_score = round(mean(score), 1)), by = y]
)[order(scorecard, y)]
#>        y          scorecard     n mean_score
#>    <int>             <char> <int>      <num>
#> 1:     0 churn (propensity)   976      449.0
#> 2:     1 churn (propensity)   424      472.3
#> 3:     0     default (risk)  1197      554.9
#> 4:     1     default (risk)   203      529.6
```

Reading a risk score as if it were a propensity score is the same error
in reverse:
[`scr_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_metrics.md)
with the wrong `higher_is_event` returns one minus the AUC.

``` r

s <- sc_risk$samples$holdout
c(read_as_safer  = scr_metrics(s$score, s$y, higher_is_event = FALSE, ci = FALSE)$auc,
  read_as_riskier = scr_metrics(s$score, s$y, higher_is_event = TRUE,  ci = FALSE)$auc)
#>   read_as_safer read_as_riskier 
#>        0.739406        0.260594
```

## 4. A tree challenger on the same scale

A gradient-boosted model can be fitted on the same WOE columns as the
scorecard and aligned to the same scale by the same regression. That
makes its output comparable point for point with the champion; it does
**not** make it a scorecard. The object says so explicitly: no points,
no reason codes, `supports_scorecard = FALSE`.

``` r

sc_x <- scr_scorecard(res_risk, challenger = "xgboost")
```

``` r

sc_x$challenger$supports_scorecard
#> [1] FALSE
sc_x$challenger$points
#> [1] "NOT_APPLICABLE_ENGINE"
sc_x$challenger$alignment
#> <scr_align> 600 points at odds 50:1 (safe:event), PDO 20 | higher_is_safer
#>   factor = 28.853901 | offset = 487.122876
#>   calibration: ln(odds) = -1.398883 + -1.883869 * raw  (adj. R2 = 0.9710, 10 bands)
#>   score = 446.759642 + -54.356970 * raw
sc_x$challenger$metrics[, .(sample, direction, auc, auc_lo, auc_hi, ks)]
#>     sample       direction       auc    auc_lo    auc_hi        ks
#>     <char>          <char>     <num>     <num>     <num>     <num>
#> 1: holdout higher_is_safer 0.7340725 0.7021223 0.7720179 0.3574453
scr_score_metrics(sc_x)[sample == "holdout", .(sample, direction, auc, auc_lo, auc_hi, ks)]
#>     sample       direction      auc    auc_lo    auc_hi        ks
#>     <char>          <char>    <num>     <num>     <num>     <num>
#> 1: holdout higher_is_safer 0.739406 0.7066284 0.7770357 0.3889033
```

The challenger’s alignment has its own intercept and slope: two engines,
two raw scores, one declared scale. Here the slope is well above 1 in
magnitude, which says the boosted logit is compressed (a few dozen
rounds at a low learning rate leave it under-confident) and the
alignment stretches it back to the empirical odds; the scorecard logit,
by contrast, needed a slope close to 1. Its AUC interval overlaps the
scorecard’s, which is the usual finding on a WOE feature set.

### The swap set

Aggregate AUCs hide where two models disagree. The swap-set table holds
the **approval rate** fixed and asks which customers one model would
approve and the other would not:

``` r

sc_x$challenger$swapset
#>    approval_rate n_swap_in n_swap_out event_rate_swap_in event_rate_swap_out
#>            <num>     <int>      <int>              <num>               <num>
#> 1:           0.5        96         96          0.1145833           0.1250000
#> 2:           0.7        75         75          0.1866667           0.1866667
#> 3:           0.9        36         36          0.4166667           0.3611111
#>    event_rate_champion event_rate_challenger
#>                  <num>                 <num>
#> 1:          0.06000000            0.05857143
#> 2:          0.08367347            0.08367347
#> 3:          0.12142857            0.12301587
```

How to read one row, say `approval_rate = 0.5`:

- both models approve the safest half of hold-out by their own score;
- `n_swap_in` customers are approved by the challenger but not by the
  champion; `n_swap_out` the reverse. At a fixed rate the two counts are
  equal;
- `event_rate_swap_in` versus `event_rate_swap_out` is the decision: the
  challenger is worth its complexity only if the customers it brings in
  are safer than the ones it sends out, by a margin that survives the
  sample size of the swap;
- `event_rate_champion` and `event_rate_challenger` are the event rates
  of the two approved books.

Because both scores sit on the same scale, the swap set can also be read
in points: a customer swapped in at the 70% rate crossed the
challenger’s cut-off and not the champion’s, and the two cut-offs are
directly comparable numbers.

## 5. The portfolio view

With several targets in flight,
[`scr_compare()`](https://evandeilton.github.io/scorecraft/reference/scr_compare.md)
gives one row per target (funnel, best hold-out model with its interval,
warning signs) and
[`scr_core()`](https://evandeilton.github.io/scorecraft/reference/scr_core.md)
lists the variables that survived on more than one target.

``` r

runs <- list(default = res_risk, churn = res_prop)
scr_compare(runs)[, .(target, rows, event_rate, candidates, approved, best_model, auc, auc_lo, auc_hi, ks, relaxation)]
#>     target  rows event_rate candidates approved best_model    auc auc_lo auc_hi
#>     <char> <int>      <num>      <int>    <int>     <char>  <num>  <num>  <num>
#> 1: default  4200     0.1425         37       12    xgboost 0.7375 0.7065 0.7762
#> 2:   churn  4200     0.2846         37        9     glmnet 0.7262 0.7086 0.7544
#>        ks             relaxation
#>     <num>                 <char>
#> 1: 0.3695                   none
#> 2: 0.3288 min_votes reduced to 1
scr_core(runs, min_targets = 2)
#>        feature n_targets mean_rank        targets
#>         <char>     <int>     <num>         <char>
#> 1: vl_score_02         2       2.0 churn, default
#> 2: vl_score_04         2       3.5 churn, default
#> 3:   ds_regiao         2       6.0 churn, default
#> 4: vl_score_06         2       6.0 churn, default
#> 5: vl_score_05         2       6.0 churn, default
#> 6: vl_score_07         2       7.5 churn, default
#> 7:  vl_hist_04         2      10.0 churn, default
```

A variable that is approved on both targets, with a good mean consensus
rank, is the strongest argument a model committee can hear in its
favour: it is not an artefact of one target definition. The `relaxation`
column records whether the consensus had to loosen its vote threshold to
reach the configured minimum number of variables, which is worth knowing
before the two shortlists are compared. Note that
[`scr_compare()`](https://evandeilton.github.io/scorecraft/reference/scr_compare.md)
reports the AUC of the **selection-stage** consensus models, not of the
final scorecards; the scorecards’ own metrics live in
[`scr_score_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_score_metrics.md),
and since both cards are on the same scale, their score distributions
can be laid side by side as well.

``` r

rbind(
  data.table(scorecard = "default", sc_risk$samples$holdout[, .(min = min(score), median = stats::median(score), max = max(score))]),
  data.table(scorecard = "churn",   sc_prop$samples$holdout[, .(min = min(score), median = stats::median(score), max = max(score))])
)
#>    scorecard      min   median      max
#>       <char>    <num>    <num>    <num>
#> 1:   default 452.9460 550.6549 652.3243
#> 2:     churn 360.4282 455.5152 549.2294
```

## 6. Rescaling an existing scorecard

A committee may ask for a different convention, say 700 points at 30:1
with a PDO of 25. Refitting is unnecessary: the logit and the
calibration regression are unchanged, only the PDO map moves.

``` r

sc_700 <- scr_scorecard(res_risk, base_score = 700, base_odds = 30, pdo = 25)
```

``` r

sc_700$alignment
#> <scr_align> 700 points at odds 30:1 (safe:event), PDO 25 | higher_is_safer
#>   factor = 36.067376 | offset = 577.327735
#>   calibration: ln(odds) = 0.141187 + -0.912143 * raw  (adj. R2 = 0.9668, 10 bands)
#>   score = 582.419962 + -32.898614 * raw
# the calibration is the same; only factor and offset change
c(intercept_600 = sc_risk$alignment$calibration$intercept, intercept_700 = sc_700$alignment$calibration$intercept,
  slope_600 = sc_risk$alignment$calibration$slope, slope_700 = sc_700$alignment$calibration$slope)
#> intercept_600 intercept_700     slope_600     slope_700 
#>     0.1411865     0.1411865    -0.9121433    -0.9121433
```

Ranking metrics are invariant to a monotone transformation, so AUC, KS
and Gini are identical to the last digit, while every point value moves.

``` r

rbind(scr_score_metrics(sc_risk)[, .(scale = "600/50/20", sample, auc, ks, gini)],
      scr_score_metrics(sc_700)[, .(scale = "700/30/25", sample, auc, ks, gini)])
#>        scale  sample       auc        ks      gini
#>       <char>  <char>     <num>     <num>     <num>
#> 1: 600/50/20   train 0.7856428 0.4411466 0.5712856
#> 2: 600/50/20 holdout 0.7394060 0.3889033 0.4788120
#> 3: 700/30/25   train 0.7856428 0.4411466 0.5712856
#> 4: 700/30/25 holdout 0.7394060 0.3889033 0.4788120
merge(sc_risk$points[, .(variable, bin, points_600 = points)],
      sc_700$points[, .(variable, bin, points_700 = points)],
      by = c("variable", "bin"))[1:6]
#> Key: <variable, bin>
#>    variable    bin points_600 points_700
#>      <char> <char>      <num>      <num>
#> 1: ds_canal    APP         -5         -6
#> 2: ds_canal   LOJA          9         11
#> 3: ds_canal    WEB          4          5
#> 4: ds_faixa      A        -11        -14
#> 5: ds_faixa      B          0         -1
#> 6: ds_faixa      C          2          3
```

The two scores are the same log-odds seen through two maps, so one can
be recovered from the other exactly:

``` r

a600 <- sc_risk$alignment; a700 <- sc_700$alignment
ln_odds <- (sc_risk$samples$holdout$score - a600$offset) / a600$factor
all.equal(a700$offset + a700$factor * ln_odds, sc_700$samples$holdout$score)
#> [1] TRUE
```

That identity is what “comparable” means: two scorecards are on the same
scale when the same log-odds gives the same points, and a scorecard is
rescaled, not remodelled, when only `factor` and `offset` change.

## 7. A checklist for the model committee

Everything the committee needs to reproduce, compare and later monitor
the scale is on the model card. Record it verbatim.

``` r

mc <- sc_risk$model_card
keys <- c("target", "objective", "direction", "odds_orientation",
          "base_score", "base_odds", "pdo", "factor", "offset",
          "align_method", "align_intercept", "align_slope", "align_r2",
          "n_train", "event_rate_train", "split_method", "split_cutoff",
          "challenger", "challenger_supports_scorecard", "auc_holdout", "ks_holdout")
data.table(field = keys, value = vapply(mc[keys], function(v) format(v, digits = 6), character(1)))
#>                             field           value
#>                            <char>          <char>
#>  1:                        target         default
#>  2:                     objective            risk
#>  3:                     direction higher_is_safer
#>  4:              odds_orientation      safe:event
#>  5:                    base_score             600
#>  6:                     base_odds              50
#>  7:                           pdo              20
#>  8:                        factor         28.8539
#>  9:                        offset         487.123
#> 10:                  align_method      regression
#> 11:               align_intercept        0.141187
#> 12:                   align_slope       -0.912143
#> 13:                      align_r2        0.966774
#> 14:                       n_train            2800
#> 15:              event_rate_train          0.1425
#> 16:                  split_method     out-of-time
#> 17:                  split_cutoff      2026-05-01
#> 18:                    challenger            none
#> 19: challenger_supports_scorecard              NA
#> 20:                   auc_holdout        0.739406
#> 21:                    ks_holdout        0.388903
#>                             field           value
#>                            <char>          <char>
```

What to write down, and why:

1.  **The scale as one sentence**: `base_score`, `base_odds`, `pdo`, and
    the derived `factor` and `offset`. Anyone with these five numbers
    can turn a log-odds into points and back.
2.  **The orientation**: `objective`, `direction` and
    `odds_orientation`. Without them `base_odds = 50` is ambiguous; with
    them it is not.
3.  **The alignment method and its coefficients**: `align_method`,
    `align_intercept`, `align_slope`, `align_r2`, and the number of
    bands. A `"regression"` alignment on one population is not the same
    map as a `"regression"` alignment on another; the coefficients are
    what make the two comparable, or show that they are not.
4.  **The population the alignment was fitted on**: `n_train`,
    `event_rate_train`, the split method and cut-off. An alignment
    absorbs the base rate of that population; if the deployment
    population differs, the intercept will drift first.
5.  **The challenger’s status**: engine, `supports_scorecard = FALSE`,
    and the swap-set table at the approval rates the business uses.
6.  **The invariants to check on every rescale**: AUC/KS/Gini unchanged,
    calibration intercept and slope unchanged, only `factor` and
    `offset` moved.

Two scorecards that share items 1 to 3 are comparable; two that share
only item 1 are not, however similar their numbers look.

## Reference

Siddiqi, N. (2006). *Credit Risk Scorecards: Developing and Implementing
Intelligent Credit Scoring*. Wiley.
