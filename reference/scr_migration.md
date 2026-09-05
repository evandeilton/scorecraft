# Migration matrix between two rating dates

Counts `N_ij` of obligors in grade `i` at the first date and grade `j`
at the second, the row probabilities `p_ij`, the upper and lower matrix
weighted bandwidths \$\$MWB\_{up} = \frac{\sum\_{i\<j} \|i-j\|\\ N_i\\
p\_{ij}}{\sum_i \max(\|i-K\|, \|i-1\|)\\ N_i \sum\_{j\>i} p\_{ij}},\$\$
(and the mirror image for downgrades), the `z` statistic of every
off-diagonal cell against its neighbour closer to the diagonal (a
significantly positive value means the probability does not decay away
from the diagonal) and the mobility summary. Values of `grade_t1`
outside `1..K` count as `default`, `NA` as `closed`; both stay out of
the bandwidths.

## Usage

``` r
scr_migration(grade_t0, grade_t1, K = NULL)
```

## Arguments

- grade_t0, grade_t1:

  Integer grades at the two dates, same length.

- K:

  Number of grades; `NULL` uses the largest grade observed.

## Value

An object of class `scr_migration`: `matrix` (counts, `K` rows, `K + 2`
columns), `p` (row probabilities), `n` (row totals), `mwb_upper`,
`mwb_lower`, `z` (`K x K`), `n_significant` (cells with `z > 1.645`),
`mobility` (`share_stable`, `share_up`, `share_down`, `mean_distance`,
`share_default`, `share_closed`). Also `K`, the number of grades.

## See also

Other irb-pd:
[`predict.scr_grades()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_grades.md),
[`predict.scr_pd()`](https://evandeilton.github.io/scorecraft/reference/predict.scr_pd.md),
[`scr_calibrate()`](https://evandeilton.github.io/scorecraft/reference/scr_calibrate.md),
[`scr_grades()`](https://evandeilton.github.io/scorecraft/reference/scr_grades.md),
[`scr_master_scale()`](https://evandeilton.github.io/scorecraft/reference/scr_master_scale.md),
[`scr_moc()`](https://evandeilton.github.io/scorecraft/reference/scr_moc.md),
[`scr_pd()`](https://evandeilton.github.io/scorecraft/reference/scr_pd.md),
[`scr_pd_pit_ttc()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_pit_ttc.md),
[`scr_pd_validate()`](https://evandeilton.github.io/scorecraft/reference/scr_pd_validate.md)

## Examples

``` r
set.seed(2)
g0 <- sample(1:5, 500, TRUE)
g1 <- pmin(5, pmax(1, g0 + sample(c(-1, 0, 0, 0, 1), 500, TRUE)))
g1[sample(500, 10)] <- NA
scr_migration(g0, g1, K = 5)
#> <scr_migration> 5 grades | 500 obligors | stable 69.4% | up 17.6% | down 13.1% | default 0.0% | closed 2.0%
#>   MWB upper 0.3308 | MWB lower 0.3422 | mean distance 0.306 | 0 cell(s) not decaying from the diagonal (z > 1.645)
#>   from        1       2       3       4       5 default  closed 
#>   1       73.3%   22.8%    0.0%    0.0%    0.0%    0.0%    4.0% 
#>   2       10.5%   64.2%   24.2%    0.0%    0.0%    0.0%    1.1% 
#>   3        0.0%   22.9%   53.1%   21.9%    0.0%    0.0%    2.1% 
#>   4        0.0%    0.0%   15.3%   62.2%   19.4%    0.0%    3.1% 
#>   5        0.0%    0.0%    0.0%   15.5%   84.5%    0.0%    0.0% 
```
