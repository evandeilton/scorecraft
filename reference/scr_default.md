# Build the default flag from a monthly panel

Applies the standard definition of default to a panel with one row per
unit (`id`) and month (`date`): a unit enters default when `dpd` reaches
`default_days` and the arrears are material (both `default_abs` in
currency units and `default_rel` as a share of `exposure`, when arrears
and exposure are supplied), or when `utp` (unlikeliness to pay) is
`TRUE`. It leaves default after `default_probation` consecutive months
without a trigger (`default_probation_restructured` when `restructured`
was `TRUE` at any point of the event). With `obligor` supplied and
`default_level = "obligor"`, a unit whose obligor has more than
`default_pulling` of its exposure in default is pulled into default too,
and a defaulted obligor defaults all its units.

## Usage

``` r
scr_default(
  data,
  id,
  date,
  dpd = NULL,
  arrears = NULL,
  exposure = NULL,
  utp = NULL,
  restructured = NULL,
  obligor = NULL,
  config = scr_config()
)
```

## Arguments

- data:

  A `data.frame` or `data.table`, one row per `id` and `date`.

- id, date:

  Column names of the unit identifier and the month.

- dpd:

  Column name of days past due (integer). Optional when `utp` is given.

- arrears, exposure:

  Column names of the overdue amount and the total exposure, both
  optional; when given, the materiality test applies.

- utp:

  Column name of a logical unlikeliness-to-pay flag, optional.

- restructured:

  Column name of a logical distressed-restructuring flag, optional.

- obligor:

  Column name of the obligor when `id` is a facility, optional; enables
  the pulling effect.

- config:

  A
  [`scr_config()`](https://evandeilton.github.io/scorecraft/reference/scr_config.md);
  keys `default_*`.

## Value

An object of class `scr_default`: `flags` (`id`, `date`, `default` 0/1,
`event_id`, `trigger`, `months_in_default`, `cured`), `events` (one row
per event: `event_id`, `id`, `start`, `end`, `trigger`, `cured`,
`months`), `summary`, `ledger` and `config`.

## Details

Rows must be monthly; gaps are tolerated (the probation counts observed
months). The result keeps the row-level flags: they are the product.

## See also

Other irb-parameters:
[`scr_default_rate()`](https://evandeilton.github.io/scorecraft/reference/scr_default_rate.md),
[`scr_irb_params()`](https://evandeilton.github.io/scorecraft/reference/scr_irb_params.md)

## Examples

``` r
d <- scr_default(scr_demo_panel, id = "id", date = "ref_date", dpd = "dpd",
                 arrears = "arrears", exposure = "exposure",
                 restructured = "restructured",
                 config = scr_config(verbose = FALSE))
d
#> <scr_default> 600 units x 21,600 rows | 176 events | level obligor
#>   rule: dpd >= 90 with material arrears | probation 3 months (12 after restructuring)
#>   triggers: dpd 100.0% | median 5 months in default | cured 87.5%
head(d$events)
#>    event_id     id      start        end trigger months cured
#>      <char> <char>     <Date>     <Date>  <char>  <int> <int>
#> 1:  O0003#1  O0003 2024-10-01 2025-05-01     dpd      8     1
#> 2:  O0011#1  O0011 2025-08-01 2025-11-01     dpd      4     1
#> 3:  O0013#1  O0013 2023-05-01 2023-08-01     dpd      4     1
#> 4:  O0016#1  O0016 2023-05-01 2023-08-01     dpd      4     1
#> 5:  O0018#1  O0018 2024-11-01 2025-04-01     dpd      6     1
#> 6:  O0018#2  O0018 2025-05-01 2025-12-01     dpd      8     0
```
