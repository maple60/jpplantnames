#' Suggest WFO Plant List names for a scientific name
#'
#' Query the WFO Plant List GraphQL API for candidate names. This is a small
#' interactive helper for checking scientific names, such as names returned by
#' [academic_name()] or [ylist_search()]. It does not change checklist lookup
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
#' wfo_suggest(academic_name("\u30b3\u30ca\u30e9"))
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
#' per input scientific name. Lookup functions such as [academic_name()] handle
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
#' wfo_accepted_name(academic_name("\u30b3\u30ca\u30e9"))
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

wfo_suggest_one <- function(scientific_name,
                            limit,
                            cache,
                            refresh,
                            delay) {
  endpoint <- wfo_endpoint()
  cache_path <- wfo_cache_file(
    function_name = "wfo_suggest",
    scientific_name = scientific_name,
    endpoint = endpoint,
    limit = limit
  )

  if (cache && !refresh) {
    cached_response <- wfo_read_cache(cache_path)
    if (!is.null(cached_response)) {
      rows <- parse_wfo_suggest_response(cached_response, scientific_name, cached = TRUE)
      attr(rows, "used_cache") <- TRUE
      return(rows)
    }
  }

  if (delay > 0) {
    Sys.sleep(delay)
  }

  response <- wfo_graphql(
    query = wfo_suggest_query(),
    variables = list(termsString = scientific_name, limit = limit),
    endpoint = endpoint
  )

  if (cache) {
    wfo_write_cache(cache_path, response)
  }

  rows <- parse_wfo_suggest_response(response, scientific_name, cached = FALSE)
  attr(rows, "used_cache") <- FALSE
  rows
}

wfo_endpoint <- function() {
  getOption("ylistjp.wfo_gql_url", "https://list.worldfloraonline.org/gql.php")
}

wfo_suggest_query <- function() {
  paste(
    "query WfoSuggest($termsString: String, $limit: Int) {",
    "taxonNameSuggestion(",
    "termsString: $termsString,",
    "limit: $limit,",
    "excludeDeprecated: true",
    ") {",
    "id",
    "fullNameStringPlain",
    "fullNameStringNoAuthorsPlain",
    "authorsString",
    "rank",
    "nomenclaturalStatus",
    "role",
    "currentPreferredUsage {",
    "hasName {",
    "id",
    "fullNameStringPlain",
    "fullNameStringNoAuthorsPlain",
    "authorsString",
    "rank",
    "nomenclaturalStatus",
    "role",
    "}",
    "}",
    "}",
    "}",
    sep = "\n"
  )
}

wfo_graphql <- function(query,
                        variables,
                        endpoint = wfo_endpoint()) {
  mock <- getOption("ylistjp.wfo_graphql", NULL)
  if (is.function(mock)) {
    return(mock(query = query, variables = variables, endpoint = endpoint))
  }

  if (!requireNamespace("httr2", quietly = TRUE)) {
    stop("Package `httr2` is required for WFO API requests.", call. = FALSE)
  }

  request <- httr2::request(endpoint)
  request <- httr2::req_method(request, "POST")
  request <- httr2::req_headers(
    request,
    Accept = "application/json",
    "Content-Type" = "application/json"
  )
  request <- httr2::req_body_json(
    request,
    list(query = query, variables = variables),
    auto_unbox = TRUE
  )

  response <- tryCatch(
    httr2::req_perform(request),
    error = function(error) {
      stop(
        "WFO GraphQL request failed: ",
        conditionMessage(error),
        call. = FALSE
      )
    }
  )

  status <- httr2::resp_status(response)
  if (status >= 400) {
    stop("WFO GraphQL request failed with HTTP status ", status, ".", call. = FALSE)
  }

  parsed <- tryCatch(
    httr2::resp_body_json(response, simplifyVector = FALSE),
    error = function(error) {
      stop(
        "Failed to parse WFO GraphQL response: ",
        conditionMessage(error),
        call. = FALSE
      )
    }
  )

  if (!is.null(parsed$errors)) {
    stop(
      "WFO GraphQL returned error(s): ",
      paste(wfo_graphql_error_messages(parsed$errors), collapse = "; "),
      call. = FALSE
    )
  }

  parsed
}

wfo_graphql_error_messages <- function(errors) {
  if (!is.list(errors)) {
    return(as.character(errors))
  }

  vapply(errors, function(error) {
    message <- error[["message"]]
    if (is.null(message) || length(message) == 0 || is.na(message[[1]])) {
      return("<unknown GraphQL error>")
    }
    as.character(message[[1]])
  }, character(1))
}

