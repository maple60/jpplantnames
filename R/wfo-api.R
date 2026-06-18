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
  getOption("jpplantnames.wfo_gql_url", "https://list.worldfloraonline.org/gql.php")
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
  mock <- getOption("jpplantnames.wfo_graphql", NULL)
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
