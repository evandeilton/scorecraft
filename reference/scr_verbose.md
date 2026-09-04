# Switch progress messages on or off

Large tables take tens of minutes, and the pipeline reports every stage
as it runs: stage name, input and output counts, elapsed time. Messages
go through [`message()`](https://rdrr.io/r/base/message.html) as single
lines, with no progress bar that redraws itself, so that a scheduled job
(`Rscript` in batch) produces a readable log.
[`suppressMessages()`](https://rdrr.io/r/base/message.html) works too;
this function exists to switch them off persistently, without wrapping
every call. The `verbose` key of
[`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md)
has the same effect per run.

## Usage

``` r
scr_verbose(on = NULL)
```

## Arguments

- on:

  `TRUE` to switch on, `FALSE` to switch off, `NULL` (default) to query
  the current state only.

## Value

The verbosity state in force *before* the call, invisibly, so that
`old <- scr_verbose(FALSE); ...; scr_verbose(old)` restores it.

## See also

Other configuration:
[`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md),
[`scr_config_keys()`](https://evandeilton.github.io/scorecraft/reference/scr_config_keys.md),
[`scr_presets()`](https://evandeilton.github.io/scorecraft/reference/scr_presets.md)

## Examples

``` r
old <- scr_verbose(FALSE)   # silence, keeping the previous state
scr_verbose(old)            # restore
scr_verbose()               # query
```
