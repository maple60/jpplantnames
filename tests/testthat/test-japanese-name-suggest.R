test_that("japanese_name_suggest returns exact Japanese matches first", {
  with_fixture_cache({
    result <- japanese_name_suggest("\u30b3\u30ca\u30e9")

    expect_s3_class(result, "data.frame")
    expect_gt(nrow(result), 0)
    expect_equal(result[["\u548c\u540d"]][[1]], "\u30b3\u30ca\u30e9")
    expect_equal(result[["matched_value"]][[1]], "\u30b3\u30ca\u30e9")
    expect_equal(result[["match_type"]][[1]], "exact")
    expect_equal(result[["distance"]][[1]], 0)
  })
})

test_that("japanese_name_suggest returns partial Japanese matches", {
  with_fixture_cache({
    result <- japanese_name_suggest("\u30ca\u30e9")

    expect_gt(nrow(result), 0)
    expect_true(any(result[["match_type"]] == "partial"))
    expect_true("\u30b3\u30ca\u30e9" %in% result[["\u548c\u540d"]])
    expect_true("\u30df\u30ba\u30ca\u30e9" %in% result[["\u548c\u540d"]])
  })
})

test_that("japanese_name_suggest normalizes Hiragana when stringi is installed", {
  skip_if_not_installed("stringi")

  with_fixture_cache({
    result <- japanese_name_suggest("\u3053\u306a\u3089")

    expect_gt(nrow(result), 0)
    expect_equal(result[["\u548c\u540d"]][[1]], "\u30b3\u30ca\u30e9")
    expect_equal(result[["match_type"]][[1]], "exact")
  })
})

test_that("japanese_name_suggest normalizes half-width Katakana when stringi is installed", {
  skip_if_not_installed("stringi")

  with_fixture_cache({
    result <- japanese_name_suggest("\uff7a\uff85\uff97")

    expect_gt(nrow(result), 0)
    expect_equal(result[["\u548c\u540d"]][[1]], "\u30b3\u30ca\u30e9")
    expect_equal(result[["match_type"]][[1]], "exact")
  })
})

test_that("japanese_name_suggest uses OSA distance when stringdist is installed", {
  skip_if_not_installed("stringdist")

  with_fixture_cache({
    result <- japanese_name_suggest("\u30b3\u30e9\u30ca")

    expect_gt(nrow(result), 0)
    expect_equal(result[["\u548c\u540d"]][[1]], "\u30b3\u30ca\u30e9")
    expect_equal(result[["match_type"]][[1]], "fuzzy")
    expect_equal(result[["distance"]][[1]], 1)
  })
})

test_that("scientific_name remains exact and conservative", {
  with_fixture_cache({
    expect_equal(scientific_name("\u30b3\u30ca\u30e9"), "Quercus serrata")
    expect_true(is.na(scientific_name("\u3053\u306a\u3089")))
    expect_true(is.na(scientific_name("\uff7a\uff85\uff97")))
    expect_true(is.na(scientific_name("\u30b3\u30e9\u30ca")))
  })
})

test_that("old suggest function name is a deprecated wrapper", {
  with_fixture_cache({
    expect_warning(
      expect_s3_class(ylist_suggest("\u30b3\u30ca\u30e9"), "data.frame"),
      "deprecated"
    )
  })
})
