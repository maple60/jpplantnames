wfo_expected_suggestion_columns <- c(
  "input",
  "wfo_id",
  "name",
  "name_no_author",
  "authors",
  "rank",
  "nomenclatural_status",
  "role",
  "accepted_wfo_id",
  "accepted_name",
  "accepted_name_no_author",
  "accepted_authors",
  "accepted_rank",
  "accepted_nomenclatural_status",
  "accepted_role",
  "is_accepted",
  "match_method",
  "cached"
)

wfo_expected_accepted_columns <- c(
  "input",
  "matched_wfo_id",
  "matched_name",
  "matched_name_no_author",
  "matched_rank",
  "matched_role",
  "accepted_wfo_id",
  "accepted_name",
  "accepted_name_no_author",
  "accepted_rank",
  "accepted_role",
  "is_accepted",
  "n_candidates",
  "match_status",
  "cached"
)

wfo_name <- function(id,
                     name,
                     no_author,
                     authors,
                     rank = "species",
                     role = "accepted",
                     status = "valid",
                     accepted = NULL) {
  candidate <- list(
    id = id,
    fullNameStringPlain = name,
    fullNameStringNoAuthorsPlain = no_author,
    authorsString = authors,
    rank = rank,
    nomenclaturalStatus = status,
    role = role
  )

  if (!is.null(accepted)) {
    candidate$currentPreferredUsage <- list(hasName = accepted)
  }

  candidate
}

wfo_accepted_name_list <- function(id = "wfo-0000293164",
                                   name = "Quercus serrata Murray",
                                   no_author = "Quercus serrata",
                                   authors = "Murray",
                                   rank = "species",
                                   role = "accepted",
                                   status = "valid") {
  list(
    id = id,
    fullNameStringPlain = name,
    fullNameStringNoAuthorsPlain = no_author,
    authorsString = authors,
    rank = rank,
    nomenclaturalStatus = status,
    role = role
  )
}

wfo_response <- function(candidates) {
  list(data = list(taxonNameSuggestion = candidates))
}

wfo_basic_response <- function() {
  accepted <- wfo_accepted_name_list()
  synonym_accepted <- wfo_accepted_name_list(
    id = "wfo-accepted-other",
    name = "Castanopsis indica (Roxb. ex Lindl.) A.DC.",
    no_author = "Castanopsis indica",
    authors = "(Roxb. ex Lindl.) A.DC."
  )

  wfo_response(list(
    wfo_name(
      id = "wfo-0000293164",
      name = "Quercus serrata Murray",
      no_author = "Quercus serrata",
      authors = "Murray",
      accepted = accepted
    ),
    wfo_name(
      id = "wfo-0000293165",
      name = "Quercus serrata Roxb.",
      no_author = "Quercus serrata",
      authors = "Roxb.",
      role = "synonym",
      status = "unknown",
      accepted = synonym_accepted
    ),
    wfo_name(
      id = "wfo-0001062616",
      name = "Quercus serrata Thunb.",
      no_author = "Quercus serrata",
      authors = "Thunb.",
      role = "unplaced",
      status = "unknown"
    )
  ))
}

wfo_variety_first_response <- function() {
  accepted <- wfo_accepted_name_list()

  wfo_response(list(
    wfo_name(
      id = "wfo-variety",
      name = "Quercus serrata var. brevipetiolata",
      no_author = "Quercus serrata var. brevipetiolata",
      authors = "",
      rank = "variety",
      role = "synonym",
      accepted = accepted
    ),
    wfo_name(
      id = "wfo-0000293164",
      name = "Quercus serrata Murray",
      no_author = "Quercus serrata",
      authors = "Murray",
      rank = "species",
      role = "accepted",
      accepted = accepted
    )
  ))
}

wfo_with_mock_graphql <- function(response, code) {
  calls <- character()
  mock <- function(query, variables, endpoint) {
    calls <<- c(calls, variables$termsString)
    response
  }

  old_options <- options(
    ylistjp.wfo_graphql = mock,
    ylistjp.wfo_gql_url = "https://example.test/gql"
  )
  on.exit(options(old_options), add = TRUE)

  force(code)
  calls
}

test_that("wfo_suggest returns stable columns for invalid input", {
  result <- wfo_suggest(c(NA_character_, "", "   "))

  expect_s3_class(result, "data.frame")
  expect_equal(names(result), wfo_expected_suggestion_columns)
  expect_equal(nrow(result), 3)
  expect_true(all(is.na(result$wfo_id)))
  expect_true(all(result$is_accepted %in% FALSE))
})

test_that("wfo_accepted_name returns stable columns for invalid input", {
  result <- wfo_accepted_name(c(NA_character_, "", "   "))

  expect_s3_class(result, "data.frame")
  expect_equal(names(result), wfo_expected_accepted_columns)
  expect_equal(result$match_status, rep("invalid_input", 3))
  expect_true(all(result$n_candidates == 0L))
})

test_that("parse_wfo_suggest_response preserves WFO fields and is_accepted logic", {
  rows <- ylistjp:::parse_wfo_suggest_response(
    wfo_basic_response(),
    "Quercus serrata",
    cached = TRUE
  )

  expect_equal(names(rows), wfo_expected_suggestion_columns)
  expect_equal(nrow(rows), 3)
  expect_true(rows$is_accepted[[1]])
  expect_false(rows$is_accepted[[2]])
  expect_false(rows$is_accepted[[3]])
  expect_true(all(rows$cached))
  expect_equal(rows$accepted_wfo_id[[2]], "wfo-accepted-other")
  expect_true(is.na(rows$accepted_wfo_id[[3]]))
})

