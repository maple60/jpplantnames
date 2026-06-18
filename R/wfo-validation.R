wfo_invalid_input <- function(x) {
  is.na(x) | trimws(x) == ""
}

wfo_check_limit <- function(limit) {
  if (!is.numeric(limit) || length(limit) != 1 || is.na(limit) ||
      !is.finite(limit) || limit < 1 || limit != as.integer(limit)) {
    stop("`limit` must be a positive integer scalar.", call. = FALSE)
  }

  as.integer(limit)
}

wfo_check_rank <- function(rank) {
  if (is.null(rank)) {
    return(NULL)
  }

  if (!is.character(rank) || length(rank) != 1 || is.na(rank) ||
      trimws(rank) == "") {
    stop("`rank` must be `NULL` or a non-empty character scalar.", call. = FALSE)
  }

  trimws(rank)
}

wfo_check_logical <- function(x, name) {
  if (!isTRUE(x) && !identical(x, FALSE)) {
    stop("`", name, "` must be TRUE or FALSE.", call. = FALSE)
  }

  x
}

wfo_check_delay <- function(delay) {
  if (!is.numeric(delay) || length(delay) != 1 || is.na(delay) ||
      !is.finite(delay) || delay < 0) {
    stop("`delay` must be a non-negative numeric scalar.", call. = FALSE)
  }

  delay
}

wfo_require_jsonlite <- function(reason) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package `jsonlite` is required for ", reason, ".", call. = FALSE)
  }

  invisible(TRUE)
}