parse_wfo_suggest_response <- function(response, input, cached = FALSE) {
  candidates <- response[["data"]][["taxonNameSuggestion"]]
  if (is.null(candidates) || length(candidates) == 0) {
    return(empty_wfo_suggestion_row(input, cached = cached))
  }

  rows <- lapply(candidates, function(candidate) {
    wfo_id <- wfo_field(candidate, "id")
    accepted_wfo_id <- wfo_accepted_field(candidate, "id")

    data.frame(
      input = input,
      wfo_id = wfo_id,
      name = wfo_field(candidate, "fullNameStringPlain"),
      name_no_author = wfo_field(candidate, "fullNameStringNoAuthorsPlain"),
      authors = wfo_field(candidate, "authorsString"),
      rank = wfo_field(candidate, "rank"),
      nomenclatural_status = wfo_field(candidate, "nomenclaturalStatus"),
      role = wfo_field(candidate, "role"),
      accepted_wfo_id = accepted_wfo_id,
      accepted_name = wfo_accepted_field(candidate, "fullNameStringPlain"),
      accepted_name_no_author = wfo_accepted_field(candidate, "fullNameStringNoAuthorsPlain"),
      accepted_authors = wfo_accepted_field(candidate, "authorsString"),
      accepted_rank = wfo_accepted_field(candidate, "rank"),
      accepted_nomenclatural_status = wfo_accepted_field(candidate, "nomenclaturalStatus"),
      accepted_role = wfo_accepted_field(candidate, "role"),
      is_accepted = !is.na(wfo_id) && !is.na(accepted_wfo_id) && identical(wfo_id, accepted_wfo_id),
      match_method = "taxonNameSuggestion",
      cached = cached,
      stringsAsFactors = FALSE
    )
  })

  rows <- do.call(rbind, rows)
  row.names(rows) <- NULL
  rows
}

empty_wfo_suggestion_row <- function(input,
                                     cached = NA,
                                     match_method = "taxonNameSuggestion") {
  data.frame(
    input = input,
    wfo_id = NA_character_,
    name = NA_character_,
    name_no_author = NA_character_,
    authors = NA_character_,
    rank = NA_character_,
    nomenclatural_status = NA_character_,
    role = NA_character_,
    accepted_wfo_id = NA_character_,
    accepted_name = NA_character_,
    accepted_name_no_author = NA_character_,
    accepted_authors = NA_character_,
    accepted_rank = NA_character_,
    accepted_nomenclatural_status = NA_character_,
    accepted_role = NA_character_,
    is_accepted = FALSE,
    match_method = match_method,
    cached = cached,
    stringsAsFactors = FALSE
  )
}

wfo_field <- function(x, name) {
  if (!is.list(x)) {
    return(NA_character_)
  }

  value <- x[[name]]
  if (is.null(value) || length(value) == 0) {
    return(NA_character_)
  }

  value <- value[[1]]
  if (is.null(value) || length(value) == 0 || is.na(value)) {
    return(NA_character_)
  }

  as.character(value)
}

wfo_accepted_field <- function(x, name) {
  usage <- x[["currentPreferredUsage"]]
  if (is.null(usage) || length(usage) == 0) {
    return(NA_character_)
  }

  has_name <- usage[["hasName"]]
  if (is.null(has_name) || length(has_name) == 0) {
    return(NA_character_)
  }

  wfo_field(has_name, name)
}

