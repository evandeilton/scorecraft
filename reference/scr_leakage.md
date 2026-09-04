# Leakage and suspicious-strength audit

Separates what the pipeline failed for excessive strength
(`IV_SUSPICIOUS`, `DEGENERATE_BIN`) from what it admitted but deserves a
second look (IV above `config$iv_suspect`). A bin with no events or no
non-events is the symptom with no innocent explanation: the variable
determines the outcome on part of the population.

## Usage

``` r
scr_leakage(x, threshold = NULL)
```

## Arguments

- x:

  An object from
  [`scr_select()`](https://evandeilton.github.io/scorecraft/reference/scr_select.md).

- threshold:

  Warning threshold. `NULL` uses `config$iv_suspect`.

## Value

An `scr_leakage` object (a list with `barred`, `degenerate`,
`approved_suspect`), with a print method.

## See also

Other accessors:
[`scr_funnel()`](https://evandeilton.github.io/scorecraft/reference/scr_funnel.md),
[`scr_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_gains.md),
[`scr_result`](https://evandeilton.github.io/scorecraft/reference/scr_result.md),
[`scr_score_gains()`](https://evandeilton.github.io/scorecraft/reference/scr_score_gains.md),
[`scr_score_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_score_metrics.md),
[`scr_selected()`](https://evandeilton.github.io/scorecraft/reference/scr_selected.md)

## Examples

``` r
cfg <- scr_config(verbose = FALSE, nthread = 1, use_ranger = FALSE,
                  xgb_rounds = 60, n_boot = 20)
res <- scr_select(scr_demo, "default", config = cfg, drop = "id",
                  date_col = "ref_date")
scr_leakage(res)
#> <scr_leakage> target "default"
#>   admission ceiling (iv_max): 1 | warning threshold: 0.50
#> 
#> Barred for IV above the ceiling: 0
#> 
#> Approved with IV >= 0.50: 0 of 12
```
