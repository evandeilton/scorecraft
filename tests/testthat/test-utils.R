test_that("%||% returns the fallback only for NULL or empty", {
  expect_equal(NULL %||% 1, 1)
  expect_equal(character() %||% "a", "a")
  expect_equal(0 %||% 1, 0)
  expect_equal(FALSE %||% TRUE, FALSE)
})

test_that("scr_verbose switches and restores the state", {
  old <- scr_verbose()
  on.exit(scr_verbose(old))
  scr_verbose(FALSE)
  expect_false(scr_verbose())
  expect_silent(msg("nothing"))
  scr_verbose(TRUE)
  expect_message(msg("hello %d", 1L), "hello 1")
})

test_that(".scr_lapply gives identical results serial and parallel and re-throws errors", {
  f <- function(i) i^2
  expect_identical(.scr_lapply(1:6, f, nthread = 1L), lapply(1:6, f))
  expect_identical(.scr_lapply(1:6, f, nthread = 2L), lapply(1:6, f))
  expect_identical(.scr_lapply(1L, f, nthread = 2L), list(1))
  expect_error(.scr_lapply(1:3, function(i) if (i == 2) stop("boom") else i, nthread = 2L), "boom")
})

test_that(".scr_chunks preserves order and covers every item", {
  ch <- .scr_chunks(letters[1:7], 3L)
  expect_length(ch, 3L)
  expect_identical(unlist(ch), letters[1:7])
  expect_identical(.scr_chunks(letters[1:3], 1L), list(letters[1:3]))
  expect_identical(.scr_chunks(character(), 2L), list(character()))
})

test_that(".sql_num keeps full double precision and is vectorised", {
  x <- c(-1.3003598122031599, 1/3, 1e-7, 123456789.123)
  expect_identical(as.numeric(.sql_num(x)), x)
  expect_identical(.sql_num(NA_real_), "NULL")
  expect_false(any(grepl("e", .sql_num(x), fixed = TRUE)))
})

test_that("subsample_stratified caps the size and keeps both classes", {
  y <- rep(0:1, c(900, 100))
  i <- subsample_stratified(y, 200, seed = 1)
  expect_lte(length(i), 200L)
  expect_true(all(c(0L, 1L) %in% y[i]))
  expect_identical(subsample_stratified(y, Inf), seq_along(y))
})
