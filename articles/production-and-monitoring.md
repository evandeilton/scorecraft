# From database to production: fetching, cut-off strategy, SQL equivalence, monitoring and deliverables

The introductory vignette walks the modelling pipeline on the bundled
`scr_demo` table. This one covers what surrounds it in a real
deployment: pulling the development table out of a database with
server-side sampling, choosing a cut-off and a band policy, moving the
scorecard into the database as SQL and proving that the SQL gives the
same numbers as R, watching the scorecard drift over time, and packaging
the deliverables for a validator.

Everything below runs on `scr_demo`, which carries the defects real data
has (sentinel `-999`, missing values, a column that degrades in the last
period) so that each stage has something to show. The configuration is
the fast one used by the examples: one thread, two consensus voters, a
short boosting schedule and a small bootstrap.

``` r

library(scorecraft)
library(data.table)
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  use_lightgbm = FALSE, xgb_rounds = 60, n_boot = 20)
```

## 1. Fetching the development table from a database

In production the table lives in a warehouse, not in a CSV.
[`scr_connect()`](https://evandeilton.github.io/scorecraft/reference/scr_connect.md)
opens a DBI connection: with a `dsn` it goes through ODBC (and forces
`bigint = "numeric"`, so that a BIGINT column is not mistaken for a
high-cardinality categorical); with a `driver` it accepts any DBI
driver, which is how the database path is exercised here without a DSN.

``` r

# a real deployment: an ODBC data source configured on the machine
con <- scr_connect("my_dsn", timeout = 30)
```

For the vignette we load `scr_demo` into an in-memory SQLite database.
SQLite has no date type, so `ref_date` is written as text; the column is
not a candidate and is only carried along.

``` r

con <- scr_connect(driver = RSQLite::SQLite(), dbname = ":memory:")
d <- scr_demo
d$ref_date <- as.character(d$ref_date)
DBI::dbWriteTable(con, "dtm", d)
DBI::dbListTables(con)
#> [1] "dtm"
```

### Server-side sampling

[`scr_fetch()`](https://evandeilton.github.io/scorecraft/reference/scr_fetch.md)
samples **on the server**. Pulling every row only to discard most of
them in R pays the network cost twice, so the sampling fraction becomes
a `WHERE` clause on a uniform random expression. The expression follows
the connection class: `rand(seed)` on Spark, Databricks and MySQL,
`random()` on PostgreSQL, Redshift and DuckDB, and an integer-modulo
expression on SQLite, whose `random()` returns a signed 64-bit integer
and cannot be seeded. `sample_expr` overrides the choice for a dialect
the package does not know. The query is echoed when verbose messages are
on.

``` r

half <- scr_fetch(con, "dtm", sample_frac = 0.5, seed = 42)
#> SQL: select * from dtm where ((abs(random()) % 1000000) / 1000000.0) <= 0.500000
class(half)
#> [1] "data.table" "data.frame"
nrow(half)
#> [1] 2113
```

`max_rows` is a memory guard rather than a second sampler. When it
binds, the function counts the table first, reduces the fraction on the
server so that the expected number of rows fits under the cap, and
reports the reduction:

``` r

capped <- scr_fetch(con, "dtm", max_rows = 1000)
#>   cap of 1,000 rows: fraction reduced from 1.0000 to 0.2381 (table has 4,200)
#> SQL: select * from dtm where ((abs(random()) % 1000000) / 1000000.0) <= 0.238095
nrow(capped)
#> [1] 1069
```

### Several targets straight from the connection

[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md)
chains fetch and selection for a list of targets. The table name accepts
a `{target}` placeholder for one-table-per-target layouts; without it
the same table serves every target. Sibling targets are removed from the
candidate list automatically, and a failure on one target is recorded in
the run set while the loop continues. Two details matter for what
follows:

- [`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md)
  records the table name in the configuration, so the SQL generated
  later already points at `dtm` rather than at the placeholder
  `your_table`;
- it has no `date_col` argument, so the split it performs is random by
  row. For an out-of-time split, fetch the table and call
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)
  with `date_col`, as in section 2.

``` r

rs <- scr_run(con, "dtm", targets = c("default", "churn"), config = cfg,
              drop = c("id", "ref_date", "default", "churn"))
#> 
#> ############### TARGET: default ###############
#> SQL: select * from dtm
#> 
#> ############### TARGET: churn ###############
#> SQL: select * from dtm
#> 
#> Done: 2 of 2 target(s) succeeded.
rs
#> <scr_runset> 2 target(s): 2 succeeded, 0 failed
#> 
#>   target           rows approved      AUC       KS
#>   default         4,200       13   0.7523   0.3891
#>   churn           4,200        8   0.7046   0.3048
scr_compare(rs)[, .(target, rows, approved, best_model, auc, auc_lo, auc_hi, ks)]
#>     target  rows approved best_model    auc auc_lo auc_hi     ks
#>     <char> <int>    <int>     <char>  <num>  <num>  <num>  <num>
#> 1: default  4200       13     glmnet 0.7523 0.7218 0.7852 0.3891
#> 2:   churn  4200        8     glmnet 0.7046 0.6710 0.7259 0.3048
rs$default$config$sql_table
#> [1] "dtm"
DBI::dbDisconnect(con)
```

## 2. Selection and scorecard with an out-of-time split

The rest of the vignette works on one target, `default`, with the split
cut by whole periods of `ref_date`: the last periods form the hold-out,
which is what the cut-off sweep, the monitoring and the vintage tables
need.

``` r

res <- scr_select(scr_demo, "default", config = cfg, drop = c("id", "churn"),
                  date_col = "ref_date")
res$split$cutoff
#> [1] "2026-05-01"
sc <- scr_scorecard(res)
sc
#> <scr_scorecard> target "default" | 12 variables | higher_is_safer
#>   scale: 600 points at odds 50:1 (safe:event), PDO 20 | alignment regression
#>   score = 491.1967 + -26.3189 * logit | base_points = 538
#>   train    n 2,800   AUC 0.7856 [0.7662, 0.8070]  KS 0.4411  Gini 0.5713
#>   holdout  n 1,400   AUC 0.7394 [0.7066, 0.7770]  KS 0.3889  Gini 0.4788
#>   score PSI (hold-out): 0.0069 - fixed: stable | adjusted (0.0181): stable
#> 
#> Points (first rows)
#>   vl_score_01                  (-Inf;33.360000]             -2.063      61
#>   vl_score_01                  (33.360000;38.150000]        -0.731      22
#>   vl_score_01                  (38.150000;44.240000]        -0.658      20
#>   vl_score_01                  (44.240000;48.060000]        -0.523      16
#>   vl_score_01                  (48.060000;63.940000]         0.040      -1
#>   vl_score_01                  (63.940000;72.610000]         0.704     -21
#>   vl_score_01                  (72.610000;+Inf]              0.996     -30
#>   vl_score_02                  (-Inf;40.880000]             -0.824      22
#>   ... (+56 rows)
```

## 3. Cut-off strategy

### The sweep

[`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md)
evaluates candidate cuts. The candidates are quantiles of the score **on
train**, and they are applied **frozen** to the hold-out: both samples
answer the same question at the same score, so a difference between them
measures the stability of the decision, not a difference in the sampling
of the cuts.

``` r

ct <- scr_cutoff(sc, n_cuts = 8)
ct
#> <scr_cutoff> target "default" | 8 cuts frozen on train | safe side: high score
#>        cut     %safe    ev.safe   ev.risky   ev.avoid       KS
#>      511.6     90.2%     12.19%     35.77%      24.1%    0.168
#>      525.6     80.0%     10.27%     31.43%      43.3%    0.273
#>      536.6     68.0%      8.09%     28.12%      62.1%    0.352
#>      546.0     55.6%      6.68%     24.32%      74.4%    0.351
#>      554.1     45.3%      5.21%     22.19%      83.7%    0.340
#>      563.8     32.6%      3.28%     19.94%      92.6%    0.295
#>      573.8     22.0%      3.57%     17.58%      94.6%    0.194
#>      588.0     12.1%      2.96%     16.08%      97.5%    0.112
```

How to read one row:

- `cut` is the score; the **safe side** is the high-score side under
  `higher_is_safer` (credit) and the low-score side under
  `higher_is_riskier` (fraud, propensity). The header of the print says
  which.
- `%safe` (`pct_safe`) is the approval rate at that cut; `ev.safe` and
  `ev.risky` are the event rates on each side.
- `ev.avoid` (`events_avoided_pct`) is the share of all events that fall
  on the risky side, the events the cut would decline;
  `nonevents_lost_pct`, in the table, is the share of good accounts
  declined with them.
- `KS` at the cut is the distance between those two shares. The cut with
  the largest KS separates the populations best, which is not the same
  as the cut that the business should choose.

The table has one row per sample and cut, so the frozen comparison is a
direct read:

``` r

ct$table[cut == ct$cuts[4],
         .(sample, cut, pct_safe, event_rate_safe, events_avoided_pct, ks_at_cut)]
#>     sample   cut  pct_safe event_rate_safe events_avoided_pct ks_at_cut
#>     <char> <num>     <num>           <num>              <num>     <num>
#> 1:   train   546 0.5560714      0.04881182          0.8095238 0.4263501
#> 2: holdout   546 0.5564286      0.06675225          0.7438424 0.3511941
```

### The strategy table

[`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md)
turns the bands (the deciles frozen on train, by default) into a policy
with an explicit economic reading. For each band it computes the
expected profit per account,

``` math
EP = (1 - p)\,\text{revenue\_good} - p\,\text{loss\_bad},
```

and the break-even event rate, where $`EP = 0`$, is
`revenue_good / (revenue_good + loss_bad)`. With a revenue of 1,080 per
good account and a loss of 4,500 per bad one, break-even is 19.35 %. The
automatic decision approves a band whose rate is below break-even, sends
to review a band up to 25 % above it and declines the rest; `decisions`
fixes the policy by hand when the business has one.

``` r

st <- scr_strategy(sc, revenue_good = 1080, loss_bad = 4500)
st
#> <scr_strategy> target "default" | sample holdout | break-even event rate: 19.35% (revenue 1080, loss 4500)
#>   band                       vol%    event decision     EP/acct       profit
#>   (590, Inf]                11.2%    3.18% approve       902.29       141660
#>   (577,590]                  8.9%    3.23% approve       900.00       111600
#>   (567,577]                  9.1%    3.91% approve       862.03       110340
#>   (558,567]                 10.6%    7.38% approve       668.05        99540
#>   (550,558]                 10.6%   12.16% approve       401.35        59400
#>   (542,550]                 10.8%   11.26% approve       451.79        68220
#>   (533,542]                 10.6%   17.45% approve       106.31        15840
#>   (524,533]                  9.9%   26.62% decline      -405.32       -56340
#>   (510,524]                  9.1%   27.34% decline      -445.78       -57060
#>   [-Inf,510]                 9.1%   35.43% decline      -897.17      -113940
st$breakeven
#> [1] 0.1935484
```

The reading that matters is the band **profitable at the margin**: the
lowest approved band carries an event rate above the portfolio average
yet still returns a positive expected profit per account, because the
revenue on its good accounts covers the loss on its bad ones. Declining
it would look prudent and cost money. The cumulative columns give the
portfolio result of approving everything down to a band:

``` r

st$table[, .(band, event_rate = round(event_rate, 4), decision,
             ep_per_account = round(ep_per_account, 1), cum_pct = round(cum_pct, 3),
             cum_event_rate = round(cum_event_rate, 4), cum_profit)]
#>           band event_rate decision ep_per_account cum_pct cum_event_rate
#>         <char>      <num>   <char>          <num>   <num>          <num>
#>  1: (590, Inf]     0.0318  approve          902.3   0.112         0.0318
#>  2:  (577,590]     0.0323  approve          900.0   0.201         0.0320
#>  3:  (567,577]     0.0391  approve          862.0   0.292         0.0342
#>  4:  (558,567]     0.0738  approve          668.1   0.399         0.0448
#>  5:  (550,558]     0.1216  approve          401.4   0.504         0.0609
#>  6:  (542,550]     0.1126  approve          451.8   0.612         0.0700
#>  7:  (533,542]     0.1745  approve          106.3   0.719         0.0855
#>  8:  (524,533]     0.2662  decline         -405.3   0.818         0.1074
#>  9:  (510,524]     0.2734  decline         -445.8   0.909         0.1241
#> 10: [-Inf,510]     0.3543  decline         -897.2   1.000         0.1450
#>     cum_profit
#>          <num>
#>  1:     141660
#>  2:     253260
#>  3:     363600
#>  4:     463140
#>  5:     522540
#>  6:     590760
#>  7:     606600
#>  8:     550260
#>  9:     493200
#> 10:     379260
```

### Honest reject inference

A scorecard is fitted on accounts that were accepted and therefore have
an outcome.
[`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md)
refuses to fabricate one number for the accounts that have none. Instead
it declares the **population scope**, measures the **coverage per band**
and reports a **sensitivity band**: the event rate each band, and the
total, would have if the population without an outcome were 2, 4 or 8
times worse than the observed one. Without a through-the-door
population, the scope is the development sample and the band is flat:

``` r

rj <- scr_reject(sc)
rj
#> <scr_reject> target "default" | multipliers 2x, 4x, 8x
#>   The scorecard describes the population WITH an observed outcome. No extrapolation to rejects was made; the sensitivity band shows the effect of declared assumptions, not an inferred number.
#>   observed event rate: 14.50%
#>   implied rate if the population without outcome is 2x worse: 14.50%
#>   implied rate if the population without outcome is 4x worse: 14.50%
#>   implied rate if the population without outcome is 8x worse: 14.50%
#>   bands with weak coverage: (590, Inf] (few_events), (577,590] (few_events), (567,577] (few_events), (558,567] (few_events), (550,558] (few_events), (542,550] (few_events), (533,542] (few_events)
```

With a through-the-door population, the `accepted` flag marks the rows
whose outcome is known. Here `scr_demo` plays the through-the-door
population and only the hold-out rows are treated as accepted, so two
thirds of the population enter through the sensitivity band alone:

``` r

acc <- seq_len(nrow(scr_demo)) %in% res$split$holdout_idx
rj2 <- scr_reject(sc, population = scr_demo, accepted = acc)
rj2
#> <scr_reject> target "default" | multipliers 2x, 4x, 8x
#>   The full population has 4,200 rows, of which 1,400 (33.3%) have an observed outcome. The rest enter only the sensitivity band, under declared multipliers.
#>   observed event rate: 14.50%
#>   implied rate if the population without outcome is 2x worse: 24.56%
#>   implied rate if the population without outcome is 4x worse: 40.45%
#>   implied rate if the population without outcome is 8x worse: 53.43%
#>   bands with weak coverage: (590, Inf] (few_events), (577,590] (few_events), (567,577] (few_events), (558,567] (few_events), (550,558] (few_events), (542,550] (few_events), (533,542] (few_events)
rj2$coverage
#>           band n_dev events_dev   rate_dev n_pop n_unknown  coverage
#>         <char> <int>      <int>      <num> <int>     <int>     <num>
#>  1: (590, Inf]   157          5 0.03184713   437       280 0.3592677
#>  2:  (577,590]   124          4 0.03225806   404       280 0.3069307
#>  3:  (567,577]   128          5 0.03906250   408       280 0.3137255
#>  4:  (558,567]   149         11 0.07382550   429       280 0.3473193
#>  5:  (550,558]   148         18 0.12162162   428       280 0.3457944
#>  6:  (542,550]   151         17 0.11258278   431       280 0.3503480
#>  7:  (533,542]   149         26 0.17449664   429       280 0.3473193
#>  8:  (524,533]   139         37 0.26618705   419       280 0.3317422
#>  9:  (510,524]   128         35 0.27343750   408       280 0.3137255
#> 10: [-Inf,510]   127         45 0.35433071   407       280 0.3120393
#>     coverage_flag
#>            <char>
#>  1:    few_events
#>  2:    few_events
#>  3:    few_events
#>  4:    few_events
#>  5:    few_events
#>  6:    few_events
#>  7:    few_events
#>  8:            ok
#>  9:            ok
#> 10:            ok
rj2$sensitivity[band == "TOTAL", .(multiplier, n_dev, events_dev, rate_dev,
                                   n_unknown, events_implied, rate_implied)]
#>    multiplier n_dev events_dev rate_dev n_unknown events_implied rate_implied
#>         <num> <int>      <int>    <num>     <int>          <num>        <num>
#> 1:          2  1400        203    0.145      2800       1031.604    0.2456199
#> 2:          4  1400        203    0.145      2800       1698.978    0.4045185
#> 3:          8  1400        203    0.145      2800       2244.083    0.5343054
```

How to read it:

- `coverage` is the share of the band’s population that has an outcome;
  `coverage_flag` marks bands with no outcome at all (`no_outcome`) and
  bands with fewer than 30 events (`few_events`), where the observed
  rate is itself fragile. The safe bands are flagged here because a 14 %
  event rate leaves few events at the top of the score.
- `rate_unknown` is the assumed rate of the unknown rows in a band
  (`rate_dev` times the multiplier, capped at one), `events_implied`
  adds the implied events to the observed ones, and `rate_implied` is
  the resulting rate over the whole band.
- The `TOTAL` rows are the headline: the observed rate and what it
  becomes under each declared multiplier. The analyst reads the band and
  states the assumption; the package does not choose it.

## 4. Scoring in R

[`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
materialises in R exactly what the production SQL does: the frozen
pre-processing (training median for missing and sentinel values,
`"MISSING"` for absent categories), the frozen bins and the points.
Nothing is refitted. `what = "all"` returns the logit, the model
probability, the exact score (`a + b * logit`), the whole-points score
and, per variable, the points and the WOE.

``` r

new <- head(scr_demo, 5)
scored <- scr_apply(sc, new, what = "all")
scored[, .(link, prob, score, score_points, vl_score_01_points, vl_score_01_woe)]
#>         link       prob    score score_points vl_score_01_points
#>        <num>      <num>    <num>        <num>              <num>
#> 1: -2.102534 0.10885077 546.5330          546                -21
#> 2: -2.702712 0.06281350 562.3290          562                 20
#> 3: -2.634040 0.06697956 560.5217          559                 -1
#> 4: -0.602874 0.35368644 507.0636          507                 -1
#> 5: -1.731277 0.15042432 536.7619          536                 -1
#>    vl_score_01_woe
#>              <num>
#> 1:      0.70394095
#> 2:     -0.65810792
#> 3:      0.03978629
#> 4:      0.03978629
#> 5:      0.03978629
```

[`scr_reasons()`](https://evandeilton.github.io/scorecraft/reference/scr_reasons.md)
gives the adverse-action reasons: the variables whose points fell
furthest below their reference, the mean points of the variable on the
training population by default (`reference = "max"` uses the best bin
instead). It only exists for the additive scorecard.

``` r

scr_reasons(sc, new, k = 3)
#>       reason_1 shortfall_1    reason_2 shortfall_2    reason_3 shortfall_3
#>         <char>       <num>      <char>       <num>      <char>       <num>
#> 1: vl_score_01   25.197857 vl_score_02   17.828571 vl_score_05    9.054286
#> 2: vl_score_04    9.052857   vl_tardio    5.716071    ds_canal    5.387857
#> 3:   vl_tardio   13.716071 vl_score_07    7.605357    ds_canal    5.387857
#> 4:   ds_regiao   13.807143    ds_faixa   11.932500 vl_score_02   11.828571
#> 5: vl_score_02   17.828571 vl_score_05    9.054286 vl_score_01    5.197857
```

## 5. Production SQL, and proof that it matches R

### What is generated

`scr_sql(res)` emits the WOE transformation of the approved variables in
two blocks: a CTE `base_scr` that reproduces the pre-processing
(imputation by the **training** median, special-population flags,
`COALESCE` of the categorical missing) and the WOE/BIN `CASE`
expressions built from the authoritative cut points at full precision.
Without the first block the WOE would be applied to data different from
what was binned. The vector returned by
[`scr_sql()`](https://evandeilton.github.io/scorecraft/reference/scr_sql.md)
keeps each block as it was emitted, so the lines are split here to show
a window; `file` writes the complete script.

``` r

sql_woe <- unlist(strsplit(scr_sql(res), "\n", fixed = TRUE))
cat(head(sql_woe, 24), sep = "\n")
#> -- =============================================================
#> -- scorecraft | target: default | 12 approved variables | dialect: ansi
#> -- Generated on 2026-09-04 13:05:38
#> -- Block 1 (CTE base_scr): Stage 1 pre-processing - imputation of missing
#> --   and sentinel values by the TRAINING median, special-population flags.
#> -- Block 2: WOE/BIN transformation emitted by OptimalBinningWoE::obwoe_sql().
#> -- =============================================================
#> WITH base_scr AS (
#>   SELECT
#>     CASE WHEN vl_score_01 IS NULL OR vl_score_01 IN (-999) THEN 52.75 ELSE vl_score_01 END AS vl_score_01,
#>     CASE WHEN vl_score_02 IS NULL OR vl_score_02 IN (-999) THEN 55.98 ELSE vl_score_02 END AS vl_score_02,
#>     CASE WHEN vl_score_04 IS NULL OR vl_score_04 IN (-999) THEN 61.835 ELSE vl_score_04 END AS vl_score_04,
#>     COALESCE(ds_faixa, 'MISSING') AS ds_faixa,
#>     CASE WHEN vl_tardio IS NULL OR vl_tardio IN (-999) THEN 0.0065000000000000006 ELSE vl_tardio END AS vl_tardio,
#>     COALESCE(ds_regiao, 'MISSING') AS ds_regiao,
#>     CASE WHEN vl_score_06 IS NULL OR vl_score_06 IN (-999) THEN 67.815 ELSE vl_score_06 END AS vl_score_06,
#>     CASE WHEN vl_score_07 IS NULL OR vl_score_07 IN (-999) THEN 71.16 ELSE vl_score_07 END AS vl_score_07,
#>     CASE WHEN vl_score_05 IS NULL OR vl_score_05 IN (-999) THEN 65.425000000000011 ELSE vl_score_05 END AS vl_score_05,
#>     COALESCE(ds_canal, 'MISSING') AS ds_canal,
#>     CASE WHEN vl_hist_04 IS NULL OR vl_hist_04 IN (-999) THEN 25 ELSE vl_hist_04 END AS vl_hist_04,
#>     CASE WHEN vl_score_10 IS NULL OR vl_score_10 IN (-999) THEN 80 ELSE vl_score_10 END AS vl_score_10
#>   FROM your_table
#> )
#> -- ---------------------------------------------------------------
i <- grep("AS vl_score_01_bin", sql_woe, fixed = TRUE)
cat(sql_woe[(i + 1):(i + 11)], sep = "\n")
#> CASE
#>     WHEN vl_score_01 IS NULL THEN 0
#>     WHEN vl_score_01 <= 33.36 THEN -2.062535589601761
#>     WHEN vl_score_01 > 33.36 AND vl_score_01 <= 38.15 THEN -0.7310494649768657
#>     WHEN vl_score_01 > 38.15 AND vl_score_01 <= 44.24 THEN -0.658107921034498
#>     WHEN vl_score_01 > 44.24 AND vl_score_01 <= 48.06 THEN -0.5226120610523515
#>     WHEN vl_score_01 > 48.06 AND vl_score_01 <= 63.94 THEN 0.03978629403758501
#>     WHEN vl_score_01 > 63.94 AND vl_score_01 <= 72.61 THEN 0.703940947094186
#>     WHEN vl_score_01 > 72.61 THEN 0.99617148311361814
#>     ELSE 0
#> END AS vl_score_01_woe,
```

`scr_sql(sc)` adds a third block for the scorecard: a CTE `woe_scr` with
the WOE and the bin index, then the final `SELECT` with `score` (exact,
from the WOE), one `<variable>_points` column per variable and
`score_points` (the base points plus the whole points per bin). `table`
and `dialect` override the configuration; the dialects available are
`ansi`, `databricks`, `spark`, `hive`, `mysql`, `mariadb`, `sqlserver`,
`bigquery`, `postgres`, `oracle`, `snowflake`, `redshift`, `duckdb` and
`sqlite`. `file` writes the script to disk.

``` r

sql_sc <- unlist(strsplit(scr_sql(sc, table = "prd.customers", dialect = "databricks"),
                          "\n", fixed = TRUE))
cat(head(sql_sc, 12), sep = "\n")
#> -- =============================================================
#> -- scorecraft | scorecard of target: default | 12 variables | dialect: databricks
#> -- Generated on 2026-09-04 13:05:39
#> -- Scale: 600 points at odds 50:1 (safe:event), PDO 20 | higher_is_safer
#> -- score = 491.19665800103655 + -26.318891476654574 * logit | base_points = 538
#> -- Block 1 (CTE base_scr): pre-processing frozen on train.
#> -- Block 2 (CTE woe_scr): WOE and bin index, emitted by OptimalBinningWoE::obwoe_sql().
#> -- Block 3: exact score (from the WOE) and whole points (from the bin index).
#> -- =============================================================
#> WITH base_scr AS (
#>   SELECT
#>     CASE WHEN vl_score_01 IS NULL OR vl_score_01 IN (-999) THEN 52.75 ELSE vl_score_01 END AS vl_score_01,
# block 3: the exact score from the WOE columns ...
i <- max(which(sql_sc == "SELECT"))
cat(sql_sc[i:(i + 15)], sep = "\n")
#> SELECT
#>     538.30012744760336
#>       + -29.701043763446282 * vl_score_01_woe
#>       + -27.130718819754311 * vl_score_02_woe
#>       + -26.649286859941228 * vl_score_04_woe
#>       + -30.277321636127542 * ds_faixa_woe
#>       + -29.966768640958328 * vl_tardio_woe
#>       + -28.964890297230774 * ds_regiao_woe
#>       + -28.874743439251926 * vl_score_06_woe
#>       + -26.679330009797006 * vl_score_07_woe
#>       + -35.128873453122381 * vl_score_05_woe
#>       + -33.247622050806406 * ds_canal_woe
#>       + -30.803729315270584 * vl_hist_04_woe
#>       + -35.878212555936543 * vl_score_10_woe AS score,
#>     vl_score_01_points,
#>     vl_score_02_points,
# ... the whole points, and one of the CASE expressions behind them
cat(grep("AS score_points", sql_sc, value = TRUE), sep = "\n")
#>     538 + vl_score_01_points + vl_score_02_points + vl_score_04_points + ds_faixa_points + vl_tardio_points + ds_regiao_points + vl_score_06_points + vl_score_07_points + vl_score_05_points + ds_canal_points + vl_hist_04_points + vl_score_10_points AS score_points
cat(grep("AS vl_score_01_points", sql_sc, value = TRUE), sep = "\n")
#>       CASE vl_score_01_idx WHEN 1 THEN 61 WHEN 2 THEN 22 WHEN 3 THEN 20 WHEN 4 THEN 16 WHEN 5 THEN -1 WHEN 6 THEN -21 WHEN 7 THEN -30 ELSE 0 END AS vl_score_01_points,
```

### Equivalence, demonstrated

The claim that R and SQL agree is checked by the package tests; it is
also cheap to demonstrate. DuckDB runs in-process, accepts `scr_demo` as
is (dates included) and executes the `duckdb` dialect. The WOE from
`scr_sql(res)` is compared with `scr_apply(res)`, and the score, the
whole points and the WOE columns from `scr_sql(sc)` with
`scr_apply(sc)`.

``` r

con <- DBI::dbConnect(duckdb::duckdb(), config = list(threads = "1"))
DBI::dbWriteTable(con, "scr_demo", scr_demo)

# selection SQL: WOE and bin of the approved variables
got_woe <- DBI::dbGetQuery(con, paste(scr_sql(res, table = "scr_demo", dialect = "duckdb"),
                                      collapse = "\n"))
exp_woe <- scr_apply(res, scr_demo, what = "both")
woe_ok <- vapply(scr_selected(res), function(f)
  isTRUE(all.equal(got_woe[[paste0(f, "_woe")]], exp_woe[[paste0(f, "_woe")]])) &&
  identical(got_woe[[paste0(f, "_bin")]], exp_woe[[paste0(f, "_bin")]]), logical(1))
all(woe_ok)
#> [1] TRUE

# scorecard SQL: score, whole points and WOE
got_sc <- DBI::dbGetQuery(con, paste(scr_sql(sc, table = "scr_demo", dialect = "duckdb"),
                                     collapse = "\n"))
exp_sc <- scr_apply(sc, scr_demo, what = "all")
all.equal(got_sc$score, exp_sc$score)
#> [1] TRUE
all.equal(got_sc$score_points, exp_sc$score_points)
#> [1] TRUE
all(vapply(sc$features, function(f)
  isTRUE(all.equal(got_sc[[paste0(f, "_points")]], exp_sc[[paste0(f, "_points")]])), logical(1)))
#> [1] TRUE
DBI::dbDisconnect(con, shutdown = TRUE)
```

`score` agrees to floating-point precision, `score_points` and every
`<variable>_points` column agree exactly. The same check on SQLite,
whose arithmetic is less forgiving, is part of the test suite.

## 6. Monitoring

[`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md)
scores any new table with the frozen scorecard and recomputes, per
period of `date_col`, the score PSI against the training distribution
with frozen bands, the CSI of every variable with frozen bins together
with the signed points shift and, when the target is present, the
performance by vintage. It schedules nothing: the analyst calls it when
needed. Here the new data are `scr_demo` itself, whose first four
periods are the training vintages and the last two the hold-out.

``` r

mo <- scr_monitor(sc, scr_demo, date_col = "ref_date", target = "default", n_boot = 20)
mo
#> <scr_monitor> target "default" | 6 period(s)
#>   period              n      score      PSI fixed      critical adj.    
#>   2026-01-01        700      549.8   0.0083 stable       0.0302 stable  
#>   2026-02-01        700      550.3   0.0071 stable       0.0302 stable  
#>   2026-03-01        700      550.4   0.0084 stable       0.0302 stable  
#>   2026-04-01        700      550.7   0.0125 stable       0.0302 stable  
#>   2026-05-01        700      550.2   0.0284 stable       0.0302 stable  
#>   2026-06-01        700      552.3   0.0129 stable       0.0302 stable  
#>   largest points shifts (variable @ period):
#>     vl_tardio                    2026-06-01   CSI 0.4141  shift +1.89 pts
#>     vl_score_01                  2026-02-01   CSI 0.0039  shift -1.01 pts
#>     vl_score_04                  2026-02-01   CSI 0.0189  shift +0.80 pts
#>     vl_score_01                  2026-06-01   CSI 0.0209  shift -0.61 pts
#>     vl_hist_04                   2026-05-01   CSI 0.0183  shift +0.60 pts
#>   performance by vintage:
#>     2026-01-01   n 700     event  14.14%  AUC 0.8152 [0.7928, 0.8508]  KS 0.5069
#>     2026-02-01   n 700     event  14.57%  AUC 0.7997 [0.7587, 0.8363]  KS 0.4708
#>     2026-03-01   n 700     event  13.71%  AUC 0.7605 [0.7049, 0.7906]  KS 0.4487
#>     2026-04-01   n 700     event  14.57%  AUC 0.7644 [0.7097, 0.8061]  KS 0.4094
#>     2026-05-01   n 700     event  14.00%  AUC 0.7500 [0.7008, 0.7908]  KS 0.3904
#>     2026-06-01   n 700     event  15.00%  AUC 0.7318 [0.6903, 0.7583]  KS 0.3950
```

### The PSI timeline and its two thresholds

``` r

mo$psi
#>        period     n mean_score         psi flag_fixed   critical flag_adjusted
#>        <char> <int>      <num>       <num>     <char>      <num>        <char>
#> 1: 2026-01-01   700   549.8457 0.008300253     stable 0.03021246        stable
#> 2: 2026-02-01   700   550.2764 0.007138020     stable 0.03021246        stable
#> 3: 2026-03-01   700   550.4213 0.008386231     stable 0.03021246        stable
#> 4: 2026-04-01   700   550.6736 0.012474292     stable 0.03021246        stable
#> 5: 2026-05-01   700   550.1794 0.028352777     stable 0.03021246        stable
#> 6: 2026-06-01   700   552.3036 0.012863926     stable 0.03021246        stable
```

Every PSI carries **both** thresholds. `flag_fixed` uses the market
convention, 0.10 for a moderate shift and 0.25 for action, which has no
published authority behind it and ignores how many rows produced the
number. `critical` is the sample-size-adjusted critical value at level
`alpha`: under no shift, the PSI over $`B`$ bands computed from $`n`$
base and $`m`$ comparison rows behaves like $`(1/n + 1/m)`$ times a
chi-squared variable with $`B - 1`$ degrees of freedom (Yurdakul and
Naranjo, 2020), so the critical value is
$`(1/n + 1/m)\,\chi^2_{B-1,\,1-\alpha}`$. With 2,800 training rows, 700
rows per period and ten bands it is about 0.03: the fixed 0.10 would let
a real shift of that size pass, while on a very small period it would
flag noise. `flag_adjusted` is the verdict against `critical`; the two
flags are reported side by side and disagree exactly when the sample
size makes the fixed threshold misleading.

### The CSI and the signed points shift

The CSI applies the same statistic to each variable’s bin distribution
and gets the same pair of thresholds. It is unsigned, so it says that a
variable moved but not where the score went. `points_shift` fills that
gap: the change in bin shares weighted by the points of each bin, which
is the amount by which the variable moved the mean score, with its sign,
and it is additive across variables.

`vl_tardio` is built to degrade in the last period only, and the monitor
finds it: stable for five periods, then a CSI far above both thresholds
and the largest points shift of the run.

``` r

mo$csi[variable == "vl_tardio", .(period, n, csi, flag_fixed, critical, flag_adjusted, points_shift)]
#>        period     n         csi flag_fixed   critical flag_adjusted
#>        <char> <int>       <num>     <char>      <num>        <char>
#> 1: 2026-01-01   700 0.008873842     stable 0.02248498        stable
#> 2: 2026-02-01   700 0.011785610     stable 0.02248498        stable
#> 3: 2026-03-01   700 0.003511450     stable 0.02248498        stable
#> 4: 2026-04-01   700 0.003353860     stable 0.02248498        stable
#> 5: 2026-05-01   700 0.013563129     stable 0.02248498        stable
#> 6: 2026-06-01   700 0.414109814      shift 0.02248498         shift
#>    points_shift
#>           <num>
#> 1:  0.478214286
#> 2: -0.190357143
#> 3: -0.008928571
#> 4: -0.278928571
#> 5: -0.338928571
#> 6:  1.885357143
mo$csi[period == max(period)][order(-abs(points_shift))][1:5,
       .(variable, csi, flag_fixed, flag_adjusted, points_shift)]
#>       variable         csi flag_fixed flag_adjusted points_shift
#>         <char>       <num>     <char>        <char>        <num>
#> 1:   vl_tardio 0.414109814      shift         shift    1.8853571
#> 2: vl_score_01 0.020937580     stable        stable   -0.6107143
#> 3: vl_score_10 0.008143611     stable        stable    0.4417857
#> 4: vl_score_02 0.006988276     stable        stable   -0.4057143
#> 5:    ds_faixa 0.003471581     stable        stable   -0.3767857
```

### Performance by vintage

With the target present, each period gets its event rate and its AUC, KS
and Gini with a bootstrap interval. The first four vintages were used
for training, so their higher discrimination is expected; the comparison
that matters is between the hold-out vintages and the scorecard’s own
hold-out figures, and then between successive production months.

``` r

mo$vintage[, .(period, n, events, event_rate = round(event_rate, 4),
               auc = round(auc, 4), auc_lo = round(auc_lo, 4), auc_hi = round(auc_hi, 4),
               ks = round(ks, 4))]
#>        period     n events event_rate    auc auc_lo auc_hi     ks
#>        <char> <int>  <int>      <num>  <num>  <num>  <num>  <num>
#> 1: 2026-01-01   700     99     0.1414 0.8152 0.7928 0.8508 0.5069
#> 2: 2026-02-01   700    102     0.1457 0.7997 0.7587 0.8363 0.4708
#> 3: 2026-03-01   700     96     0.1371 0.7605 0.7049 0.7906 0.4487
#> 4: 2026-04-01   700    102     0.1457 0.7644 0.7097 0.8061 0.4094
#> 5: 2026-05-01   700     98     0.1400 0.7500 0.7008 0.7908 0.3904
#> 6: 2026-06-01   700    105     0.1500 0.7318 0.6903 0.7583 0.3950
```

`mo$plan` records the monitoring contract that was applied: both sets of
thresholds, `alpha`, the frozen score bands and the source of each
threshold. It is written to the strategy workbook.

## 7. Deliverables

[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
writes the deliverables to a directory. `stamp = FALSE` writes in place;
the default creates a timestamped subdirectory so that earlier runs are
never overwritten. For the scorecard, the cut-off, strategy, reject and
monitor objects computed above can be passed in so that the workbooks
carry exactly what was read in this session; otherwise they are
recomputed with defaults.

``` r

out <- file.path(tempdir(), "scorecraft-prod")
res <- scr_export(res, out, stamp = FALSE)
sc  <- scr_export(sc, out, stamp = FALSE, cutoff = ct, strategy = st, reject = rj2, monitor = mo)
basename(unlist(res$files))
#> [1] "selection_default.xlsx" "sql_woe_default.sql"    "summary_default.md"
basename(unlist(sc$files))
#> [1] "scorecard_default.xlsx"  "validation_default.xlsx"
#> [3] "strategy_default.xlsx"   "sql_score_default.sql"  
#> [5] "sql_woe_default.sql"
```

Four workbooks are produced between the two calls, plus the SQL scripts
and a Markdown summary:

- **`selection_default.xlsx`** (from the `scr_result`): `01_Funnel`,
  every input column with the stage it left at and why; `02_Gains`;
  `03_Screening`; `04_Holdout`, the revalidation with frozen bins;
  `05_Models`, `06_Votes` and `07_Consensus`; `08_Ledger`, the
  pre-processing decisions that the SQL reproduces; `09_Redundancy`;
  and, when a coarse-classing lab was applied, `10_Coarse_Classing` and
  `11_Decision_Ledger`.
- **`scorecard_default.xlsx`**: `Score_Summary` (scale, direction and
  `odds_orientation`), `Final_Scorecard` (the points table),
  `Coefficients`, `Sign_Check`, `Alignment` and `Alignment_Bands` (the
  log-odds regression behind the scale), `Model_Card`, and `Challenger`
  and `Swap_Set` when a challenger was fitted.
- **`validation_default.xlsx`**: `Score_Gains_Frozen`,
  `Variable_Gains_IV`, `Discrimination_CI`, `Stability_PSI_Timeline` and
  `Stability_CSI_Timeline` (the monitor tables above),
  `Stability_Variables`, `Calibration` and `Calibration_Bands`,
  `Performance_By_Vintage` and `Rank_Order_Diagnostics`.
- **`strategy_default.xlsx`**: `Population_Scope` and `Band_Coverage`
  from reject inference, `Cutoff_Sweep`, `Strategy_Bands`,
  `Reject_Sensitivity` and `Monitoring_Plan`.

`sql_woe_default.sql` and `sql_score_default.sql` hold the two SQL
scripts of section 5, and `summary_default.md` the executive summary of
the selection.

The writer is hardened for documents that leave the analyst’s hands.
Every sheet is sanitised first: factors and list columns become text,
and a cell starting with `=`, `+`, `-` or `@` is prefixed with an
apostrophe so that a spreadsheet cannot interpret it as a formula. The
workbook is written to a temporary file, reopened, and its sheet names
and row counts are verified against what was meant to be written before
it is renamed into place; a verification failure raises an error rather
than leaving a partial file. A sheet with nothing to report receives an
`availability` and `reason_code` row, never a fabricated zero.

## 8. Production checklist

Before the scorecard goes live:

1.  **Scope.** The population scope statement from
    [`scr_reject()`](https://evandeilton.github.io/scorecraft/reference/scr_reject.md)
    is written down next to the scorecard, with the coverage per band
    and the multiplier the business is prepared to defend.
2.  **Split.** The development split is out-of-time (`date_col` given to
    [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md)),
    and the hold-out performance in the model card is the figure quoted,
    not the training one.
3.  **Cut-off.** The cut and the band policy come from
    [`scr_cutoff()`](https://evandeilton.github.io/scorecraft/reference/scr_cutoff.md)
    and
    [`scr_strategy()`](https://evandeilton.github.io/scorecraft/reference/scr_strategy.md)
    with the revenue and loss figures the business signed off, and the
    marginal band was read rather than declined by instinct.
4.  **SQL.** The script in production is the one written by
    [`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md)
    for the target dialect, with `table` set to the real source; the
    pre-processing CTE was not edited by hand.
5.  **Equivalence.** The scored output of the production SQL was
    compared with
    [`scr_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_apply.md)
    on the same rows, as in section 5, after deployment and after any
    change to the source table.
6.  **Reason codes.**
    [`scr_reasons()`](https://evandeilton.github.io/scorecraft/reference/scr_reasons.md)
    is the source of adverse-action reasons, with the reference (`mean`
    or `max`) stated in the policy.
7.  **Monitoring contract.** `mo$plan` is filed with the deliverables:
    both PSI thresholds, `alpha`, the frozen bands and the minimum
    events per period below which no verdict is issued.
8.  **Cadence.**
    [`scr_monitor()`](https://evandeilton.github.io/scorecraft/reference/scr_monitor.md)
    runs on every new period; a score PSI above the adjusted critical
    value, a CSI shift with a material points shift, or a vintage AUC
    outside the development interval triggers a review before a refit.
9.  **Deliverables.** The four workbooks, the SQL and the summary are
    archived from a stamped export (`stamp = TRUE`), never overwritten.

## Reference

Yurdakul, B. and Naranjo, J. (2020). Statistical properties of the
population stability index. *Journal of Risk Model Validation*, 14(4),
89-100.
