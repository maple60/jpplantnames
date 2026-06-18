col_japanese_name <- "\u548c\u540d"
col_alias_name <- "\u5225\u540d"
col_scientific_name <- "\u5b66\u540d"
col_scientific_name_author <- "\u5b66\u540d withAuthor"
col_status <- "\u30b9\u30c6\u30fc\u30bf\u30b9"
status_standard <- "\u6a19\u6e96"

required_japanese_name_columns <- c(
  col_japanese_name,
  col_alias_name,
  col_scientific_name,
  col_scientific_name_author,
  col_status
)

check_japanese_name_columns <- function(data, required = required_japanese_name_columns) {
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    stop(
      "Lookup data is missing required column(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(data)
}

#' Look up scientific names from Japanese plant names
#'
#' Exact-matches Japanese names in the cached checklist data and returns the
#' scientific name.
#'
#' @param name Character vector of Japanese plant names.
#' @param with_author Logical. If `TRUE`, include the name author.
#'
#' @return A character vector with one result per input name. Missing names
#'   return `NA_character_`.
#' @export
#'
#' @examples
#' \dontrun{
#' scientific_name("コナラ")
#' #> [1] "Quercus serrata"
#' 
#' scientific_name("コナラ", with_author = TRUE)
#' #> [1] "Quercus serrata Murray"
#' }
scientific_name <- function(name, with_author = FALSE) {
  if (!is.character(name)) {
    stop("`name` must be a character vector.", call. = FALSE)
  }
  if (!isTRUE(with_author) && !identical(with_author, FALSE)) {
    stop("`with_author` must be TRUE or FALSE.", call. = FALSE)
  }

  data <- japanese_name_data()
  check_japanese_name_columns(
    data,
    required = c(
      col_japanese_name,
      col_alias_name,
      col_scientific_name,
      col_scientific_name_author,
      col_status
    )
  )

  column <- if (with_author) col_scientific_name_author else col_scientific_name

  vapply(
    name,
    lookup_one_scientific_name,
    data = data,
    column = column,
    FUN.VALUE = character(1),
    USE.NAMES = FALSE
  )
}

#' @export
academic_name <- function(name, with_author = FALSE) {
  .Deprecated("scientific_name")
  scientific_name(name, with_author = with_author)
}

lookup_one_scientific_name <- function(name, data, column) {
  if (is.na(name)) {
    return(NA_character_)
  }

  japanese_match <- data[[col_japanese_name]] == name
  alias_match <- data[[col_alias_name]] == name
  japanese_match[is.na(japanese_match)] <- FALSE
  alias_match[is.na(alias_match)] <- FALSE

  hits <- data[
    (japanese_match | alias_match) & data[[col_status]] == status_standard,
    ,
    drop = FALSE
  ]

  if (nrow(hits) == 0) {
    return(NA_character_)
  }

  if (nrow(hits) > 1 && !is_checklist_data(hits)) {
    stop(
      "Multiple standard lookup matches found for `",
      name,
      "`. Use japanese_name_search(\"",
      name,
      "\") to inspect candidates.",
      call. = FALSE
    )
  }

  value <- hits[[column]][[1]]
  if (is.na(value) || identical(value, "")) {
    return(NA_character_)
  }

  value
}

#' Search cached checklist rows
#'
#' Search cached checklist rows by Japanese name, scientific name, alias, or all
#' of those fields.
#'
#' @param query Character scalar to search for.
#' @param field Field to search: `japanese`, `scientific`, `alias`, or `all`.
#' @param exact Logical. If `TRUE`, use exact matching; otherwise use partial
#'   fixed-string matching.
#'
#' @return A data frame of matching lookup rows.
#' @export
japanese_name_search <- function(query, field = c("japanese", "scientific", "alias", "all"), exact = FALSE) {
  if (!is.character(query) || length(query) != 1 || is.na(query)) {
    stop("`query` must be a non-missing character scalar.", call. = FALSE)
  }
  if (!isTRUE(exact) && !identical(exact, FALSE)) {
    stop("`exact` must be TRUE or FALSE.", call. = FALSE)
  }

  field <- match.arg(field)
  data <- japanese_name_data()
  check_japanese_name_columns(data)

  columns <- switch(
    field,
    japanese = col_japanese_name,
    scientific = c(col_scientific_name, col_scientific_name_author),
    alias = col_alias_name,
    all = c(
      col_japanese_name,
      col_alias_name,
      col_scientific_name,
      col_scientific_name_author
    )
  )

  mask <- Reduce(
    `|`,
    lapply(columns, function(column) match_japanese_name_column(data[[column]], query, exact = exact))
  )

  result <- data[mask, , drop = FALSE]
  row.names(result) <- NULL
  result
}

#' @export
ylist_search <- function(query, field = c("japanese", "scientific", "alias", "all"), exact = FALSE) {
  .Deprecated("japanese_name_search")
  japanese_name_search(query = query, field = field, exact = exact)
}

match_japanese_name_column <- function(values, query, exact) {
  values[is.na(values)] <- ""
  if (exact) {
    return(values == query)
  }

  grepl(tolower(query), tolower(values), fixed = TRUE)
}

#' Suggest lookup rows for an approximate Japanese plant name
#'
#' `japanese_name_suggest()` is a small interactive helper for finding likely lookup
#' rows before converting Japanese names to scientific names. It searches only
#' the cached lookup Japanese-name column and does not change or autocorrect
#' [scientific_name()] results.
#'
#' @param query Character scalar Japanese plant name to search for.
#' @param n Maximum number of candidate rows to return.
#' @param max_distance Maximum string distance for fuzzy matches. If `NULL`,
#'   the default is 1 for normalized queries with 3 or fewer characters and 2
#'   for longer queries.
#'
#' @return A data frame containing lookup rows plus `query`, `matched_value`,
#'   `distance`, `score`, and `match_type`.
#' @export
#'
#' @examples
#' \dontrun{
#' japanese_name_suggest("\u30b3\u30ca\u30e9")
#' japanese_name_suggest("\u30ca\u30e9")
#' }
japanese_name_suggest <- function(query, n = 10, max_distance = NULL) {
  if (!is.character(query) || length(query) != 1 || is.na(query)) {
    stop("`query` must be a non-missing character scalar.", call. = FALSE)
  }
  if (
    !is.numeric(n) ||
      length(n) != 1 ||
      is.na(n) ||
      !is.finite(n) ||
      n < 0 ||
      n != floor(n)
  ) {
    stop("`n` must be a non-negative whole number.", call. = FALSE)
  }
  if (
    !is.null(max_distance) &&
      (!is.numeric(max_distance) ||
        length(max_distance) != 1 ||
        is.na(max_distance) ||
        !is.finite(max_distance) ||
        max_distance < 0)
  ) {
    stop("`max_distance` must be NULL or a non-negative number.", call. = FALSE)
  }

  data <- japanese_name_data()
  check_japanese_name_columns(data, required = col_japanese_name)

  query_key <- normalize_japanese_name(query)
  if (is.na(query_key) || identical(query_key, "")) {
    stop("`query` must not be empty after normalization.", call. = FALSE)
  }

  if (is.null(max_distance)) {
    max_distance <- if (nchar(query_key, type = "chars") <= 3L) 1 else 2
  }

  candidate_keys <- normalize_japanese_name(data[[col_japanese_name]])
  valid <- !is.na(candidate_keys) & candidate_keys != ""
  distances <- rep(Inf, length(candidate_keys))
  distances[valid] <- japanese_name_string_distance(query_key, candidate_keys[valid])

  exact <- valid & candidate_keys == query_key
  partial <- rep(FALSE, length(candidate_keys))
  partial_candidates <- valid & !exact
  partial[partial_candidates] <- grepl(
    query_key,
    candidate_keys[partial_candidates],
    fixed = TRUE
  )
  fuzzy <- valid & !exact & !partial & distances <= max_distance

  keep <- exact | partial | fuzzy
  if (!any(keep) || n == 0L) {
    return(empty_japanese_name_suggest(data))
  }

  result <- data[keep, , drop = FALSE]
  matched_keys <- candidate_keys[keep]
  result$query <- query
  result$matched_value <- data[[col_japanese_name]][keep]
  result$distance <- distances[keep]
  result$score <- result$distance / pmax(
    nchar(query_key, type = "chars"),
    nchar(matched_keys, type = "chars")
  )
  result$match_type <- ifelse(
    exact[keep],
    "exact",
    ifelse(partial[keep], "partial", "fuzzy")
  )

  rank <- match(result$match_type, c("exact", "partial", "fuzzy"))
  result <- result[
    order(rank, result$distance, result$score, seq_len(nrow(result))),
    ,
    drop = FALSE
  ]
  if (nrow(result) > n) {
    result <- result[seq_len(n), , drop = FALSE]
  }

  row.names(result) <- NULL
  result
}

#' @export
ylist_suggest <- function(query, n = 10, max_distance = NULL) {
  .Deprecated("japanese_name_suggest")
  japanese_name_suggest(query = query, n = n, max_distance = max_distance)
}

normalize_japanese_name <- function(x) {
  x <- enc2utf8(x)
  if (requireNamespace("stringi", quietly = TRUE)) {
    x <- stringi::stri_trans_nfkc(x)
    x <- stringi::stri_trans_general(x, "Hiragana-Katakana")
  }
  x <- trimws(x)
  gsub("[[:space:]\u3000]+", "", x, perl = TRUE)
}

japanese_name_string_distance <- function(query_key, candidate_keys) {
  if (length(candidate_keys) == 0L) {
    return(numeric())
  }

  if (requireNamespace("stringdist", quietly = TRUE)) {
    return(stringdist::stringdist(
      rep(query_key, length(candidate_keys)),
      candidate_keys,
      method = "osa"
    ))
  }

  as.numeric(utils::adist(query_key, candidate_keys))
}

empty_japanese_name_suggest <- function(data) {
  result <- data[0, , drop = FALSE]
  result$query <- character()
  result$matched_value <- character()
  result$distance <- numeric()
  result$score <- numeric()
  result$match_type <- character()
  result
}

is_checklist_data <- function(data) {
  all(c("source_id", "source") %in% names(data))
}
