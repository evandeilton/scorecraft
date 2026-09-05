# scorecraft 0.2.0 (unreleased)

The IRB layer: from the scorecard to regulatory risk parameters, with the
same contracts as the scorecard pipeline (one configuration, ledgers with
mandatory reasons, hold-out revalidation with frozen bins, hardened
workbooks, production SQL verified against DuckDB and SQLite). Regimes are
parameter tables selected by a preset, never prose.

* `scr_irb_params()` ships the numbers of three presets (`"bcb"`,
  `"basel3_final"`, `"crr3"`): PD floors, LGD input floors, foundation LGD,
  standardised CCFs, asset correlations, maturity rules, output floor and
  standardised risk weights; the tables are editable and edits are recorded.
* `scr_default()` builds the default flag from a monthly panel (days past
  due with absolute and relative materiality, unlikeliness to pay,
  probation, restructuring, obligor-level pulling effect);
  `scr_default_rate()` gives the default rates by cohort, grade, segment
  and exposure, with the long-run average and its benchmark.
* `scr_bin_continuous()` bins drivers against a bounded continuous target
  (LGD, CCF) and returns an object with the shape of the engine's, so
  `OptimalBinningWoE::obwoe_apply()` and `obwoe_sql()` reproduce the bin
  means in R and in every SQL dialect; hold-out revalidation with frozen
  cut points and PSI.
* `scr_config()` gains the keys of stages 8 to 12 (`default_*`, `pd_*`,
  `lgd_*`, `ccf_*`, `framework`, `capital_*`, `ecl_*`), all registered in
  `scr_config_keys()` and validated.
* `scr_demo_panel`, `scr_demo_lgd`, `scr_demo_lgd_cashflows`,
  `scr_demo_rates`, `scr_demo_ead` and `scr_demo_portfolio` are new
  demonstration data.
* PD: `scr_master_scale()`, `scr_calibrate()` (intercept shift, log-odds
  `(a, b)`, scaling, quasi-moment matching; a new alignment, the scorecard
  untouched), `scr_grades()` (geometric, quantile or supplied grades, merges
  below the minimum counts, monotone repair recorded), `scr_moc()`
  (estimation error computed; other categories with a mandatory reason),
  `scr_pd()` (floors from the preset), `scr_migration()`,
  `scr_pd_validate()` (Jeffreys, binomial, normal, Hosmer-Lemeshow,
  multi-period, AUC against the initial value, PSI, migration bandwidths,
  concentration; traffic lights), `scr_pd_pit_ttc()`, with `predict()`,
  `scr_apply()`, `scr_sql()` (grade and PD as a `CASE` on the score) and
  `scr_export()` methods.
* LGD: `scr_workout()` (discounted recoveries and costs, cures, merged
  re-defaults, extrapolated incomplete workouts, named funnel rules),
  `scr_lgd()` (cure stage on the binary engine, severity stage on the
  continuous binner with a fractional logit or a beta regression, hold-out
  revalidation, pools), `scr_lgd_downturn()`, `scr_lgd_floor()`,
  `scr_elbe()`, `scr_lgd_validate()`, with `scr_apply()`, `scr_sql()` (both
  stages, pool `CASE`, floored result) and `scr_export()` methods.
* EAD: `scr_ead_data()` (realised conversion factors under a fixed, cohort
  or variable horizon; conversion factor below and limit factor above a
  utilisation threshold; named funnel rules), `scr_ead()` (driver bins with
  admission rules, pools, estimation-error margin, standardised floor),
  `scr_ead_downturn()`, `scr_ead_validate()`, with `scr_apply()`,
  `scr_sql()` and `scr_export()` methods.
