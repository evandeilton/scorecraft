# Propose manual bins for a variable

Exactly one of `breaks`, `groups`, `merge`, `split` or `reset` per call;
`missing_to` and `other_to` compose with a categorical instruction. The
instruction is resolved against the current bins into an absolute
specification, the WOE is refitted on the training rows, the bins are
applied frozen to the hold-out, and the comparison against the optimal
bins is printed. The proposal is a value: nothing changes in the lab
until
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md).

## Usage

``` r
scr_classing_propose(
  lab,
  variable,
  breaks = NULL,
  groups = NULL,
  merge = NULL,
  split = NULL,
  missing_to = NULL,
  other_to = NULL,
  reset = FALSE
)
```

## Arguments

- lab:

  An object from
  [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md).

- variable:

  A variable of the lab.

- breaks:

  Numeric: interior cut points, `(-Inf, b1], (b1, b2], ...`.

- groups:

  Categorical: a list of character vectors, one per bin; names are
  display labels. Every training category must be assigned, or
  `other_to` must name the catch-all bin.

- merge:

  Bin ids to merge (adjacent for numerics).

- split:

  `c(id, at)`: split numeric bin `id` at `at`.

- missing_to:

  Categorical: fold the `"MISSING"` category into this bin.

- other_to:

  Categorical: the bin that receives every training category not listed
  in `groups`.

- reset:

  `TRUE` proposes a return to the optimal bins.

## Value

An `scr_classing_proposal` with `id`, `variable`, `instruction` (the
resolved instruction as text), `entry` (the hand-built bins), `checks`,
`optimal` (the checks of the optimal bins), `compare`, `verdict`
(`ACCEPTABLE`, `REVIEW` or `BLOCKED`), `warnings` and `blocking`.

## See also

[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md)
for a complete session, from lab to scorecard.

Other classing:
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md),
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
[`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md),
[`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md),
[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md),
[`scr_decisions()`](https://evandeilton.github.io/scorecraft/reference/scr_decisions.md)
