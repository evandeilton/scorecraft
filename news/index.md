# Changelog

## scorecraft 0.1.0

First release. A production-grade scorecard engine for binary targets,
built on ‘OptimalBinningWoE’: audit funnel, single configuration, named
relaxation, first-class scale alignment, cut-off strategy and hardened
deliverables.

- Seven stages, each an exported function, chained by
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
  and
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md):
  [`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md),
  [`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md),
  [`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md),
  [`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md),
  [`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md),
  [`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md)/[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md)/[`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md).
- [`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md)
  is a first-class stage: banded log-odds regression on the raw score
  composed with the PDO map, `odds_orientation` recorded, applied to any
  engine. It runs automatically inside
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).
- [`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
  emits production SQL in fourteen dialects: a pre-processing CTE, the
  WOE/BIN transformation from the authoritative cut points and, for a
  scorecard, the exact score plus whole points from the bin index. R-SQL
  equivalence is verified by test against DuckDB and SQLite.
- Binning is parallelised by column (`nthread`), with the fits merged;
  the result is identical to the serial one.
- [`scr_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_metrics.md)
  always reports a bootstrap confidence interval for AUC/KS/Gini;
  [`scr_psi()`](https://evandeilton.github.io/scorecraft/reference/scr_psi.md)
  reports the fixed threshold next to the sample-size-adjusted critical
  value of Yurdakul and Naranjo (2020).
- A tree challenger (`xgboost` or `lightgbm`) can be fitted on the same
  WOE columns and aligned to the same scale, with
  `supports_scorecard = FALSE`.
- [`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md)
  implements honest reject inference: population scope, band coverage
  and a 2x/4x/8x sensitivity band, never parcelling by default.
- [`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md)
  recomputes PSI/CSI (with the signed points shift) and the performance
  by vintage on new data; it never schedules itself.
- [`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
  writes four hardened `.xlsx` workbooks (selection, scorecard,
  validation, strategy), the SQL files and a Markdown summary.
- [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
  opens a manual binning lab:
  [`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md),
  [`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md)
  (breaks, groups, merge, split, missing_to, other_to, reset),
  [`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md)/[`scr_classing_discard()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md)
  with a mandatory reason,
  [`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md)
  (keep/drop/force),
  [`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md)/[`scr_classing_read()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md)/[`scr_classing_import()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md)
  for a CSV/xlsx round trip,
  [`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md)
  to commit into a new `scr_result`, and
  [`scr_decisions()`](https://evandeilton.github.io/scorecraft/reference/scr_decisions.md)
  for the append-only ledger. Manual bins share the engine’s contract,
  so
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
  [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
  and
  [`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
  follow them unchanged; the funnel gains `provenance`.
- [`scr_connect()`](https://evandeilton.github.io/scorecraft/reference/scr_connect.md)
  accepts any DBI driver next to an ODBC DSN, and
  [`scr_fetch()`](https://evandeilton.github.io/scorecraft/reference/scr_fetch.md)
  samples server-side with a dialect-aware random expression.
