# Accept or discard a proposal

`reason` is mandatory. Accepting replaces the variable's current bins;
the previous accepted proposal is marked `superseded`. A `BLOCKED`
proposal needs `override = TRUE`, and the override is itself a ledger
row.

## Usage

``` r
scr_classing_accept(lab, proposal, reason, override = FALSE)

scr_classing_discard(lab, proposal, reason)
```

## Arguments

- lab:

  An object from
  [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md).

- proposal:

  An object from
  [`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md).

- reason:

  Free text, at least 5 characters.

- override:

  Accept a `BLOCKED` proposal.

## Value

The updated lab, invisibly.

## See also

Other classing:
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md),
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
[`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md),
[`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md),
[`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md),
[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md),
[`scr_decisions()`](https://evandeilton.github.io/scorecraft/reference/scr_decisions.md)
