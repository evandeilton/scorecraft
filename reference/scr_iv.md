# Information Value of any grouping

Laplace smoothing by default. It is not cosmetic: without it, a
single-class group (a normal situation in a small sentinel population)
yields `Inf` and contaminates any ordering that depends on the IV.

## Usage

``` r
scr_iv(g, y, laplace = 0.5)
```

## Arguments

- g:

  Group vector (any coercible type; `NA` is ignored).

- y:

  0/1 outcome vector.

- laplace:

  Smoothing constant added to each count. `0` switches it off.

## Value

Total IV, a scalar. Zero when fewer than two groups are populated.

## Details

Implemented with [`tabulate()`](https://rdrr.io/r/base/tabulate.html) on
integer codes rather than `data.table` aggregation: this function is
called once per candidate variable, hundreds of times per run, and the
fixed cost dominated the triage.

## See also

Other metrics:
[`scr_metrics()`](https://evandeilton.github.io/scorecraft/reference/scr_metrics.md),
[`scr_psi()`](https://evandeilton.github.io/scorecraft/reference/scr_psi.md)

## Examples

``` r
set.seed(1)
y <- stats::rbinom(1000, 1, 0.3)
g <- ifelse(stats::runif(1000) < 0.5 + 0.3 * y, "A", "B")
scr_iv(g, y)
#> [1] 0.3450935
```
