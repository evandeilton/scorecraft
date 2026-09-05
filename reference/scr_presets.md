# Selection presets, side by side

Returns the funnel keys resolved per preset, to compare before choosing.
`target_min` and `iv_max` are shown for context; the presets leave them
unchanged, as they do every other configuration key.

## Usage

``` r
scr_presets()
```

## Value

A `data.frame` with one row per preset.

## See also

Other configuration:
[`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md),
[`scr_config_keys()`](https://evandeilton.github.io/scorecraft/reference/scr_config_keys.md),
[`scr_verbose()`](https://evandeilton.github.io/scorecraft/reference/scr_verbose.md)

## Examples

``` r
scr_presets()
#>       preset target_min target_max min_votes corr_cutoff iv_min iv_max
#> 1 aggressive         10         15         3         0.6   0.03      1
#> 2   moderate         10         25         2         0.7   0.02      1
#> 3       lazy         10         40         1         0.8   0.02      1
```
