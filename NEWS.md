# scorecraft 0.1.0

First release. A production-grade scorecard engine for binary targets, built
on 'OptimalBinningWoE': audit funnel, single configuration, named relaxation,
first-class scale alignment, cut-off strategy and hardened deliverables.

* Seven stages, each an exported function, chained by `scr_select()` and
  `scr_scorecard()`: `scr_split()`, `scr_triage()`, `scr_bin()`,
  `scr_model()`, `scr_align()`, `scr_cutoff()`/`scr_strategy()`/`scr_reject()`.
* `scr_align()` is a first-class stage: banded log-odds regression on the raw
  score composed with the PDO map, `odds_orientation` recorded, applied to
  any engine. It runs automatically inside `scr_scorecard()`.
* `scr_sql()` emits production SQL in fourteen dialects: a pre-processing
  CTE, the WOE/BIN transformation from the authoritative cut points and, for
  a scorecard, the exact score plus whole points from the bin index. R-SQL
  equivalence is verified by test against DuckDB and SQLite.
* Binning is parallelised by column (`nthread`), with the fits merged; the
  result is identical to the serial one.
* `scr_metrics()` always reports a bootstrap confidence interval for
  AUC/KS/Gini; `scr_psi()` reports the fixed threshold next to the
  sample-size-adjusted critical value of Yurdakul and Naranjo (2020).
* A tree challenger (`xgboost` or `lightgbm`) can be fitted on the same WOE
  columns and aligned to the same scale, with `supports_scorecard = FALSE`.
* `scr_reject()` implements honest reject inference: population scope, band
  coverage and a 2x/4x/8x sensitivity band, never parcelling by default.
* `scr_monitor()` recomputes PSI/CSI (with the signed points shift) and the
  performance by vintage on new data; it never schedules itself.
* `scr_export()` writes four hardened `.xlsx` workbooks (selection,
  scorecard, validation, strategy), the SQL files and a Markdown summary.
* `scr_coarse_classing()` opens a manual binning lab: `scr_classing_view()`,
  `scr_classing_propose()` (breaks, groups, merge, split, missing_to,
  other_to, reset), `scr_classing_accept()`/`scr_classing_discard()` with a
  mandatory reason, `scr_classing_choose()` (keep/drop/force),
  `scr_classing_spec()`/`scr_classing_read()`/`scr_classing_import()` for a
  CSV/xlsx round trip, `scr_classing_apply()` to commit into a new
  `scr_result`, and `scr_decisions()` for the append-only ledger. Manual
  bins share the engine's contract, so `scr_scorecard()`, `scr_apply()` and
  `scr_sql()` follow them unchanged; the funnel gains `provenance`.
* `scr_connect()` accepts any DBI driver next to an ODBC DSN, and
  `scr_fetch()` samples server-side with a dialect-aware random expression.
