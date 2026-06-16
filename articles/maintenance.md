# Maintenance guide

This guide is for maintainers who want to change `jpplantnames` without
first reading the whole package. It maps common maintenance goals to the
files that usually need to be edited.

For Japanese, see [日本語:
メンテナンスガイド](https://maple60.github.io/jpplantnames/articles/ja-maintenance.md).

## Project Map

| If you want to change… | Edit these files |
|----|----|
| Checklist download URL, cache file name, or cache location | `R/cache.R` |
| How the checklist Excel file is parsed | `R/load.R` |
| [`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md) behavior | `R/lookup.R`, `tests/testthat/test-lookup.R` |
| [`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md) fields or matching rules | `R/lookup.R`, `tests/testthat/test-lookup.R` |
| GBIF response fields or API behavior | `R/gbif.R`, `tests/testthat/test-gbif.R` |
| Exported functions | `NAMESPACE`, matching `.Rd` files in `man/` |
| Package metadata, dependencies, site URL | `DESCRIPTION` |
| README and pkgdown home page | `README.md` |
| Japanese README | `README.ja.md` |
| pkgdown navigation and reference sections | `_pkgdown.yml` |
| User guides | `vignettes/get-started.Rmd`, `vignettes/ja-get-started.Rmd` |
| Maintenance guides | `vignettes/maintenance.Rmd`, `vignettes/ja-maintenance.Rmd` |
| Package development tutorial | `vignettes/package-development.Rmd`, `vignettes/ja-package-development.Rmd` |
| GitHub Actions R package check | `.github/workflows/R-CMD-check.yaml` |
| GitHub Pages / pkgdown deployment | `.github/workflows/pkgdown.yaml` |

## Function Behavior

### `japanese_name_download()`

Implemented in `R/cache.R`.

Change this file when:

- the checklist Excel file URL changes;
- the cache file name should change;
- you want to change how local fixture sources are copied in tests;
- you want to change the cache directory policy.

The function should keep returning the cached file path invisibly. Tests
for cache behavior live in `tests/testthat/test-cache-load.R`.

### `japanese_name_load()`

Implemented in `R/load.R`.

Change this file when:

- the checklist sheet or required columns change;
- required post-processing is added after reading the file.

The checklist Excel file is read from the `JN_dataset` sheet. Keep
structure tests in the synthetic fixture rather than downloading the
full checklist file during unit tests.

### `scientific_name()`

Implemented in `R/lookup.R`.

Change this file when:

- exact-match behavior changes;
- synonym handling changes;
- no-match behavior changes;
- ambiguity handling changes;
- the return value should include more metadata.

The current contract is intentionally conservative:

- exact-match the `和名` and `別名` columns;
- use only rows where `ステータス == "標準"`;
- return `NA_character_` when there is no standard exact match;
- error when multiple standard exact matches are found.

If this contract changes, update the README, both usage guides, and
tests.

### `japanese_name_search()`

Implemented in `R/lookup.R`.

Change this file when:

- adding a new `field` option;
- changing partial matching behavior;
- adding normalization such as hiragana-to-katakana conversion;
- adding richer candidate ranking.

Add tests for each new search mode. Search should remain explicit and
inspectable; avoid silently changing
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
into a fuzzy lookup.

### `gbif_match()`

Implemented in `R/gbif.R`.

Change this file when:

- adding returned GBIF fields;
- changing error behavior;
- supporting another international name service.

Live GBIF tests are skipped by default. Use
`JPPLANTNAMES_RUN_NETWORK_TESTS=true` when you intentionally want to run
network tests.

## Documentation

The pkgdown home page is generated from `README.md`, so keep `README.md`
in English and link to `README.ja.md` and the Japanese guide.

Use this split:

- `README.md`: English top-level landing page.
- `README.ja.md`: Japanese landing page.
- `vignettes/get-started.Rmd`: English user guide.
- `vignettes/ja-get-started.Rmd`: Japanese user guide.
- `vignettes/maintenance.Rmd`: English maintainer guide.
- `vignettes/ja-maintenance.Rmd`: Japanese maintainer guide.
- `vignettes/package-development.Rmd`: English package-build tutorial.
- `vignettes/ja-package-development.Rmd`: Japanese package-build
  tutorial.
- `_pkgdown.yml`: site navigation, article groups, and reference
  sections.

After editing documentation, build the site locally when possible:

``` r

pkgdown::build_site(preview = FALSE)
```

## Tests and Checks

Run unit tests:

``` r

testthat::test_local(".", reporter = "summary")
```

Build and check the package:

``` sh
R CMD build .
R CMD check jpplantnames_0.1.0.tar.gz --no-manual
```

On Windows, if Pandoc is not on `PATH`, set `RSTUDIO_PANDOC` to an
installed Pandoc directory before building vignettes or pkgdown.

## Release Checklist

Before pushing a maintenance change:

1.  Update tests for any behavior change.
2.  Update README and both language guides if user-visible behavior
    changes.
3.  Run
    [`testthat::test_local()`](https://testthat.r-lib.org/reference/test_package.html).
4.  Run `R CMD build` and `R CMD check`.
5.  Build pkgdown locally if documentation changed.
6.  Push and verify both GitHub Actions workflows.
7.  Confirm the site at <https://maple60.github.io/jpplantnames/>.
