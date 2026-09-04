# Changelog

## scorecraft 0.2.0 (unreleased)

The IRB layer: from the scorecard to regulatory risk parameters, with
the same contracts as the scorecard pipeline (one configuration, ledgers
with mandatory reasons, hold-out revalidation with frozen bins, hardened
workbooks, production SQL verified against DuckDB and SQLite). Regimes
are parameter tables selected by a preset, never prose.

- [`scr_irb_params()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_params.md)
  ships the numbers of three presets (`"bcb"`, `"basel3_final"`,
  `"crr3"`): PD floors, LGD input floors, foundation LGD, standardised
  CCFs, asset correlations, maturity rules, output floor and
  standardised risk weights; the tables are editable and edits are
  recorded.
- [`scr_default()`](https://evandeilton.github.io/scorecraft/reference/scr_default.md)
  builds the default flag from a monthly panel (days past due with
  absolute and relative materiality, unlikeliness to pay, probation,
  restructuring, obligor-level pulling effect);
  [`scr_default_rate()`](https://evandeilton.github.io/scorecraft/reference/scr_default_rate.md)
  gives the default rates by cohort, grade, segment and exposure, with
  the long-run average and its benchmark.
- [`scr_bin_continuous()`](https://evandeilton.github.io/scorecraft/reference/scr_bin_continuous.md)
  bins drivers against a bounded continuous target (LGD, CCF) and
  returns an object with the shape of the engine’s, so
  [`OptimalBinningWoE::obwoe_apply()`](https://evandeilton.github.io/OptimalBinningWoE/reference/obwoe_apply.html)
  and `obwoe_sql()` reproduce the bin means in R and in every SQL
  dialect; hold-out revalidation with frozen cut points and PSI.
- Configuration gains the keys of stages 8 to 12 (`default_*`, `pd_*`,
  `lgd_*`, `ccf_*`, `framework`, `capital_*`, `ecl_*`), all registered
  in
  [`scr_config_keys()`](https://evandeilton.github.io/scorecraft/reference/scr_config_keys.md)
  and validated.
- New demonstration data: `scr_demo_panel`, `scr_demo_lgd`,
  `scr_demo_lgd_cashflows`, `scr_demo_rates`, `scr_demo_ead`,
  `scr_demo_portfolio`.
- PD:
  [`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md),
  [`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md)
  (intercept shift, log-odds `(a, b)`, scaling, quasi-moment matching; a
  new alignment, the scorecard untouched),
  [`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md)
  (geometric, quantile or supplied grades, merges below the minimum
  counts, monotone repair recorded),
  [`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md)
  (estimation error computed; other categories with a mandatory reason),
  [`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md)
  (floors from the preset),
  [`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md),
  [`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md)
  (Jeffreys, binomial, normal, Hosmer-Lemeshow, multi-period, AUC
  against the initial value, PSI, migration bandwidths, concentration;
  traffic lights),
  [`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md),
  with [`predict()`](https://rdrr.io/r/stats/predict.html),
  [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
  [`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
  (grade and PD as a `CASE` on the score) and
  [`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
  methods.
- LGD:
  [`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md)
  (discounted recoveries and costs, cures, merged re-defaults,
  extrapolated incomplete workouts, named funnel rules),
  [`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md)
  (cure stage on the binary engine, severity stage on the continuous
  binner with a fractional logit or a beta regression, hold-out
  revalidation, pools),
  [`scr_lgd_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_downturn.md),
  [`scr_lgd_floor()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_floor.md),
  [`scr_elbe()`](https://evandeilton.github.io/scorecraft/reference/scr_elbe.md),
  [`scr_lgd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_validate.md),
  with
  [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
  [`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
  (both stages, pool `CASE`, floored result) and
  [`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
  methods.
- EAD:
  [`scr_ead_data()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_data.md)
  (realised conversion factors under a fixed, cohort or variable
  horizon; conversion factor below and limit factor above a utilisation
  threshold; named funnel rules),
  [`scr_ead()`](https://evandeilton.github.io/scorecraft/reference/scr_ead.md)
  (driver bins with admission rules, pools, estimation-error margin,
  standardised floor),
  [`scr_ead_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_downturn.md),
  [`scr_ead_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_validate.md),
  with
  [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md),
  [`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
  and
  [`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
  methods.
- Expected loss and capital:
  [`scr_el()`](https://evandeilton.github.io/scorecraft/reference/scr_el.md),
  [`scr_irb_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_rw.md)
  (the risk-weight function with correlations, size adjustment,
  maturity, floors and the defaulted case),
  [`scr_sa_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_sa_rw.md),
  [`scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_capital.md)
  (reconciliation by segment, output floor, provisions shortfall and
  excess, floors impact, sensitivity grid, concentration),
  [`scr_pd_stress()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_stress.md),
  [`scr_ecl()`](https://evandeilton.github.io/scorecraft/reference/scr_ecl.md)
  (survival-weighted 12-month and lifetime expected credit loss with
  stages and scenarios), with
  [`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
  (constants per pool, no normal quantile at run time) and
  [`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
  methods.
- `betareg` joins Suggests for the beta severity engine of the LGD
  model.

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

### Hardening after the first release (unreleased)

- [`scr_monitoring_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_monitoring_plan.md)
  is the monitoring contract: created by
  [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md),
  written to the `Monitoring_Plan` sheet, and read back by
  `scr_monitor(plan = )` (a table or the strategy workbook), which now
  takes its PSI/CSI thresholds, alpha and `min_events_per_period` from
  it.
- The scorecard stores the hold-out bin index of every variable, so the
  `Stability_CSI_Timeline` sheet is a real timeline by vintage without a
  [`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md)
  object.
- The parallel backend is selectable with
  `options(scorecraft.parallel = "fork" | "psock" | "serial")`; the test
  suite exercises the PSOCK path (the Windows semantics) on every
  platform and pins serial == fork == psock.
- The descriptive triage is parallel by column as well.
- Workers never fail silently on any backend: a worker error is
  re-thrown with the failing item, a worker killed by the system is
  reported as such (instead of a `NULL` that surfaces later as a
  subscript error), warnings raised in a worker are re-raised in the
  parent, PSOCK workers run with a single data.table thread, and a
  `data.table` returned by a worker is re-allocated so that `:=` works
  on it. `R CMD check --as-cran`’s two-process limit is honoured.
- On Linux the fork backend caps the number of workers by the memory
  available (`options(scorecraft.fork_mem_fraction = 0.75)`, `Inf` to
  disable): forked workers duplicate the parent heap once the garbage
  collector runs, and twenty workers over a two-million-row table were
  killed by the OOM daemon in under two minutes.
