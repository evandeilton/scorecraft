# Red / amber / green lights of a score against its reference

Reads a study sample against the reference the score was developed on
and lights every check red, amber or green, in four families:
discrimination, calibration, stability and, for a scorecard, the
variables. With `by`, one set of lights per period or segment, from the
same count table.

## Usage

``` r
scr_rag(x, ...)

# S3 method for class 'scr_scorecard'
scr_rag(
  x,
  plan = NULL,
  sample = "holdout",
  reference = "train",
  by = NULL,
  level = NULL,
  min_events = 20L,
  n_bands = NULL,
  n_boot = NULL,
  seed = NULL,
  max_cells = 1e+05,
  boot_cells = 10000,
  ...
)

# S3 method for class 'data.frame'
scr_rag(
  x,
  score = "score",
  y = "y",
  prob = NULL,
  objective = "risk",
  direction = NULL,
  weight = NULL,
  sample = NULL,
  reference = NULL,
  study = NULL,
  by = NULL,
  plan = NULL,
  level = 0.95,
  min_events = 20L,
  n_bands = 10L,
  n_boot = 200L,
  seed = NULL,
  max_cells = 1e+05,
  boot_cells = 10000,
  ...
)

# S3 method for class 'scr_study'
scr_rag(
  x,
  plan = NULL,
  sample = NULL,
  level = NULL,
  min_events = 20L,
  n_boot = 200L,
  seed = NULL,
  boot_cells = 10000,
  ...
)
```

## Arguments

- x:

  An object from
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)
  or
  [`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md),
  or a `data.frame` with one row per scored case.

- ...:

  Passed on to the methods; an unknown argument is an error.

- plan:

  Thresholds table, as returned by
  [`scr_rag_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_rag_plan.md);
  `NULL` uses the defaults for the objective.

- sample:

  For a scorecard: the study sample (`"holdout"`). For a data.frame: the
  name of a column with sample labels, or `NULL`. For a score study: the
  study samples, `NULL` for every sample but the reference.

- reference:

  For a scorecard: the sample the bands are frozen on (`"train"`). For a
  data.frame: the label of the reference sample; `NULL` takes the first
  level of the `sample` column.

- by:

  Name of a column holding periods or segments (for a scorecard, a
  column of its scored samples such as `"date"`).

- level:

  Confidence level of the intervals. For a scorecard or a score study,
  `NULL` uses `config$study_level` or the level of the study.

- min_events:

  Fewest events, and non-events, of the study group for a lit result.

- n_bands:

  Bands frozen on the reference for the PSI, the rank order and the band
  calibration. For a scorecard, `NULL` uses `config$score_groups`. A
  score study uses its own cuts.

- n_boot:

  Bootstrap resamples of the Gini ratio interval. For a scorecard,
  `NULL` uses `config$n_boot`.

- seed:

  Seed of the bootstrap. A number is local to the call (the user's
  random stream is restored on exit); `NULL` draws from the user's
  stream and advances it. For a scorecard, `NULL` uses `config$seed`.

- max_cells:

  Largest number of distinct score values kept exactly.

- boot_cells:

  Largest number of score cells resampled exactly by the bootstrap
  (default 10,000; `Inf` for no pooling). See the section Method.

- score, y:

  Column names of the score and of the 0/1 outcome (`NA` allowed).

- prob:

  For a data.frame: optional column with the expected event probability
  of every case.

- objective:

  `"risk"` (the event is the bad case) or `"propensity"` (the event is
  the good case).

- direction:

  `"higher_is_safer"` or `"higher_is_riskier"`; `NULL` derives it from
  `objective`.

- weight:

  Optional column of non-negative case weights.

- study:

  Labels of the study samples; `NULL` takes every level other than the
  reference.

## Value

An object of class `scr_rag`:

- `table`:

  One row per check: `sample`, `group`, `family`, `metric`, `level`
  (`"score"`, a variable name or a band label), `value`, `lo`, `hi`,
  `benchmark` (the reference value or critical value it is read
  against), `light` (`"green"`, `"amber"`, `"red"`, `"grey"` or
  `"none"`) and `reason`.

- `summary`:

  One row per sample and group: the light of `discrimination`,
  `calibration`, `stability`, `variables` and `overall`, and the
  `reason` of the overall light.

- `plan`:

  The thresholds used.

- `objective`, `direction`, `level`, `min_events`, `reference`, `study`,
  `by`, `cuts`, `target`, `call`:

  The settings.

## Checks

- Discrimination:

  `gini_ratio`, Gini(study) / Gini(reference), with a bootstrap interval
  from independent resamples of both samples (the count bootstrap of
  [`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
  exact up to `boot_cells` distinct scores and an approximation above);
  `auc_change_p`, the one-sided p-value of the S-test \$\$S =
  (AUC\_{ref} - AUC\_{study}) / \sqrt{se\_{study}^2 + se\_{ref}^2},\$\$
  with both DeLong standard errors computed from the counts per score
  value. This is the two-sample form: both AUCs are estimated here, on
  independent samples. The ECB (2019) instructions take the initial AUC
  as fixed (only the current AUC's standard error), which suits a
  development AUC taken from documentation; applied to an estimated
  reference AUC, that form rejects too often. `ks` is reported without a
  light.

- Calibration:

  Needs an expected probability: the alignment of a scorecard, or the
  `prob` column of a data.frame; otherwise both lights are `"grey"` ("no
  expected probability"). `oe_ratio`, observed over expected events,
  with the Jeffreys interval of the observed rate; `band_calibration`,
  the number of bands whose Jeffreys test rejects the band mean expected
  probability. Under risk both checks are one-sided, against
  under-prediction only (over-prediction is prudent); under propensity
  they are two-sided (see
  [`scr_rag_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_rag_plan.md)).
  Every band is also listed, without a light.