test_that("missing fields in WFO-like responses do not crash parsing", {
  rows <- ylistjp:::parse_wfo_suggest_response(
    wfo_response(list(list(id = "wfo-missing"))),
    "Missing fields",
    cached = FALSE
  )

  expect_equal(rows$wfo_id[[1]], "wfo-missing")
  expect_true(is.na(rows$name[[1]]))
  expect_false(rows$is_accepted[[1]])
})

test_that("wfo_suggest handles vectors, rank filtering, and repeated names", {
  calls <- wfo_with_mock_graphql(wfo_variety_first_response(), {
    result <- wfo_suggest(
      c("Quercus serrata", " Quercus serrata "),
      rank = "species",
      cache = FALSE,
      delay = 0
    )

    expect_equal(nrow(result), 2)
    expect_true(all(result$rank == "species"))
    expect_equal(result$input, c("Quercus serrata", " Quercus serrata "))
  })

  expect_equal(calls, "Quercus serrata")
})

test_that("wfo_accepted_name prefers exact species matches over infraspecific candidates", {
  wfo_with_mock_graphql(wfo_variety_first_response(), {
    result <- wfo_accepted_name(
      "Quercus serrata",
      rank = "species",
      cache = FALSE,
      delay = 0
    )

    expect_equal(result$matched_wfo_id[[1]], "wfo-0000293164")
    expect_equal(result$matched_rank[[1]], "species")
    expect_equal(result$match_status[[1]], "matched")
    expect_true(result$is_accepted[[1]])
  })
})

test_that("wfo_accepted_name reports ambiguity and no exact rank match", {
  accepted <- wfo_accepted_name_list()
  ambiguous_response <- wfo_response(list(
    wfo_name(
      id = "wfo-1",
      name = "Quercus serrata A",
      no_author = "Quercus serrata",
      authors = "A",
      accepted = accepted
    ),
    wfo_name(
      id = "wfo-2",
      name = "Quercus serrata B",
      no_author = "Quercus serrata",
      authors = "B",
      accepted = accepted
    )
  ))

  wfo_with_mock_graphql(ambiguous_response, {
    ambiguous <- wfo_accepted_name(
      "Quercus serrata",
      cache = FALSE,
      delay = 0
    )

    expect_equal(ambiguous$match_status[[1]], "ambiguous")
    expect_equal(ambiguous$n_candidates[[1]], 2L)
  })

  wfo_with_mock_graphql(wfo_basic_response(), {
    no_exact <- wfo_accepted_name(
      "Quercus other",
      rank = "species",
      cache = FALSE,
      delay = 0
    )

    expect_equal(no_exact$match_status[[1]], "no_exact_rank_match")
    expect_equal(no_exact$n_candidates[[1]], 3L)
  })
})

test_that("wfo_accepted_name can return accepted names without authors", {
  wfo_with_mock_graphql(wfo_variety_first_response(), {
    result <- wfo_accepted_name(
      "Quercus serrata",
      with_author = FALSE,
      cache = FALSE,
      delay = 0
    )

    expect_equal(result$accepted_name[[1]], "Quercus serrata")
    expect_equal(result$accepted_name_no_author[[1]], "Quercus serrata")
  })
})

test_that("WFO cache files are read and can be refreshed", {
  skip_if_not(requireNamespace("jsonlite", quietly = TRUE), "jsonlite is not installed.")

  cache_dir <- tempfile("wfo-cache-")
  old_options <- options(
    ylistjp.wfo_cache_dir = cache_dir,
    ylistjp.wfo_gql_url = "https://example.test/gql"
  )
  on.exit(options(old_options), add = TRUE)
  on.exit(unlink(cache_dir, recursive = TRUE, force = TRUE), add = TRUE)

  path <- ylistjp:::wfo_cache_file(
    function_name = "wfo_suggest",
    scientific_name = "Quercus serrata",
    endpoint = "https://example.test/gql",
    limit = 10
  )
  ylistjp:::wfo_write_cache(path, wfo_basic_response())

  old_graphql <- options(ylistjp.wfo_graphql = function(query, variables, endpoint) {
    stop("API should not be called when cache is available.", call. = FALSE)
  })
  on.exit(options(old_graphql), add = TRUE)

  cached <- wfo_suggest("Quercus serrata")
  expect_true(all(cached$cached))

  calls <- 0L
  options(ylistjp.wfo_graphql = function(query, variables, endpoint) {
    calls <<- calls + 1L
    wfo_variety_first_response()
  })

  refreshed <- wfo_suggest("Quercus serrata", refresh = TRUE, delay = 0)
  expect_equal(calls, 1L)
  expect_false(any(refreshed$cached))
})

test_that("backend = local errors clearly", {
  expect_error(
    wfo_suggest("Quercus serrata", backend = "local"),
    "local WFO backend is planned"
  )
  expect_error(
    wfo_accepted_name("Quercus serrata", backend = "local"),
    "local WFO backend is planned"
  )
})
