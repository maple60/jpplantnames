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
