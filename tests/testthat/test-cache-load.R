test_that("japanese_name_download writes to and reuses the cache", {
  with_fixture_cache({
    path <- japanese_name_download()

    expect_true(file.exists(path))
    expect_match(path, "wamei_checklist_ver.1.10.xlsx", fixed = TRUE)

    first_mtime <- file.info(path)$mtime
    second_path <- japanese_name_download()

    expect_identical(path, second_path)
    expect_equal(file.info(path)$mtime, first_mtime)
  })
})

test_that("japanese_name_load reads normalized checklist data", {
  with_fixture_cache({
    data <- japanese_name_load()

    expect_s3_class(data, "data.frame")
    expect_true("和名" %in% names(data))
    expect_equal(data[["和名"]][[1]], "コナラ")
    expect_equal(data[["学名"]][[1]], "Quercus serrata")
    expect_equal(data[["別名"]][[2]], "ナラ")
    expect_equal(data[["source_id"]][[1]], "GL_05174")
  })
})

test_that("japanese_name_load refresh redownloads cached data", {
  with_fixture_cache({
    path <- japanese_name_download()
    writeLines("broken", path)

    data <- japanese_name_load(refresh = TRUE)

    expect_equal(data[["和名"]][[1]], "コナラ")
    expect_equal(data[["学名 withAuthor"]][[1]], "Quercus serrata Murray")
  })
})

test_that("old cache function names are deprecated wrappers", {
  with_fixture_cache({
    expect_warning(
      path <- ylist_download(),
      "deprecated"
    )
    expect_true(file.exists(path))
    expect_warning(
      expect_s3_class(ylist_load(), "data.frame"),
      "deprecated"
    )
  })
})
