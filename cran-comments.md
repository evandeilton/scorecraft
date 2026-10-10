## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility: "Days since last update: 3". This
  update fixes the noLD additional issue reported by the CRAN team (deadline
  2026-10-30): a test parsed 17-digit SQL literals back with `as.numeric()`,
  which is off by one ulp without long double. The test now compares the
  literals as text.
* The update also adds the score studies (`scr_bands()`, `scr_tiers()`,
  `scr_rag()` and related functions); see NEWS.md.

## Test environments

* Local: Ubuntu 26.04, R 4.6.1
* GitHub Actions: macOS, Windows and Ubuntu (R-devel, release, oldrel)
* R-hub `nold` container: R-devel configured with `--disable-long-double`
