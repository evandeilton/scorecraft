# Overlap of rules and a score

Compares a set of rules (0/1 flags) with the alerts of a score at one
cut: what each rule catches, what the score also catches, what only one
of them catches, and which rules the score makes redundant. Built for
fraud, where expert rules and a model alert on the same transactions.

## Usage

``` r
scr_overlap(x, ...)

# S3 method for class 'data.frame'
scr_overlap(
  x,
  score = "score",
  y = "y",
  rules,
  alert_share = NULL,
  cut = NULL,
  value = NULL,
  objective = "risk",
  direction = "higher_is_riskier",
  retire_at = 0.95,
  level = 0.95,
  weight = NULL,
  max_cells = 1e+05,
  ...
)
```

## Arguments

- x:

  A `data.frame` with one row per case (a transaction).

- ...:

  Passed on to the methods; an unknown argument is an error.

- score, y:

  Column names of the score and of the 0/1 outcome (`NA` allowed).

- rules:

  Names of the rule columns: 0/1 numbers or logicals.

- alert_share:

  Share of the rows the score alerts, in (0, 1\].

- cut:

  Instead of `alert_share`: the score cut of the alerts.

- value:

  Optional column of a value per case (the amount).

- objective:

  `"risk"` (the event is the bad case) or `"propensity"` (the event is
  the good case).

- direction:

  `"higher_is_riskier"` (default, a fraud score) or `"higher_is_safer"`;
  `NULL` derives it from `objective`.

- retire_at:

  Share of the events of a rule caught by the score from which the rule
  is a candidate for retirement.

- level:

  Confidence level of the Jeffreys intervals.

- weight:

  Optional column of non-negative case weights.

- max_cells:

  Largest number of distinct score values kept exactly.

## Value

An object of class `c("scr_overlap", "list")`:

- `table`:

  One row per rule (see the section Rules).

- `summary`:

  One row: `n`, `events`, `n_score`, `share_score`, `precision_score`,
  `n_rules`, `share_rules`, `precision_rules`, `n_any`, `share_any`,
  `precision_any`, `recall_score`, `recall_rules`, `recall_any`,
  `incr_score`, `incr_rules` and, with `value`, `value_events`,
  `value_recall_score`, `value_recall_rules`, `value_recall_any`,
  `value_incr_score` and `value_incr_rules`.

- `cut`, `alert_share`, `rules`, `retire_at`, `level`, `objective`,
  `direction`, `score`, `target`, `value`, `n`, `n_rows`, `n_dropped`,
  `n_patterns`, `weighted`, `call`:

  The cut and the settings; `n_patterns` is the number of distinct
  patterns of rule flags and score alert.

## Score alerts

The score alerts the rows on its event-rich side: `score >= cut` under
`higher_is_riskier` and `score < cut` under `higher_is_safer`, the
convention of
[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md).
Give `cut`, or `alert_share`, the share of the rows to alert: the cut is
then the boundary between two distinct scores nearest to that share
(tie-safe, as in
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md)),
and the share realized is reported in the summary (`share_score`).

## Rules

Per rule, the rows it flags are split by the score alert:

- `n_rule`, `events_rule`, `precision_rule`: every row the rule flags;

- `n_both`, `events_both`, `precision_both`: flagged by the rule and
  alerted by the score;

- `n_rule_only`, `events_rule_only`, `precision_rule_only`: flagged by
  the rule, not alerted by the score;

- `n_score_only`, `events_score_only`, `precision_score_only`: alerted
  by the score, not flagged by the rule;

- `caught_by_score` = `events_both / events_rule`, the share of the
  events of the rule that the score alerts too, and `retire_candidate` =
  `caught_by_score >= retire_at` (`NA` for a rule without events): the
  score already catches what the rule catches.

A precision is the event rate of the set, events over rows with a known
outcome, with its Jeffreys interval (`_lo`, `_hi`; on the Kish effective
size under weights). With `value`, `value_rule`, `value_both`,
`value_rule_only` and `value_score_only` are the sums of the value over
the events of each set, and `caught_by_score_value` the share in value.
A missing rule flag counts as not flagged.

## Summary

`recall_score`, `recall_rules` (any rule) and `recall_any` (the score or
any rule) are the shares of all events alerted; `incr_score` =
`recall_any - recall_rules` is what the score adds to the rules and
`incr_rules` = `recall_any - recall_score` what the rules add to the
score. The `value_` columns are the same shares of the event value. The
alert volumes are `n_score`, `n_rules` and `n_any`, each with its share
of all rows and its precision.

