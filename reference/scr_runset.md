# Set of runs, one per target

Object returned by
[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md):
a named list of `scr_result`, plus the errors of the targets that
failed. Use
[`scr_compare()`](https://evandeilton.github.io/scorecraft/reference/scr_compare.md)
for the comparison table and
[`scr_core()`](https://evandeilton.github.io/scorecraft/reference/scr_core.md)
for the variables that cross several targets.

## Usage

``` r
# S3 method for class 'scr_runset'
print(x, ...)
```

## Arguments

- x:

  An `scr_runset` object.

- ...:

  Ignored.

## Value

`x`, invisibly.

## See also

Other portfolio:
[`scr_compare()`](https://evandeilton.github.io/scorecraft/reference/scr_compare.md),
[`scr_core()`](https://evandeilton.github.io/scorecraft/reference/scr_core.md),
[`scr_run()`](https://evandeilton.github.io/scorecraft/reference/scr_run.md)
