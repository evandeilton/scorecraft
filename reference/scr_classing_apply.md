# Commit the lab into a new selection result

Returns a new `scr_result` in which the accepted manual entries replace
the optimal ones inside `fit` (the automatic fit is frozen as
`fit_auto`), the screening and hold-out rows of those variables are
recomputed with the very same pipeline functions, the final shortlist is
the one implied by
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
and the funnel, gains, SQL and summary are rebuilt with a `provenance`
column.
[`scr_selected()`](https://evandeilton.github.io/scorecraft/reference/scr_selected.md)
on the result returns the final list (`which = "consensus"` still gives
the automatic one). The ledger travels with the result and into
[`scr_scorecard()`](https://evandeilton.github.io/scorecraft/reference/scr_scorecard.md)
and
[`scr_export()`](https://evandeilton.github.io/scorecraft/reference/scr_export.md).
The input result is not modified.

## Usage

``` r
scr_classing_apply(lab)
```

## Arguments

- lab:

  An object from
  [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md).

## Value

An `scr_result` with a `lab` component (`ledger`, `spec`, `shortlist`,
`source`).

## See also

[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
for a complete session, from lab to scorecard.

Other classing:
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
[`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md),
[`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md),
[`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md),
[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md),
[`scr_decisions()`](https://evandeilton.github.io/scorecraft/reference/scr_decisions.md)