* Expected loss and capital: `scr_el()`, `scr_irb_rw()` (the risk-weight
  function with correlations, size adjustment, maturity, floors and the
  defaulted case), `scr_sa_rw()`, `scr_capital()` (reconciliation by
  segment, output floor, provisions shortfall and excess, floors impact,
  sensitivity grid, concentration), `scr_pd_stress()`, `scr_ecl()`
  (survival-weighted 12-month and lifetime expected credit loss with
  stages and scenarios), with `scr_sql()` (constants per pool, no normal
  quantile at run time) and `scr_export()` methods.
* `scr_irb_rw()` and `scr_capital()` read the supervisory LGD of the
  foundation approach from `params$lgd_firb` through a `claim` type;
  `scr_sa_rw()` and `scr_capital()` apply the non-granular retail weight
  with `granular = FALSE`; the Hosmer-Lemeshow light of
  `scr_pd_validate()` is green when every grade sits on the conservative
  side (the PD above the observed rate), since the statistic is two-sided.
* `betareg` (Suggests) powers the beta severity engine of `scr_lgd()`.
* After the documentation audit: `scr_iv()` ignores `NA` for every group
  type; `scr_classing_read()` validates the separator and the spec carries
  it into `scr_classing_import()`; the `TOO_MANY_BINS` screening rule can
  fire (the screen reads `max_bins`); `scr_psi()` stores and prints its
  thresholds; `scr_default_rate()` reports one long-run mean and
  benchmarks an optional `lra_adjusted`; one `asset_class` configuration
  key replaces `pd_asset_class` and `capital_asset_class`;
  `scr_lgd_downturn()` always records a reason; the traffic-light
  convention is red at or below the first threshold in PD, LGD and EAD;
  `scr_apply()` on an `scr_ead` takes `what`; `scr_fetch()` gains
  `verbose` and `scr_run()` follows `config$verbose`; the `scr_demo`
  columns carry English names (`vl_partial_*`, `vl_noise_*`,
  `vl_constant`, `vl_near_const`, `vl_duplicate`, `vl_redundant`,
  `vl_late`, `ds_region`, `ds_band`, `ds_channel`, `ds_high_card`).

## Scorecard pipeline hardening

* `scr_monitoring_plan()` is the monitoring contract: created by
  `scr_scorecard()`, written to the `Monitoring_Plan` sheet, and read back by
  `scr_monitor(plan = )` (a table or the strategy workbook), which now takes
  its PSI/CSI thresholds, alpha and `min_events_per_period` from it.
* `scr_scorecard()` stores the hold-out bin index of every variable, so the
  `Stability_CSI_Timeline` sheet is a real timeline by vintage without a
  `scr_monitor()` object.
* `options(scorecraft.parallel = "fork" | "psock" | "serial")` selects
  the parallel backend; the test suite exercises the PSOCK path (the
  Windows semantics) on every platform and pins serial == fork == psock.
* `scr_triage()` is parallel by column as well.
* Workers never fail silently on any backend: a worker error is re-thrown
  with the failing item, a worker killed by the system is reported as such
  (instead of a `NULL` that surfaces later as a subscript error), warnings
  raised in a worker are re-raised in the parent, PSOCK workers run with a
  single data.table thread, and a `data.table` returned by a worker is
  re-allocated so that `:=` works on it. `R CMD check --as-cran`'s
  two-process limit is honoured.
* `options(scorecraft.fork_mem_fraction = 0.75)` caps the fork workers by
  the memory available on Linux (`Inf` to disable): forked workers duplicate the parent heap once the garbage
  collector runs, and twenty workers over a two-million-row table were
  killed by the OOM daemon in under two minutes.

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
* `scr_bin()` is parallelised by column (`nthread`), with the fits merged;
  the result is identical to the serial one.
* `scr_metrics()` always reports a bootstrap confidence interval for
  AUC/KS/Gini; `scr_psi()` reports the fixed threshold next to the
  sample-size-adjusted critical value of Yurdakul and Naranjo (2020).
* `scr_scorecard(challenger = )` fits a tree challenger (`xgboost` or
  `lightgbm`) on the same WOE columns, aligned to the same scale, with
  `supports_scorecard = FALSE`.
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
