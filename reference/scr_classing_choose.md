# Choose the final variable list manually

The final list is `(consensus shortlist + force) - drop`, then
intersected with `keep` when given. `force` is allowed only for
variables that reached binning; a variable failed for `IV_SUSPICIOUS`
(the leakage ceiling) and a derived `__sp` flag under
`allow_derived_final = FALSE` are refused unless `override = TRUE`.
`reason` is one string for every variable named, or a character vector
named by variable.

## Usage

``` r
scr_classing_choose(
  lab,
  keep = NULL,
  drop = NULL,
  force = NULL,
  reason = NULL,
  override = FALSE
)
```

## Arguments

- lab:

  An object from
  [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md).

- keep:

  Variables to keep (restricts the final list).

- drop:

  Variables to remove from the final list.

- force:

  Variables to add to the final list.

- reason:

  Mandatory when `drop` or `force` is given.

- override:

  Allow a refused `force`.

## Value

The updated lab, invisibly.

## See also

Other classing:
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md),
[`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md),
[`scr_classing_spec()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_spec.md),
[`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md),
[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md),
[`scr_decisions()`](https://evandeilton.github.io/scorecraft/reference/scr_decisions.md)
