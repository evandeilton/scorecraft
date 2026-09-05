# Decision ledger of a lab, a result or a scorecard

Returns the append-only ledger of manual decisions: every proposal
accepted, discarded or superseded, every forced or dropped variable and
every override, each with its reason.

## Usage

``` r
scr_decisions(x)
```

## Arguments

- x:

  An `scr_classing` lab, an `scr_result` from
  [`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md)
  or an `scr_scorecard` fitted on one.

## Value

A `data.table`, one row per decision (append-only), or an empty one when
no manual decision exists.

## See also

[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
for a complete session, from lab to scorecard.

Other classing:
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md),
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
[`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md),
[`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md),
[`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md),
[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
