# The classing specification as a long table (and its file round trip)

One row per bin of every variable in the lab, optimal and manual, with
the authoritative columns a reviewer may edit (`lower`/`upper` for
numerics, `categories`/`is_other` for categoricals, `reason`) and
context columns that are regenerated on read. Open ends are written as
`NA`. `scr_classing_read()` validates a file back into a spec and
`scr_classing_import()` turns every variable whose bins differ from the
lab's current ones into a proposal, so a spreadsheet edit never enters
silently.

## Usage

``` r
scr_classing_spec(lab, file = NULL)

scr_classing_read(file, sep = "%;%")

scr_classing_import(lab, file)
```

## Arguments

- lab:

  An object from
  [`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md),
  or an `scr_result` returned by
  [`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md).

- file:

  Optional `.csv` or `.xlsx` path to write the table to.

- sep:

  Bin separator used in `categories` (the configuration's
  `bin_separator`).

## Value

A `data.frame` of class `scr_classing_spec`.

`scr_classing_import()` returns a named list of proposals (one per
variable whose bins differ from the lab's current ones), each to be
accepted or discarded.

## See also

Other classing:
[`scr_classing_accept()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_accept.md),
[`scr_classing_apply()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_apply.md),
[`scr_classing_choose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_choose.md),
[`scr_classing_propose()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_propose.md),
[`scr_classing_view()`](https://evandeilton.github.io/scorecraft/reference/scr_classing_view.md),
[`scr_coarse_classing()`](https://evandeilton.github.io/scorecraft/reference/scr_coarse_classing.md),
[`scr_decisions()`](https://evandeilton.github.io/scorecraft/reference/scr_decisions.md)
