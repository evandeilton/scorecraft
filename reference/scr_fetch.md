# Fetch a table with reproducible server-side sampling

Sampling happens on the server, not in R: pulling a million rows to
discard ninety per cent of them pays the network cost twice. `max_rows`
is a memory guard: when it binds, the requested fraction is reduced on
the server and the reduction is reported. The random expression follows
the connection class (`rand(seed)` on Spark/Databricks/MySQL, `random()`
on PostgreSQL/DuckDB, an integer-modulo expression on SQLite, which has
no seedable `random()`); pass `sample_expr` to override it.

## Usage

``` r
scr_fetch(
  con,
  table,
  sample_frac = 1,
  seed = NULL,
  max_rows = NULL,
  sample_expr = NULL
)
```

## Arguments

- con:

  A DBI connection, from
  [`scr_connect()`](https://evandeilton.github.io/scorecraft/reference/scr_connect.md).

- table:

  Qualified table name.

- sample_frac:

  Fraction of rows to fetch, in (0, 1\].

- seed:

  Seed of the server-side random function, where supported.

- max_rows:

  Row cap. `NULL` switches it off.

- sample_expr:

  Optional SQL expression yielding a uniform number in `[0, 1)`, used as
  `WHERE <sample_expr> <= sample_frac`.

## Value

A `data.table` with the fetched table.

## See also

Other database:
[`scr_connect()`](https://evandeilton.github.io/scorecraft/reference/scr_connect.md)

## Examples

``` r
con <- scr_connect(driver = RSQLite::SQLite(), dbname = ":memory:")
d <- scr_demo; d$ref_date <- as.character(d$ref_date)
DBI::dbWriteTable(con, "dtm", d)
nrow(scr_fetch(con, "dtm", sample_frac = 0.5, seed = 42))
#> SQL: select * from dtm where ((abs(random()) % 1000000) / 1000000.0) <= 0.500000
#> [1] 2121
nrow(scr_fetch(con, "dtm", max_rows = 1000))
#>   cap of 1,000 rows: fraction reduced from 1.0000 to 0.2381 (table has 4,200)
#> SQL: select * from dtm where ((abs(random()) % 1000000) / 1000000.0) <= 0.238095
#> [1] 974
DBI::dbDisconnect(con)
```
