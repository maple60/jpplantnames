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
| [`japanese_name_suggest()`](https://maple60.github.io/jpplantnames/reference/japanese_name_suggest.md) normalization, ranking, or fuzzy matching | `R/lookup.R`, `tests/testthat/test-japanese-name-suggest.R` |
| [`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md) summary fields or optional WFO/GBIF aggregation | `R/japanese_name_info.R`, `tests/testthat/test-japanese-name-info.R` |
| WFO response fields, accepted-name behavior, or response cache | `R/wfo.R`, `tests/testthat/test-wfo.R` |
| GBIF response fields or API behavior | `R/gbif.R`, `tests/testthat/test-gbif.R` |
| Exported functions | roxygen comments in `R/*.R`; regenerate `NAMESPACE` and `man/*.Rd` |
| Package metadata, dependencies, site URL | `DESCRIPTION` |
| README and pkgdown home page | `README.md` |
| Japanese README | `README.ja.md` |
| pkgdown navigation and reference sections | `_pkgdown.yml` |
| User guides | `vignettes/get-started.qmd`, `vignettes/ja-get-started.qmd` |
| Maintenance guides | `vignettes/maintenance.qmd`, `vignettes/ja-maintenance.qmd` |
| Package development tutorial | `vignettes/package-development.qmd`, `vignettes/ja-package-development.qmd` |
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

### `japanese_name_suggest()`

Implemented in `R/lookup.R`.

Change this file when:

- Japanese-name normalization changes;
- exact, partial, or fuzzy-match ordering changes;
- default `max_distance`, scoring, or candidate ranking changes;
- optional `stringi` or `stringdist` behavior changes;
- return metadata columns such as `matched_value`, `distance`, `score`,
  or `match_type` change.

This helper searches only the cached Japanese-name column. It is for
suggesting candidate checklist rows, not for autocorrecting
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md).
Keep
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
exact and conservative. Tests live in
`tests/testthat/test-japanese-name-suggest.R`.

### `japanese_name_info()`

Implemented in `R/japanese_name_info.R`.

Change this file when:

- summary columns or print output change;
- the preferred checklist candidate rule changes;
- optional WFO or GBIF integration changes;
- external API failures should be summarized differently;
- the deprecated
  [`ylist_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
  compatibility wrapper changes.

By default,
[`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
uses only cached checklist data. It calls WFO only with `wfo = TRUE` and
GBIF only with `gbif = TRUE`. WFO and GBIF results are stored alongside
the checklist summary and do not overwrite checklist names. External API
failures should warn and return error-status rows instead of failing the
whole info call. Tests live in
`tests/testthat/test-japanese-name-info.R`.

### `wfo_suggest()` and `wfo_accepted_name()`

Implemented in `R/wfo.R`.

Change this file when:

- the WFO GraphQL endpoint, query, or returned fields change;
- accepted-name summarization, rank preference, or `with_author`
  behavior changes;
- WFO cache file naming, cache directory policy, or cache read/write
  behavior changes;
- `backend = "local"` is implemented.

WFO access is an optional, small-scale external API check. With
`cache = TRUE`, raw API responses are cached locally; `refresh = TRUE`
ignores an existing cache file and fetches again. The default cache
directory is `tools::R_user_dir("jpplantnames", which = "cache")/wfo`,
unless `options(jpplantnames.wfo_cache_dir = ...)` is set. WFO results
do not replace Japanese-name checklist results. Unit tests should use
mocked GraphQL responses through
`options(jpplantnames.wfo_graphql = ...)`, not live WFO requests.

### `gbif_match()`

Implemented in `R/gbif.R`.

Change this file when:

- adding returned GBIF fields;
- changing error behavior;
- changing the optional GBIF API wrapper used by
  [`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md).

Live GBIF tests are skipped by default. Use
`JPPLANTNAMES_RUN_NETWORK_TESTS=true` when you intentionally want to run
network tests.

## External APIs and Caches

Keep network-dependent behavior explicit in examples and tests.
Checklist data is loaded from the package cache after download.
[`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
does not call external APIs unless WFO or GBIF checks are requested.

WFO responses can be cached and refreshed through the arguments
described above. GBIF has no package-level response cache, so live GBIF
tests must stay opt-in. When adding or changing an external API, keep
unit tests mocked, document any new cache or refresh behavior, and make
sure external results remain separate from the core checklist lookup.

## Documentation

The pkgdown home page is generated from `README.md`, so keep `README.md`
in English and link to `README.ja.md` and the Japanese guide.

Function reference pages are generated from roxygen comments in `R/*.R`.
Treat the roxygen comments as the source of truth. Do not edit files in
`man/` by hand; they will be overwritten the next time roxygen runs. If
a reference page needs a new argument description, example, details
section, alias, or deprecated-wrapper note, add it to the roxygen block
next to the function.

Use this split:

- `README.md`: English top-level landing page.
- `README.ja.md`: Japanese landing page.
- `vignettes/get-started.qmd`: English user guide.
- `vignettes/ja-get-started.qmd`: Japanese user guide.
- `vignettes/maintenance.qmd`: English maintainer guide.
- `vignettes/ja-maintenance.qmd`: Japanese maintainer guide.
- `vignettes/package-development.qmd`: English package-build tutorial.
- `vignettes/ja-package-development.qmd`: Japanese package-build
  tutorial.
- `_pkgdown.yml`: site navigation, article groups, and reference
  sections.

## Local Documentation Workflow

For a function-reference change:

1.  Edit the roxygen comments in `R/*.R`.
2.  Regenerate reference files:

``` powershell
Rscript -e "roxygen2::roxygenise()"
```

3.  Review the generated diff:

``` powershell
git diff -- R/ man/ NAMESPACE
```

For README, vignette, or pkgdown navigation changes, also build the site
locally when possible:

``` r

pkgdown::build_site(preview = FALSE)
```

If pkgdown stops because `docs/` is non-empty and not recognized as a
pkgdown site, remove the local generated site first:

``` r

pkgdown::clean_site(force = TRUE)
pkgdown::build_site(preview = FALSE)
```

In this repository, `docs/` is ignored locally. GitHub Actions deploys
the published pkgdown site to the `gh-pages` branch, so do not stage
local `docs/` files for ordinary documentation updates.

On Windows, local pkgdown builds may also need environment variables for
Pandoc and a writable R cache:

``` powershell
$env:RSTUDIO_PANDOC = "C:\Program Files\RStudio\resources\app\bin\quarto\bin\tools"
$env:R_USER_CACHE_DIR = "C:\Users\Konrai\github\ylistjp\work\r-cache"
```

If the local build fails while contacting `realfavicongenerator.net`,
`cloud.r-project.org`, or Bioconductor, treat that as an environment or
network failure rather than a documentation-source failure. Push the
roxygen and vignette changes and verify the GitHub Actions pkgdown
workflow, which runs in a networked CI environment.

## Tests and Checks

Run unit tests:

``` powershell
Rscript -e "testthat::test_local('.', reporter = 'summary')"
```

Build and check the package:

``` powershell
R CMD build .
R CMD check jpplantnames_0.1.0.tar.gz --no-manual
```

On Windows, if Pandoc is not on `PATH`, set `RSTUDIO_PANDOC` to an
installed Pandoc directory before building vignettes or pkgdown.

Before committing a documentation-only change, check the final file set:

``` powershell
git status --short
```

Commit the edited sources and generated roxygen outputs, such as
`R/*.R`, `man/*.Rd`, and `NAMESPACE` when it changes. Do not commit
`docs/` from a local pkgdown build in the usual workflow.

## Release Checklist

Before pushing a maintenance change:

1.  Update tests for any behavior change.
2.  Update README and both language guides if user-visible behavior
    changes.
3.  Run `roxygen2::roxygenise()` if roxygen comments changed.
4.  Run
    [`testthat::test_local()`](https://testthat.r-lib.org/reference/test_package.html).
5.  Run `R CMD build` and `R CMD check`.
6.  Build pkgdown locally if documentation changed.
7.  Push and verify both GitHub Actions workflows.
8.  Confirm the site at <https://maple60.github.io/jpplantnames/>.