summarize_wfo_accepted <- function(input,
                                   query_name,
                                   rows,
                                   rank,
                                   with_author) {
  cached <- wfo_cache_value(rows$cached)
  candidate_rows <- rows[!is.na(rows$wfo_id), , drop = FALSE]
  n_candidates <- nrow(candidate_rows)

  if (n_candidates == 0) {
    return(empty_wfo_accepted_row(
      input,
      "no_candidate",
      n_candidates = 0L,
      cached = cached
    ))
  }

  exact_name <- !is.na(candidate_rows$name_no_author) &
    candidate_rows$name_no_author == query_name
  rank_match <- rep(TRUE, n_candidates)
  if (!is.null(rank)) {
    rank_match <- !is.na(candidate_rows$rank) & candidate_rows$rank == rank
  }

  exact_rank_rows <- candidate_rows[exact_name & rank_match, , drop = FALSE]
  if (nrow(exact_rank_rows) > 0) {
    chosen <- exact_rank_rows[1, , drop = FALSE]
    status <- if (nrow(exact_rank_rows) > 1) "ambiguous" else "matched"
  } else {
    rank_rows <- candidate_rows[rank_match, , drop = FALSE]
    if (nrow(rank_rows) > 0) {
      chosen <- rank_rows[1, , drop = FALSE]
    } else {
      chosen <- candidate_rows[1, , drop = FALSE]
    }
    status <- "no_exact_rank_match"
  }

  accepted_name <- if (with_author) {
    chosen$accepted_name[[1]]
  } else {
    chosen$accepted_name_no_author[[1]]
  }

  data.frame(
    input = input,
    matched_wfo_id = chosen$wfo_id[[1]],
    matched_name = chosen$name[[1]],
    matched_name_no_author = chosen$name_no_author[[1]],
    matched_rank = chosen$rank[[1]],
    matched_role = chosen$role[[1]],
    accepted_wfo_id = chosen$accepted_wfo_id[[1]],
    accepted_name = accepted_name,
    accepted_name_no_author = chosen$accepted_name_no_author[[1]],
    accepted_rank = chosen$accepted_rank[[1]],
    accepted_role = chosen$accepted_role[[1]],
    is_accepted = chosen$is_accepted[[1]],
    n_candidates = n_candidates,
    match_status = status,
    cached = cached,
    stringsAsFactors = FALSE
  )
}

empty_wfo_accepted_row <- function(input,
                                   match_status,
                                   n_candidates = 0L,
                                   cached = NA) {
  data.frame(
    input = input,
    matched_wfo_id = NA_character_,
    matched_name = NA_character_,
    matched_name_no_author = NA_character_,
    matched_rank = NA_character_,
    matched_role = NA_character_,
    accepted_wfo_id = NA_character_,
    accepted_name = NA_character_,
    accepted_name_no_author = NA_character_,
    accepted_rank = NA_character_,
    accepted_role = NA_character_,
    is_accepted = FALSE,
    n_candidates = as.integer(n_candidates),
    match_status = match_status,
    cached = cached,
    stringsAsFactors = FALSE
  )
}

wfo_cache_value <- function(cached) {
  cached <- cached[!is.na(cached)]
  if (length(cached) == 0) {
    return(NA)
  }

  all(cached)
}

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

wfo_cache_dir <- function() {
  cache_dir <- getOption("ylistjp.wfo_cache_dir", NULL)
  if (!is.null(cache_dir)) {
    return(cache_dir)
  }

  file.path(tools::R_user_dir("ylistjp", which = "cache"), "wfo")
}

wfo_cache_file <- function(function_name,
                           scientific_name,
                           endpoint = wfo_endpoint(),
                           limit = 10) {
  key <- paste(function_name, endpoint, limit, scientific_name, sep = "\n")
  safe_name <- wfo_safe_filename_part(scientific_name)
  hash <- wfo_hash_string(key)

  file.path(
    wfo_cache_dir(),
    paste0(function_name, "_", safe_name, "_limit", limit, "_", hash, ".json")
  )
}

wfo_read_cache <- function(path) {
  if (!file.exists(path)) {
    return(NULL)
  }

  wfo_require_jsonlite("reading WFO cache files")
  tryCatch(
    jsonlite::read_json(path, simplifyVector = FALSE),
    error = function(error) NULL
  )
}

wfo_write_cache <- function(path, response) {
  wfo_require_jsonlite("writing WFO cache files")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    response,
    path = path,
    auto_unbox = TRUE,
    null = "null",
    pretty = TRUE
  )

  invisible(path)
}

wfo_safe_filename_part <- function(x) {
  safe <- iconv(enc2utf8(x), to = "ASCII//TRANSLIT", sub = "_")
  if (is.na(safe)) {
    safe <- "name"
  }

  safe <- gsub("[^A-Za-z0-9]+", "_", safe)
  safe <- gsub("^_+|_+$", "", safe)
  if (identical(safe, "")) {
    safe <- "name"
  }

  substr(safe, 1, 60)
}

wfo_hash_string <- function(x) {
  bytes <- as.integer(charToRaw(enc2utf8(x)))
  if (length(bytes) == 0) {
    return("00000000")
  }

  value <- sum((bytes + 1) * seq_along(bytes)) %% 2147483647
  sprintf("%08x", as.integer(value))
}
