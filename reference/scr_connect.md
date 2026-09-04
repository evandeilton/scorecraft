# Connect to a database (ODBC DSN or any DBI driver)

With `dsn`, a thin wrapper around
[`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)
over
[`odbc::odbc()`](https://odbc.r-dbi.org/reference/dbConnect-OdbcDriver-method.html)
with one deliberate choice: `bigint = "numeric"`. Under the odbc default
a BIGINT column arrives as `integer64`, and
[`is.numeric()`](https://rdrr.io/r/base/numeric.html) of an `integer64`
is `FALSE`: typing would treat the column as a categorical of very high
cardinality. With `driver`, any DBI driver object is accepted (e.g.
[`RSQLite::SQLite()`](https://rsqlite.r-dbi.org/reference/SQLite.html),
[`duckdb::duckdb()`](https://r.duckdb.org/reference/duckdb.html)), which
is how the database path is tested without a DSN.

## Usage

``` r
scr_connect(dsn = NULL, driver = NULL, timeout = 20, ...)
```

## Arguments

- dsn:

  Name of the DSN configured on the system. Ignored when `driver` is
  given.

- driver:

  Optional DBI driver object, used instead of ODBC.

- timeout:

  Connection timeout in seconds (ODBC only).

- ...:

  Extra arguments passed on to
  [`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)
  (for example `dbname = ":memory:"` for SQLite).

## Value

A DBI connection. Close it with
[`DBI::dbDisconnect()`](https://dbi.r-dbi.org/reference/dbDisconnect.html).

## See also

Other database:
[`scr_fetch()`](https://evandeilton.github.io/scorecraft/reference/scr_fetch.md)

## Examples

``` r
con <- scr_connect(driver = RSQLite::SQLite(), dbname = ":memory:")
d <- scr_demo; d$ref_date <- as.character(d$ref_date)   # SQLite has no Date type
DBI::dbWriteTable(con, "dtm", d)
dt <- scr_fetch(con, "dtm", sample_frac = 0.5, seed = 42)
#> SQL: select * from dtm where ((abs(random()) % 1000000) / 1000000.0) <= 0.500000
nrow(dt)
#> [1] 2094
DBI::dbDisconnect(con)
```
