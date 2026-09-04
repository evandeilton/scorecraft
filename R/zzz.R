#' @keywords internal
#' @noRd
.onAttach <- function(libname, pkgname) {
  missing <- character()
  for (p in c("glmnet", "ranger", "lightgbm", "openxlsx")) {
    if (!requireNamespace(p, quietly = TRUE)) missing <- c(missing, p)
  }
  if (length(missing)) {
    packageStartupMessage(
      "scorecraft: optional package(s) not installed: ", paste(missing, collapse = ", "),
      ".\n  - glmnet, ranger and lightgbm are optional consensus voters (xgboost is required);",
      "\n  - openxlsx is required by scr_export().")
  }
}
