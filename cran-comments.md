## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.
* Examples and tests run the whole pipeline on a bundled 4,200-row dataset
  with reduced model settings; parallel code paths use at most 2 cores.
* Suggested packages (`glmnet`, `ranger`, `lightgbm`, `openxlsx`, `DBI`,
  `RSQLite`, `duckdb`, `odbc`) are guarded by `requireNamespace()` and the
  tests that need them are skipped when they are absent.