Rows with a missing or infinite score, or a zero weight, are left out
(`n_dropped`); rows with a missing outcome count in the volumes only.

## Cost

The rows are counted once per distinct pattern of rule flags and score
alert, and every set is a sum over that table. Time and memory after the
pass grow with the number of distinct patterns times the number of rules
(`n_patterns` is reported). A few dozen rules that seldom fire together
give a small table; many dense, unrelated rules can give nearly one
pattern per row, in which case pass the rules in smaller groups.

## References

Brown, L. D., Cai, T. T. and DasGupta, A. (2001). Interval estimation
for a binomial proportion. *Statistical Science*, 16(2), 101-133.
[doi:10.1214/ss/1009213286](https://doi.org/10.1214/ss/1009213286)

## See also

[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md)
for the cut of the alerts under a capacity,
[`scr_detection()`](https://evandeilton.github.io/scorecraft/reference/scr_detection.md)
for the time to detection,
[`scr_score_cross()`](https://evandeilton.github.io/scorecraft/reference/scr_score_cross.md)
for two scores on the same rows.

Other score-studies:
[`scr_bands()`](https://evandeilton.github.io/scorecraft/reference/scr_bands.md),
[`scr_claims()`](https://evandeilton.github.io/scorecraft/reference/scr_claims.md),
[`scr_detection()`](https://evandeilton.github.io/scorecraft/reference/scr_detection.md),
[`scr_maturity()`](https://evandeilton.github.io/scorecraft/reference/scr_maturity.md),
[`scr_mix_shift()`](https://evandeilton.github.io/scorecraft/reference/scr_mix_shift.md),
[`scr_operating()`](https://evandeilton.github.io/scorecraft/reference/scr_operating.md),
[`scr_rag()`](https://evandeilton.github.io/scorecraft/reference/scr_rag.md),
[`scr_rag_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_rag_plan.md),
[`scr_score_cross()`](https://evandeilton.github.io/scorecraft/reference/scr_score_cross.md),
[`scr_segments()`](https://evandeilton.github.io/scorecraft/reference/scr_segments.md),
[`scr_tiers()`](https://evandeilton.github.io/scorecraft/reference/scr_tiers.md),
[`scr_uplift()`](https://evandeilton.github.io/scorecraft/reference/scr_uplift.md)

## Examples

``` r
local({
  set.seed(1)
  n <- 20000
  x <- rnorm(n)
  fraud <- rbinom(n, 1, plogis(-5 + 1.5 * x))
  d <- data.frame(score = round(100 * plogis(x + rnorm(n, sd = 0.5))), y = fraud,
                  amount = round(rexp(n, 1 / 80), 2),
                  # one rule the score covers, one that sees something else
                  rule_velocity = as.integer(x > 1.6),
                  rule_new_device = rbinom(n, 1, ifelse(fraud == 1, 0.3, 0.01)))
  ov <- scr_overlap(d, rules = c("rule_velocity", "rule_new_device"), alert_share = 0.05,
                    value = "amount")
  print(ov)
  ov$table[, c("rule", "n_rule", "precision_rule", "caught_by_score", "retire_candidate")]
})
#> <scr_overlap> outcome "y" | score "score" (higher_is_riskier) | 2 rules
#>   20,000 rows | 389 events | the score alerts score >= 86.5: 971 rows (4.86%)
#> 
#>   alerts              n    share  precision   recall
#>   score             971    4.86%      12.5%    31.1%
#>   any rule        1,360    6.80%      16.6%    58.1%
#>   either          1,683    8.42%      14.0%    60.7%
#>   incremental recall: the score over the rules +2.57 pp, the rules over the score +29.56 pp
#>   in value ("amount"): recall 30.6% score, 55.7% rules, 58.0% either | incremental +2.27 pp and +27.44 pp
#> 
#> Rules (retire candidate: the score catches at least 95% of the events of the rule)
#>   rule                           n    events  precision    n_both n_rule_only ev_rule_only  caught  retire
#>   rule_velocity              1,102       150      13.6%       637         465           48   68.0%  no
#>   rule_new_device              316       122      38.6%        54         262           79   35.2%  no
#>               rule n_rule precision_rule caught_by_score retire_candidate
#>             <char>  <num>          <num>           <num>           <lgcl>
#> 1:   rule_velocity   1102      0.1361162        0.680000            FALSE
#> 2: rule_new_device    316      0.3860759        0.352459            FALSE
```
