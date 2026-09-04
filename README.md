# scorecraft <img src="man/figures/logo.png" align="right" height="139" alt="scorecraft hex logo" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/evandeilton/scorecraft/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/evandeilton/scorecraft/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/evandeilton/scorecraft/actions/workflows/pkgdown.yaml/badge.svg)](https://evandeilton.github.io/scorecraft/)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

A production-grade scorecard engine for binary targets (credit risk, fraud,
propensity), built on
[OptimalBinningWoE](https://github.com/evandeilton/OptimalBinningWoE). It
selects variables through optimal binning and a multi-strategy consensus,
fits the points scorecard with an explicit and auditable **scale
alignment**, sweeps cut-offs with frozen cuts, performs honest reject
inference, monitors PSI/CSI with both the fixed and the sample-size-adjusted
threshold, and emits **production SQL** whose output is verified against R
by test.

Every stage is an exported function; `scr_select()` and `scr_scorecard()`
are the shortcuts that chain them.

Documentation site: <https://evandeilton.github.io/scorecraft/>.

## Installation

```r
# install.packages("pak")
pak::pak("evandeilton/scorecraft")
```

`xgboost` and `OptimalBinningWoE` are required. `glmnet`, `ranger` and
`lightgbm` are optional consensus voters; `openxlsx` is needed by
`scr_export()`; `DBI` plus a driver by `scr_connect()`.

## The pipeline in one screen

```r
library(scorecraft)

cfg <- scr_config("moderate", objective = "risk", nthread = 4)

# Stages 0-4: split, triage, binning + screening, multi-strategy consensus
res <- scr_select(scr_demo, "default", config = cfg, drop = "id", date_col = "ref_date")
res
scr_selected(res)                 # the shortlist
scr_funnel(res)                   # every input column and the stage it died at
scr_leakage(res)                  # suspicious IV and degenerate bins

# Stages 4-5: points scorecard, aligned to 600 points at 50:1 with PDO 20
sc <- scr_scorecard(res, challenger = "xgboost")
sc
sc$alignment                      # ln(odds) = I + S * logit -> score = a + b * logit
scr_score_metrics(sc)             # AUC/KS/Gini with bootstrap CI, per sample
scr_score_gains(sc, "holdout")    # frozen bands, from the risky to the safe side

# Stage 6: cut-off, strategy with marginal expected profit, honest reject inference
scr_cutoff(sc)
scr_strategy(sc, revenue_good = 1080, loss_bad = 4500)
scr_reject(sc)

# Coarse classing lab: manual bins and manual variable choice, with a reason
lab <- scr_coarse_classing(res)
p   <- scr_classing_propose(lab, "ds_regiao",
                            groups = list(south = c("BA", "RS"), north = c("SP", "RJ", "MG")))
lab <- scr_classing_accept(lab, p, reason = "north/south is what pricing uses")
lab <- scr_classing_choose(lab, drop = "vl_score_10", reason = "not available at decision time")
res2 <- scr_classing_apply(lab)      # a new scr_result; scr_scorecard(res2) refits on it
scr_decisions(res2)                  # the append-only decision ledger

# Production: R and SQL give the same numbers
scr_apply(sc, newdata)
cat(scr_sql(sc, table = "prd.customers", dialect = "databricks"), sep = "\n")

# Monitoring, when the analyst decides to run it
scr_monitor(sc, newdata, date_col = "ref_date", target = "default")

# Deliverables: four hardened .xlsx workbooks, the SQL files, a Markdown summary
scr_export(sc, "output")
```

## Why another scorecard package

* **Alignment is a stage, not a footnote.** `scr_align()` takes the raw
  score of any engine to the declared scale by regressing empirical log-odds
  on score bands and composing with the PDO map, and records
  `odds_orientation`. Two scorecards aligned this way are comparable point
  for point.
* **The funnel is the deliverable.** No candidate disappears from the
  report: every input column carries the exact stage it failed at and why.
* **Production SQL is the core, not an export.** Two blocks (pre-processing
  CTE, WOE/BIN from the authoritative cut points), a third for the score,
  fourteen dialects, equivalence with `scr_apply()` verified by test in
  DuckDB and SQLite.
* **Both thresholds, always.** PSI/CSI report the market's 0.10/0.25 next to
  the sample-size-adjusted critical value; AUC/KS/Gini always come with a
  bootstrap interval.
* **Honest reject inference.** Population scope, band coverage and a
  sensitivity band instead of a single invented multiplier.
* **Manual binning with an audit trail.** `scr_coarse_classing()` opens a
  lab where the analyst proposes breaks or groupings, reads the comparison
  against the optimal bins on train and hold-out, accepts or discards with a
  mandatory reason, forces or drops variables, and commits to a new result
  that the scorecard, the R scoring and the SQL follow unchanged. The spec
  round-trips through CSV/xlsx for a business reviewer.
* **A challenger that never pretends.** A tree model aligned to the same
  scale for comparison, with `supports_scorecard = FALSE`: no points, no
  reason codes.

## Reading conventions

`objective = "risk"` means `target = 1` is the bad case and more points are
safer (`higher_is_safer`, odds `safe:event`). `objective = "propensity"`
means `target = 1` is the good case and more points are more likely
(`higher_is_riskier`, odds `event:safe`). `objective` never changes the
selection; `event_level` does.