- Stability:

  `score_psi` over bands frozen on the reference, lit by effect and
  significance; `rank_order`, the number of Holm-significant reversals
  between adjacent bands.

- Variables:

  For a scorecard read on its hold-out against train: the CSI of every
  variable over its frozen bins (same rule as the PSI), `iv_ratio` =
  IV(study) / IV(reference), and `woe_sign_flip`, the number of bins
  holding at least 5% of the study volume whose WOE changes sign (amber
  at most).

One convention holds for every light: a light is amber or red only when
the confidence interval shows the metric beyond the threshold (for a
p-value, when the test rejects); with too few events it is `"grey"`. The
thresholds and rules are in
[`scr_rag_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_rag_plan.md).

A group with fewer than `min_events` events, or non-events, in the study
sample gets `"grey"` lights, with the values still reported. Within a
family the worst light wins (red, then amber, then green; `"grey"` only
when nothing is lit). The overall light is the worst of discrimination
and calibration; stability and variables can raise it to amber, never to
red, and an overall without any lit discrimination or calibration check
is `"grey"`. The `reason` of the summary says how the overall light was
formed, for example "calibration not tested" when no expected
probability is available.

With `by`, a group of the study sample is compared with the same group
of the reference when the reference has it (a segment), and with the
whole reference otherwise (a new period). Without a sample column, every
group is compared with the whole data.

## References

Brown, L. D., Cai, T. T. and DasGupta, A. (2001). Interval estimation
for a binomial proportion. *Statistical Science*, 16(2), 101-133.
[doi:10.1214/ss/1009213286](https://doi.org/10.1214/ss/1009213286)

DeLong, E. R., DeLong, D. M. and Clarke-Pearson, D. L. (1988). Comparing
the areas under two or more correlated receiver operating characteristic
curves: a nonparametric approach. *Biometrics*, 44(3), 837-845.

European Central Bank (2019). *Instructions for reporting the validation
results of internal models: IRB Pillar I models for credit risk*. ECB
Banking Supervision.

Siddiqi, N. (2006). *Credit Risk Scorecards: Developing and Implementing
Intelligent Credit Scoring*. Wiley.

Yurdakul, B. and Naranjo, J. (2020). Statistical properties of the
population stability index. *Journal of Risk Model Validation*, 14(4),
89-100.

## See also

Other score-studies:
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md),
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md),
[`scr_rag_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_rag_plan.md),
[`scr_score_cross()`](https://evandeilton.github.io/scorecraft/reference/scr_score_cross.md),
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 40, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                  date_col = "ref_date")
sc <- scr_scorecard(res)
rg <- scr_rag(sc)
rg
#> <scr_rag> target "default" | objective risk | higher_is_safer | reference 'train'
#>   sample     group        discrimination  calibration  stability  variables  overall 
#>   holdout    all          amber           green        green      amber      AMBER   
#> 
#> Not green
#>   amber  holdout    all          gini_ratio      score                  0.8381  upper bound 0.936 below 0.95, not below 0.9
#>   amber  holdout    all          auc_change_p    score                  0.0159  p = 0.0159 (red at or below 0.01, amber at or below 0.05)
#>   amber  holdout    all          iv_ratio        vl_score_02            0.7535  value 0.753 below 0.8, not below 0.5
#>   amber  holdout    all          woe_sign_flip   vl_score_02            1.0000  1 found (green at or below 0); bins (48.660000;64.440000]
#>   amber  holdout    all          woe_sign_flip   vl_score_04            2.0000  2 found (green at or below 0); bins (-Inf;42.800000], (47.660000;50.750000]
#>   amber  holdout    all          woe_sign_flip   ds_band                1.0000  1 found (green at or below 0); bins B
#>   amber  holdout    all          csi             vl_late                0.1042  index 0.104 >= 0.1, above the n-adjusted critical value 0.0135
#>   amber  holdout    all          woe_sign_flip   vl_score_06            1.0000  1 found (green at or below 0); bins (69.210000;77.560000]
#>   amber  holdout    all          iv_ratio        vl_score_05            0.7359  value 0.736 below 0.8, not below 0.5
#>   amber  holdout    all          woe_sign_flip   vl_score_07            1.0000  1 found (green at or below 0); bins (74.330000;76.800000]
rg$summary
#>     sample  group discrimination calibration stability variables overall reason
#>     <char> <char>         <char>      <char>    <char>    <char>  <char> <char>
#> 1: holdout    all          amber       green     green     amber   amber       

# a data.frame with a sample column and an expected probability
d <- rbind(data.frame(sample = "dev", sc$samples$train[, c("score", "y", "prob")]),
           data.frame(sample = "new", sc$samples$holdout[, c("score", "y", "prob")]))
scr_rag(d, prob = "prob", sample = "sample", n_boot = 50)$summary
#>    sample  group discrimination calibration stability variables overall reason
#>    <char> <char>         <char>      <char>    <char>    <char>  <char> <char>
#> 1:    new    all          amber       green     green      <NA>   amber       
```
