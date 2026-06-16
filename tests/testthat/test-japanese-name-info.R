konara <- "\u30b3\u30ca\u30e9"
mizunara <- "\u30df\u30ba\u30ca\u30e9"

test_that("japanese_name_info returns a scalar summary and keeps checklist candidates", {
  with_fixture_cache({
    result <- japanese_name_info(konara)

    expect_s3_class(result, "japanese_name_info")
    expect_s3_class(result, "ylist_info")
    expect_equal(result$query, konara)
    expect_equal(nrow(result$summary), 1L)
    expect_true(result$summary$matched[[1]])
    expect_equal(result$summary$scientific_name[[1]], "Quercus serrata")
    expect_equal(
      result$summary$scientific_name_with_author[[1]],
      "Quercus serrata Murray"
    )
    expect_equal(result$summary$n_japanese_name_candidates[[1]], 4L)
    expect_equal(result$summary$match_status[[1]], "matched")
    expect_equal(nrow(result$japanese_name), 4L)
    expect_equal(sum(result$japanese_name$is_preferred), 1L)
    expect_identical(result$ylist, result$japanese_name)
    expect_null(result$wfo)
    expect_null(result$gbif)
  })
})

test_that("japanese_name_info preserves vector input order and length", {
  with_fixture_cache({
    input <- c(konara, mizunara, "not-a-name")
    result <- japanese_name_info(input, with_author = FALSE)

    expect_equal(result$summary$input, input)
    expect_equal(nrow(result$summary), length(input))
    expect_equal(
      result$summary$scientific_name,
      c("Quercus serrata", "Quercus crispula", NA_character_)
    )
    expect_equal(
      result$summary$match_status,
      c("matched", "matched", "no_japanese_name_match")
    )
  })
})

test_that("japanese_name_info handles invalid input without lookup errors", {
  with_fixture_cache({
    result <- japanese_name_info(c(NA_character_, "", "   "))

    expect_equal(nrow(result$summary), 3L)
    expect_equal(result$summary$match_status, rep("invalid_input", 3))
    expect_equal(result$summary$n_japanese_name_candidates, rep(0L, 3))
    expect_equal(nrow(result$japanese_name), 0L)
  })
})

test_that("japanese_name_info does not call external APIs by default", {
  calls <- character()
  old_options <- options(
    ylistjp.wfo_graphql = function(query, variables, endpoint) {
      calls <<- c(calls, "wfo")
      stop("WFO should not be called.", call. = FALSE)
    },
    ylistjp.gbif_match = function(scientific_name) {
      calls <<- c(calls, "gbif")
      stop("GBIF should not be called.", call. = FALSE)
    }
  )
  on.exit(options(old_options), add = TRUE)

  with_fixture_cache({
    result <- japanese_name_info(konara)

    expect_null(result$wfo)
    expect_null(result$gbif)
    expect_equal(calls, character())
  })
})

test_that("print.japanese_name_info does not error", {
  with_fixture_cache({
    scalar <- japanese_name_info(konara)
    vector <- japanese_name_info(c(konara, mizunara))

    expect_output(print(scalar), "Japanese name info")
    expect_output(print(vector), "match_status")
  })
})

test_that("japanese_name_info can add a mocked WFO accepted-name summary", {
  calls <- character()
  old_options <- options(
    ylistjp.wfo_graphql = function(query, variables, endpoint) {
      calls <<- c(calls, variables$termsString)
      accepted <- list(
        id = "wfo-0000293164",
        fullNameStringPlain = "Quercus serrata Murray",
        fullNameStringNoAuthorsPlain = "Quercus serrata",
        authorsString = "Murray",
        rank = "species",
        nomenclaturalStatus = "valid",
        role = "accepted"
      )
      list(data = list(taxonNameSuggestion = list(
        c(
          accepted,
          list(currentPreferredUsage = list(hasName = accepted))
        )
      )))
    }
  )
  on.exit(options(old_options), add = TRUE)

  with_fixture_cache({
    result <- japanese_name_info(konara, wfo = TRUE, cache = FALSE, delay = 0)

    expect_equal(calls, "Quercus serrata")
    expect_s3_class(result$wfo, "data.frame")
    expect_equal(result$summary$wfo_accepted_name[[1]], "Quercus serrata Murray")
    expect_equal(result$summary$wfo_accepted_wfo_id[[1]], "wfo-0000293164")
    expect_equal(result$summary$wfo_match_status[[1]], "matched")
  })
})

test_that("japanese_name_info records WFO failures without failing the whole call", {
  old_options <- options(
    ylistjp.wfo_graphql = function(query, variables, endpoint) {
      stop("mock WFO failure", call. = FALSE)
    }
  )
  on.exit(options(old_options), add = TRUE)

  with_fixture_cache({
    expect_warning(
      result <- japanese_name_info(konara, wfo = TRUE, cache = FALSE, delay = 0),
      "WFO lookup failed"
    )

    expect_equal(result$summary$wfo_match_status[[1]], "error")
  })
})

test_that("japanese_name_info can add a mocked GBIF match summary", {
  calls <- character()
  old_options <- options(
    ylistjp.gbif_match = function(scientific_name) {
      calls <<- scientific_name
      data.frame(
        input = scientific_name,
        usageKey = rep(2878688L, length(scientific_name)),
        scientificName = paste(scientific_name, "Murray"),
        canonicalName = scientific_name,
        rank = rep("SPECIES", length(scientific_name)),
        status = rep("ACCEPTED", length(scientific_name)),
        confidence = rep(99, length(scientific_name)),
        matchType = rep("EXACT", length(scientific_name)),
        kingdom = rep("Plantae", length(scientific_name)),
        family = rep("Fagaceae", length(scientific_name)),
        genus = rep("Quercus", length(scientific_name)),
        species = scientific_name,
        stringsAsFactors = FALSE
      )
    }
  )
  on.exit(options(old_options), add = TRUE)

  with_fixture_cache({
    result <- japanese_name_info(konara, gbif = TRUE)

    expect_equal(calls, "Quercus serrata")
    expect_s3_class(result$gbif, "data.frame")
    expect_equal(result$summary$gbif_usage_key[[1]], 2878688L)
    expect_equal(result$summary$gbif_scientific_name[[1]], "Quercus serrata Murray")
    expect_equal(result$summary$gbif_status[[1]], "ACCEPTED")
    expect_equal(result$summary$gbif_match_type[[1]], "EXACT")
  })
})

test_that("japanese_name_info records GBIF failures without failing the whole call", {
  old_options <- options(
    ylistjp.gbif_match = function(scientific_name) {
      stop("mock GBIF failure", call. = FALSE)
    }
  )
  on.exit(options(old_options), add = TRUE)

  with_fixture_cache({
    expect_warning(
      result <- japanese_name_info(konara, gbif = TRUE),
      "GBIF lookup failed"
    )

    expect_equal(result$summary$gbif_status[[1]], "error")
  })
})

test_that("old info function name is a deprecated wrapper", {
  with_fixture_cache({
    expect_warning(
      result <- ylist_info(konara),
      "deprecated"
    )
    expect_s3_class(result, "japanese_name_info")
    expect_equal(result$summary$scientific_name[[1]], "Quercus serrata")
  })
})
