test_that("academic_name returns standard scientific names", {
  with_fixture_cache({
    expect_equal(academic_name("コナラ"), "Quercus serrata")
    expect_equal(academic_name("コナラ", with_author = TRUE), "Quercus serrata Murray")
  })
})

test_that("academic_name uses the first checklist candidate deterministically", {
  with_fixture_cache({
    expect_equal(academic_name("コナラ", with_author = TRUE), "Quercus serrata Murray")
    expect_false(
      identical(
        academic_name("コナラ", with_author = TRUE),
        "Quercus serrata Murray subsp. serrata var. serrata"
      )
    )
  })
})

test_that("academic_name searches another name values", {
  with_fixture_cache({
    expect_equal(academic_name("ナラ"), "Quercus serrata")
    expect_equal(academic_name("ナラ", with_author = TRUE), "Quercus serrata Murray")
  })
})

test_that("academic_name returns NA for no match", {
  with_fixture_cache({
    expect_true(is.na(academic_name("存在しない植物名")))
    expect_true(is.na(academic_name(NA_character_)))
  })
})

test_that("academic_name errors on ambiguous standard exact matches", {
  data <- data.frame(
    "和名" = c("コナラ", "コナラ"),
    "別名" = c("", ""),
    "学名" = c("Quercus serrata", "Quercus duplicate"),
    "学名 withAuthor" = c("Quercus serrata Murray", "Quercus duplicate Author"),
    "ステータス" = c("標準", "標準"),
    check.names = FALSE
  )

  old_options <- options(ylistjp.data = data)
  on.exit(options(old_options), add = TRUE)

  expect_error(academic_name("コナラ"), "Multiple standard lookup matches")
})

test_that("ylist_search returns candidates for partial Japanese search", {
  with_fixture_cache({
    result <- ylist_search("コナラ")

    expect_s3_class(result, "data.frame")
    expect_gt(nrow(result), 1)
    expect_true("コナラ" %in% result[["和名"]])
    expect_true("オオバコナラ" %in% result[["和名"]])
    expect_true("Quercus serrata" %in% result[["学名"]])
  })
})

test_that("ylist_search supports field-specific exact matching", {
  with_fixture_cache({
    exact <- ylist_search("Quercus serrata", field = "scientific", exact = TRUE)
    alias <- ylist_search("ナラ", field = "alias", exact = TRUE)

    expect_equal(nrow(exact), 2)
    expect_equal(nrow(alias), 1)
    expect_equal(alias[["和名"]][[1]], "コナラ")
  })
})

test_that("ylist_search can search all name fields", {
  with_fixture_cache({
    result <- ylist_search("コナラ", field = "all")

    expect_true("Quercus \u00d7 major" %in% result[["学名"]])
  })
})
