# Package index

## Configuration

- [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md)
  : Pipeline configuration
- [`scr_config_keys()`](https://evandeilton.github.io/scorecraft/reference/scr_config_keys.md)
  : Dictionary of configuration keys
- [`scr_presets()`](https://evandeilton.github.io/scorecraft/reference/scr_presets.md)
  : Selection presets, side by side
- [`scr_verbose()`](https://evandeilton.github.io/scorecraft/reference/scr_verbose.md)
  : Switch progress messages on or off

## Stages

Every stage of the pipeline as a function, plus the shortcuts that chain
them.

- [`predict(`*`<scr_align>`*`)`](https://evandeilton.github.io/scorecraft/reference/predict.scr_align.md)
  : Apply an alignment to raw scores
- [`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md)
  : Stage 5: align a raw score to the declared scale
- [`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md)
  : Stage 2: optimal binning, screening, hold-out revalidation and
  pruning
- [`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md)
  : Stage 6: cut-off sweep with frozen cuts
- [`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md)
  : Stages 3 and 4: multi-strategy selection and consensus
- [`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md)
  : Monitor the scorecard on new data
- [`scr_monitoring_plan()`](https://evandeilton.github.io/scorecraft/reference/scr_monitoring_plan.md)
  : The monitoring plan: the contract scr_monitor() reads
- [`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md)
  : Stage 6: honest reject inference through a sensitivity band
- [`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md)
  : Run the selection for several targets straight from the database
- [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
  : Stages 4 and 5: points scorecard, aligned to the declared scale
- [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
  : Select variables for the scorecard
- [`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md)
  : Stage 0: type the data and split train and hold-out
- [`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md)
  : Stage 6: strategy table per band, with marginal expected profit
- [`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)
  : Stage 1: descriptive triage and sentinel resolution

## Coarse classing lab

Manual binning, manual variable choice and the decision ledger.

- [`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md)
  [`scr_classing_discard()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md)
  : Accept or discard a proposal
- [`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md)
  : Commit the lab into a new selection result
- [`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md)
  : Choose the final variable list manually
- [`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md)
  : Propose manual bins for a variable
- [`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md)
  [`scr_classing_read()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md)
  [`scr_classing_import()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md)
  : The classing specification as a long table (and its file round trip)
- [`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md)
  : Inspect the current bins of a variable in the lab
- [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
  : Coarse classing lab: manual binning and manual variable choice
- [`scr_decisions()`](https://evandeilton.github.io/scorecraft/reference/scr_decisions.md)
  : Decision ledger of a lab, a result or a scorecard

## Reading the result

- [`scr_funnel()`](https://evandeilton.github.io/scorecraft/reference/scr_funnel.md)
  : Audit funnel: every input variable and its fate
- [`scr_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_gains.md)
  : Gains table, at bin level
- [`scr_leakage()`](https://evandeilton.github.io/scorecraft/reference/scr_leakage.md)
  : Leakage and suspicious-strength audit
- [`print(`*`<scr_result>`*`)`](https://evandeilton.github.io/scorecraft/reference/scr_result.md)
  [`summary(`*`<scr_result>`*`)`](https://evandeilton.github.io/scorecraft/reference/scr_result.md)
  [`as.data.frame(`*`<scr_result>`*`)`](https://evandeilton.github.io/scorecraft/reference/scr_result.md)
  [`plot(`*`<scr_result>`*`)`](https://evandeilton.github.io/scorecraft/reference/scr_result.md)
  : Result of a selection
- [`scr_score_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_score_gains.md)
  : Score gains per frozen band
- [`scr_score_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_score_metrics.md)
  : Score metrics per sample, with CI
- [`scr_selected()`](https://evandeilton.github.io/scorecraft/reference/scr_selected.md)
  : Variables approved for the scorecard

## Production

Scoring in R, production SQL, deliverables.

- [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
  : Apply the WOE transformation or the scorecard to new data
- [`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
  : Write the deliverables
- [`scr_reasons()`](https://evandeilton.github.io/scorecraft/reference/scr_reasons.md)
  : Reason codes: the variables that took the most points from each row
- [`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
  : Production SQL

## Metrics

- [`scr_iv()`](https://evandeilton.github.io/scorecraft/reference/scr_iv.md)
  : Information Value of any grouping
- [`scr_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_metrics.md)
  : AUC, KS and Gini of a score, with a bootstrap confidence interval
- [`scr_psi()`](https://evandeilton.github.io/scorecraft/reference/scr_psi.md)
  : Population stability index, with the fixed and the
  sample-size-adjusted threshold

## Portfolio and database

- [`scr_compare()`](https://evandeilton.github.io/scorecraft/reference/scr_compare.md)
  : Compare runs across targets
- [`scr_core()`](https://evandeilton.github.io/scorecraft/reference/scr_core.md)
  : Variables that cross several targets
- [`print(`*`<scr_runset>`*`)`](https://evandeilton.github.io/scorecraft/reference/scr_runset.md)
  : Set of runs, one per target
- [`scr_connect()`](https://evandeilton.github.io/scorecraft/reference/scr_connect.md)
  : Connect to a database (ODBC DSN or any DBI driver)
- [`scr_fetch()`](https://evandeilton.github.io/scorecraft/reference/scr_fetch.md)
  : Fetch a table with reproducible server-side sampling

## IRB parameters and the default definition

Parameter tables by framework preset, the default engine and default
rates by cohort.

- [`scr_default()`](https://evandeilton.github.io/scorecraft/reference/scr_default.md)
  : Build the default flag from a monthly panel
- [`scr_default_rate()`](https://evandeilton.github.io/scorecraft/reference/scr_default_rate.md)
  : One-year default rates by cohort and the long-run average
- [`scr_irb_params()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_params.md)
  : IRB parameter tables by framework preset

## PD calibration and rating grades

- [`predict(`*`<scr_grades>`*`)`](https://evandeilton.github.io/scorecraft/reference/predict.scr_grades.md)
  : Grade a score vector with the cut points of an scr_grades object
- [`predict(`*`<scr_pd>`*`)`](https://evandeilton.github.io/scorecraft/reference/predict.scr_pd.md)
  : Predict grade and PD from an scr_pd object
- [`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md)
  : Calibrate the alignment to a central tendency
- [`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md)
  : Rating grades on the score
- [`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md)
  : Master scale of PD grades
- [`scr_migration()`](https://evandeilton.github.io/scorecraft/reference/scr_migration.md)
  : Migration matrix between two rating dates
- [`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md)
  : Margin of conservatism, by category
- [`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md)
  : The PD model: grades, margin of conservatism and the floor
- [`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md)
  : One-factor bridge between point-in-time and through-the-cycle PD
- [`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md)
  : Validate a PD model on a cohort panel

## LGD

Workout loss given default, two-stage model, pools, downturn, floors and
in-default estimates.

- [`scr_elbe()`](https://evandeilton.github.io/scorecraft/reference/scr_elbe.md)
  : ELBE and in-default LGD on a grid of months since default
- [`scr_lgd()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd.md)
  : Two-stage LGD model and pools on the reference data set
- [`scr_lgd_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_downturn.md)
  : Downturn LGD per pool
- [`scr_lgd_floor()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_floor.md)
  : Input floor on the downturn LGD per pool
- [`scr_lgd_pools()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_pools.md)
  : LGD pools from the predicted LGD
- [`scr_lgd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_lgd_validate.md)
  : Validation battery of an LGD model
- [`scr_workout()`](https://evandeilton.github.io/scorecraft/reference/scr_workout.md)
  : Workout LGD: the reference data set from default events and cash
  flows

## EAD and credit conversion factors

- [`scr_bin_continuous()`](https://evandeilton.github.io/scorecraft/reference/scr_bin_continuous.md)
  : Bin drivers against a continuous target (LGD, CCF)
- [`scr_ead()`](https://evandeilton.github.io/scorecraft/reference/scr_ead.md)
  : Estimate CCF pools from the reference data set
- [`scr_ead_data()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_data.md)
  : Build the realised-CCF reference data set from facility snapshots
- [`scr_ead_downturn()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_downturn.md)
  : Downturn CCF per pool
- [`scr_ead_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_ead_validate.md)
  : Validate CCF pools: calibration, discrimination, back-testing and
  stability

## Expected loss, capital and ECL

- [`scr_capital()`](https://evandeilton.github.io/scorecraft/reference/scr_capital.md)
  : Expected loss, risk-weighted assets and capital of a portfolio
- [`scr_ecl()`](https://evandeilton.github.io/scorecraft/reference/scr_ecl.md)
  : Expected credit loss with stage allocation
- [`scr_el()`](https://evandeilton.github.io/scorecraft/reference/scr_el.md)
  : Expected loss per exposure
- [`scr_irb_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_rw.md)
  : IRB risk weight of one or many exposures
- [`scr_pd_stress()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_stress.md)
  : Stressed PD of the one-factor model
- [`scr_sa_rw()`](https://evandeilton.github.io/scorecraft/reference/scr_sa_rw.md)
  : Standardised risk weight of an exposure

## Data

- [`scr_demo`](https://evandeilton.github.io/scorecraft/reference/scr_demo.md)
  : Synthetic example data

- [`scr_demo_ead`](https://evandeilton.github.io/scorecraft/reference/scr_demo_ead.md)
  : Synthetic monthly facility snapshots for the EAD/CCF module

- [`scr_demo_lgd`](https://evandeilton.github.io/scorecraft/reference/scr_demo_lgd.md)
  : Synthetic default events for the workout LGD examples

- [`scr_demo_lgd_cashflows`](https://evandeilton.github.io/scorecraft/reference/scr_demo_lgd_cashflows.md)
  :

  Synthetic post-default cash flows of `scr_demo_lgd`

- [`scr_demo_panel`](https://evandeilton.github.io/scorecraft/reference/scr_demo_panel.md)
  : Synthetic monthly panel for the default engine and PD calibration

- [`scr_demo_portfolio`](https://evandeilton.github.io/scorecraft/reference/scr_demo_portfolio.md)
  : Synthetic exposure snapshot for expected loss, capital and ECL

- [`scr_demo_rates`](https://evandeilton.github.io/scorecraft/reference/scr_demo_rates.md)
  : Synthetic monthly reference rate series
