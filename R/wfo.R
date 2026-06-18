#' Suggest WFO Plant List names for a scientific name
#'
#' Query the WFO Plant List GraphQL API for candidate names. This is a small
#' interactive helper for checking scientific names, such as names returned by
#' [scientific_name()] or [japanese_name_search()]. It does not change checklist lookup
#' results.
#'
#' WFO accepted names are database- and release-dependent. For large-scale or
#' reproducible workflows, use cached results and record the WFO release or use
#' a future local WFO release workflow.
#'
#' @param scientific_name Character vector of scientific names.
#' @param limit Integer. Maximum number of WFO suggestions to request per
#'   unique scientific name.
#' @param rank Optional character scalar. If supplied, candidate rows are
#'   filtered by WFO rank after retrieval, for example `"species"`,
#'   `"subspecies"`, or `"variety"`.
#' @param cache Logical. If `TRUE`, raw API responses are cached locally.
#' @param refresh Logical. If `TRUE`, ignore an existing cached response and
#'   fetch from the WFO API again.
#' @param delay Numeric. Seconds to wait between uncached API requests.
#' @param backend Character. Only `"api"` is implemented. `"local"` is reserved
#'   for future WFO release support.
#'
#' @return A data frame with WFO candidate names, accepted-name fields, rank,
#'   status, role, and cache status.
#' @export
#'
#' @examples
#' \dontrun{
#' wfo_suggest("Quercus serrata")
#' wfo_suggest(scientific_name("\u30b3\u30ca\u30e9"))
#' }
wfo_suggest <- function(scientific_name,
                        limit = 10,
                        rank = NULL,
                        cache = TRUE,
                        refresh = FALSE,
                        delay = 0.2,
                        backend = c("api", "local")) {
  if (!is.character(scientific_name)) {
    stop("`scientific_name` must be a character vector.", call. = FALSE)
  }

  backend <- match.arg(backend)
  if (identical(backend, "local")) {
    stop(
      "The local WFO backend is planned but not implemented yet. ",
      "Use `backend = \"api\"` for now.",
      call. = FALSE
    )
  }

  limit <- wfo_check_limit(limit)
  rank <- wfo_check_rank(rank)
  cache <- wfo_check_logical(cache, "cache")
  refresh <- wfo_check_logical(refresh, "refresh")
  delay <- wfo_check_delay(delay)

  if (length(scientific_name) == 0) {
    return(empty_wfo_suggestion_row(NA_character_)[0, , drop = FALSE])
  }

  valid <- !wfo_invalid_input(scientific_name)
  query_names <- unique(trimws(scientific_name[valid]))

  if (length(query_names) > 0 && cache) {
    wfo_require_jsonlite("WFO cache handling")
  }

  by_query <- list()
  uncached_requests <- 0L
  for (query_name in query_names) {
    wait <- if (uncached_requests > 0L) delay else 0
    rows <- wfo_suggest_one(
      query_name,
      limit = limit,
      cache = cache,
      refresh = refresh,
      delay = wait
    )

    used_cache <- isTRUE(attr(rows, "used_cache"))
    attr(rows, "used_cache") <- NULL
    if (!used_cache) {
      uncached_requests <- uncached_requests + 1L
    }

    if (!is.null(rank) && any(!is.na(rows$wfo_id))) {
      filtered <- rows[!is.na(rows$wfo_id) & rows$rank == rank, , drop = FALSE]
      if (nrow(filtered) == 0) {
        rows <- empty_wfo_suggestion_row(query_name, cached = wfo_cache_value(rows$cached))
      } else {
        rows <- filtered
      }
    }

    by_query[[query_name]] <- rows
  }

  result <- lapply(seq_along(scientific_name), function(i) {
    input <- scientific_name[[i]]
    if (wfo_invalid_input(input)) {
      return(empty_wfo_suggestion_row(input, match_method = NA_character_))
    }

    rows <- by_query[[trimws(input)]]
    rows$input <- input
    rows
  })

  result <- do.call(rbind, result)
  row.names(result) <- NULL
  result
}

#' Return the best accepted WFO Plant List name
#'
#' Summarise WFO Plant List suggestions into one accepted-name interpretation
#' per input scientific name. Lookup functions such as [scientific_name()] handle
#' Japanese name to scientific name lookup; this helper handles scientific name
#' to WFO candidate, accepted name, WFO ID, rank, and status checks.
#'
#' WFO API access is intended for small-scale interactive checks. These
#' functions do not automatically replace checklist names with WFO accepted
#' names.
#'
#' @param scientific_name Character vector of scientific names.
#' @param rank Character scalar rank to prefer, usually `"species"`.
#' @param with_author Logical. If `TRUE`, return the accepted name with authors
#'   when available. If `FALSE`, return the no-author accepted name in
#'   `accepted_name`.
#' @param limit Integer. Maximum number of WFO suggestions to request per
#'   unique scientific name.
#' @param cache Logical. If `TRUE`, raw API responses are cached locally.
#' @param refresh Logical. If `TRUE`, ignore an existing cached response and
#'   fetch from the WFO API again.
#' @param delay Numeric. Seconds to wait between uncached API requests.
#' @param backend Character. Only `"api"` is implemented. `"local"` is reserved
#'   for future WFO release support.
#'
#' @return A data frame with one row per input and a clear `match_status`.
#' @export
#'
#' @examples
#' \dontrun{
#' wfo_accepted_name("Quercus serrata")
#' wfo_accepted_name("Quercus serrata", with_author = FALSE)
#' wfo_accepted_name(scientific_name("\u30b3\u30ca\u30e9"))
#' }
wfo_accepted_name <- function(scientific_name,
                              rank = "species",
                              with_author = TRUE,
                              limit = 10,
                              cache = TRUE,
                              refresh = FALSE,
                              delay = 0.2,
                              backend = c("api", "local")) {
  if (!is.character(scientific_name)) {
    stop("`scientific_name` must be a character vector.", call. = FALSE)
  }

  backend <- match.arg(backend)
  if (identical(backend, "local")) {
    stop(
      "The local WFO backend is planned but not implemented yet. ",
      "Use `backend = \"api\"` for now.",
      call. = FALSE
    )
  }

  rank <- wfo_check_rank(rank)
  with_author <- wfo_check_logical(with_author, "with_author")
  limit <- wfo_check_limit(limit)
  cache <- wfo_check_logical(cache, "cache")
  refresh <- wfo_check_logical(refresh, "refresh")
  delay <- wfo_check_delay(delay)

  if (length(scientific_name) == 0) {
    return(empty_wfo_accepted_row(NA_character_, "invalid_input")[0, , drop = FALSE])
  }

  valid <- !wfo_invalid_input(scientific_name)
  query_names <- unique(trimws(scientific_name[valid]))

  suggestions <- empty_wfo_suggestion_row(NA_character_)[0, , drop = FALSE]
  if (length(query_names) > 0) {
    suggestions <- wfo_suggest(
      query_names,
      limit = limit,
      rank = NULL,
      cache = cache,
      refresh = refresh,
      delay = delay,
      backend = backend
    )
  }

  result <- lapply(seq_along(scientific_name), function(i) {
    input <- scientific_name[[i]]
    if (wfo_invalid_input(input)) {
      return(empty_wfo_accepted_row(input, "invalid_input"))
    }

    query_name <- trimws(input)
    rows <- suggestions[suggestions$input == query_name, , drop = FALSE]
    summarize_wfo_accepted(
      input = input,
      query_name = query_name,
      rows = rows,
      rank = rank,
      with_author = with_author
    )
  })

  result <- do.call(rbind, result)
  row.names(result) <- NULL
  result
}
