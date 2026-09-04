# scorecraft: scorecard engine with alignment, cut-off strategy and production SQL

A professional scorecard is born of seven chained stages, and this
package exposes each of them as a function of its own, next to the
shortcut
[`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
that chains them for the common case:

## Details

1.  **Split**
    ([`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md)):
    train/hold-out by whole periods (out-of-time) before any supervised
    fit.

2.  **Triage**
    ([`scr_triage()`](https://evandeilton.github.io/scorecraft/reference/scr_triage.md)):
    structural filters, decomposition of sentinels and missing values,
    exact duplicates. The data leaves with no `NA`.

3.  **Binning and screening**
    ([`scr_bin()`](https://evandeilton.github.io/scorecraft/reference/scr_bin.md)):
    optimal bins parallelised by column, eight admission rules, hold-out
    revalidation with frozen bins, redundancy pruning.

4.  **Multi-strategy selection**
    ([`scr_model()`](https://evandeilton.github.io/scorecraft/reference/scr_model.md)):
    elastic net, boosting and random forest on the WOE space; consensus
    weighted by hold-out Gini.

5.  **Scorecard**
    ([`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)):
    logistic regression on the shortlist, sign check, points per bin, a
    tree challenger explicitly without points.

6.  **Alignment**
    ([`scr_align()`](https://evandeilton.github.io/scorecraft/reference/scr_align.md)):
    log-odds regression on the raw score composed with the PDO map, with
    `odds_orientation` recorded. Runs automatically inside
    [`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md).

7.  **Cut-off and strategy**
    ([`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md),
    [`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md),
    [`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md)):
    sweep with frozen cuts, bands with marginal expected profit, honest
    reject inference through a sensitivity band.

The deliverables
([`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md))
are the audit funnel, the gains tables, the production SQL
([`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md))
with R-SQL equivalence verified by test, and four `.xlsx` workbooks.
[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md)
recomputes PSI/CSI on new data, with both the fixed and the
sample-size-adjusted threshold, and never schedules anything by itself.

## Reading conventions

`objective` declares the vocabulary and the direction of the scale
(`"risk"`: more points, safer; `"propensity"`: more points, more likely)
and does **not** change what is modelled. `event_level` changes what is
modelled. Both are documented in
[`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md)
and
[`scr_split()`](https://evandeilton.github.io/scorecraft/reference/scr_split.md).

## See also

Useful links:

- <https://github.com/evandeilton/scorecraft>

- Report bugs at <https://github.com/evandeilton/scorecraft/issues>

## Author

**Maintainer**: Jose Evandeilton Lopes <evandeilton@gmail.com>
\[copyright holder\]

Authors:

- Jose Evandeilton Lopes <evandeilton@gmail.com> \[copyright holder\]
