# ============================================================================ #
# utils.R - internal utilities: verbosity, parallelism, formatting
# ============================================================================ #
# Nothing here knows about the pipeline. Pure functions, reusable and testable
# in isolation.
# ============================================================================ #

#' @keywords internal
#' @noRd
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# -- Verbosity -------------------------------------------------------------- #

.scr_env <- new.env(parent = emptyenv())
.scr_env$verbose <- TRUE

#' Switch progress messages on or off
#'
#' Large tables take tens of minutes, and the pipeline reports every stage as
#' it runs: stage name, input and output counts, elapsed time. Messages go
#' through [message()] as single lines, with no progress bar that redraws
#' itself, so that a scheduled job (`Rscript` in batch) produces a readable
#' log. [suppressMessages()] works too; this function exists to switch them
#' off persistently, without wrapping every call. The `verbose` key of
#' [scr_config()] has the same effect per run.
#'
#' @param on `TRUE` to switch on, `FALSE` to switch off, `NULL` (default) to
#'   query the current state only.
#'
#' @return The verbosity state in force *before* the call, invisibly, so that
#'   `old <- scr_verbose(FALSE); ...; scr_verbose(old)` restores it.
#'
#' @family configuration
#' @examples
#' old <- scr_verbose(FALSE)   # silence, keeping the previous state
#' scr_verbose(old)            # restore
#' scr_verbose()               # query
#' @export
scr_verbose <- function(on = NULL) {
  old <- .scr_env$verbose
  if (!is.null(on)) .scr_env$verbose <- isTRUE(on)
  invisible(old)
}

#' @keywords internal
#' @noRd
msg <- function(fmt, ...) {
  if (isTRUE(.scr_env$verbose)) {
    message(if (length(list(...))) sprintf(fmt, ...) else fmt)
  }
  invisible(NULL)
}

#' @keywords internal
#' @noRd
msg_stage <- function(n, title) {
  msg("\n===== STAGE %s: %s =====", n, title)
}

#' Time an expression, reporting the elapsed time at the end
#' @keywords internal
#' @noRd
time_it <- function(label, expr) {
  t0  <- Sys.time()
  res <- eval.parent(substitute(expr))
  msg("  %s - ok (%.2fs)", label, as.numeric(difftime(Sys.time(), t0, units = "secs")))
  res
}

# -- Parallelism by column (D12) -------------------------------------------- #

#' Parallel lapply with a serial fallback
#'
#' The single real speed lever found in the research: none of the 37 binning
#' algorithms runs in parallel, but columns are embarrassingly parallel. On
#' unix this forks ([parallel::mclapply()]); on Windows it starts a PSOCK
#' cluster, which requires `FUN` to reference package functions with `::`.
#' Serial when `nthread <= 1` or there are fewer than two items.
#'
#' An error in any worker is re-thrown here with the failing item, instead of
#' becoming a silent `try-error` inside the list.
#' @keywords internal
#' @noRd
.scr_lapply <- function(X, FUN, nthread = 1L, ...) {
  n <- length(X)
  k <- min(as.integer(nthread %||% 1L), n)
  if (n < 2L || is.na(k) || k <= 1L) return(lapply(X, FUN, ...))

  if (.Platform$OS.type == "unix") {
    out <- suppressWarnings(parallel::mclapply(X, FUN, ..., mc.cores = k, mc.preschedule = TRUE))
  } else {
    cl <- parallel::makeCluster(k)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    out <- parallel::parLapply(cl, X, FUN, ...)
  }
  err <- vapply(out, inherits, logical(1), "try-error")
  if (any(err)) {
    i <- which(err)[1]
    stop("parallel worker failed (item ", i, "): ",
         conditionMessage(attr(out[[i]], "condition")), call. = FALSE)
  }
  out
}

#' Split a vector into `k` chunks of similar size, preserving order
#' @keywords internal
#' @noRd
.scr_chunks <- function(x, k) {
  k <- max(1L, min(as.integer(k), length(x)))
  if (k == 1L) return(list(x))
  unname(split(x, cut(seq_along(x), k, labels = FALSE)))
}

# -- Sampling --------------------------------------------------------------- #

#' Indices of a subsample stratified by the target
#'
#' Used only for the classifiers: permutation importance and cross-validation
#' grow with the number of rows, and the *ordering* of importance stabilises
#' long before the whole table is used.
#' @keywords internal
#' @noRd
subsample_stratified <- function(y, max_n, seed = NULL) {
  n <- length(y)
  if (!is.finite(max_n) || n <= max_n) return(seq_len(n))
  if (!is.null(seed)) set.seed(seed)
  frac <- max_n / n
  idx  <- integer(0)
  for (lv in unique(y)) {
    pos <- which(y == lv)
    k   <- max(1L, min(length(pos), floor(frac * length(pos))))
    idx <- c(idx, if (length(pos) == 1L) pos else sample(pos, k))
  }
  sort(idx)
}

# -- Ranking and formatting ------------------------------------------------- #

#' Rank percentile from 0 to 1, 1 being the best
#' @keywords internal
#' @noRd
rank_pct <- function(x) {
  ok <- is.finite(x)
  out <- rep(0, length(x))
  if (!any(ok)) return(out)
  r <- rank(x[ok], ties.method = "average")
  out[ok] <- if (sum(ok) == 1L) 1 else (r - 1) / (sum(ok) - 1)
  out
}

#' @keywords internal
#' @noRd
fmt_pct <- function(x, dig = 1) {
  ifelse(is.na(x), "-", sprintf(paste0("%.", dig, "f%%"), 100 * x))
}

#' Integer with thousands separator
#' @keywords internal
#' @noRd
n_fmt <- function(x) {
  formatC(as.integer(x), big.mark = ",", format = "d")
}

#' Truncate a vector of names for a readable log
#' @keywords internal
#' @noRd
lst <- function(x, n = 8) {
  if (!length(x)) return("(none)")
  if (length(x) <= n) paste(x, collapse = ", ")
  else paste0(paste(x[seq_len(n)], collapse = ", "), sprintf(" ... (+%d)", length(x) - n))
}

#' Validate a finite numeric scalar
#' @keywords internal
#' @noRd
.scr_num1 <- function(x, name, lower = -Inf, upper = Inf, open_lower = FALSE) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) {
    stop("`", name, "` must be a single finite number.", call. = FALSE)
  }
  if (x < lower || (open_lower && x <= lower) || x > upper) {
    stop("`", name, "` is outside the allowed range (", if (open_lower) "(" else "[",
         lower, ", ", upper, "]).", call. = FALSE)
  }
  x
}

#' Format numbers for SQL without losing precision or falling into scientific notation
#' @keywords internal
#' @noRd
.sql_num <- function(x) {
  vapply(as.double(x), function(v) {
    if (!is.finite(v)) return("NULL")
    s <- format(v, digits = 15L, scientific = FALSE, trim = TRUE)
    if (!isTRUE(all.equal(as.numeric(s), v, tolerance = 0)))
      s <- format(v, digits = 17L, scientific = FALSE, trim = TRUE)
    s
  }, character(1), USE.NAMES = FALSE)
}

#' @keywords internal
#' @noRd
.sql_str <- function(x) paste0("'", gsub("'", "''", gsub("\\\\", "\\\\\\\\", x)), "'")
