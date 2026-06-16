# Building jpplantnames as an R package

This article explains how `jpplantnames` is organized as a small R
package. It is a worked example for people who want to learn how an R
package can turn a useful public data source into a reproducible
analysis tool.

For Japanese, see [日本語:
パッケージ開発チュートリアル](https://maple60.github.io/jpplantnames/articles/ja-package-development.md).

## Start from a Small Problem

The original goal was simple:

``` r

scientific_name("コナラ")
#> [1] "Quercus serrata"
```

That small API hides several important package-design decisions:

- the package is an unofficial wrapper around the Vascular Plant
  Japanese Name Checklist ver. 1.10;
- checklist data is not redistributed inside the package;
- the checklist Excel file is downloaded only when needed;
- repeated lookup uses the user’s local cache;
- exact lookup is conservative, so ambiguous names are not silently
  guessed;
- international checking is optional and kept separate from the
  checklist lookup.

This is a good package-sized problem because the public API is small,
but it still touches data access, encoding, caching, tests,
documentation, and GitHub Actions.

## Package Skeleton

`jpplantnames` follows the standard structure used by many R packages.

| Path | Role in this package |
|----|----|
| `DESCRIPTION` | Package metadata, dependencies, URLs, and vignette settings. |
| `NAMESPACE` | Exported user-facing functions. |
| `R/` | Implementation code for cache, loading, lookup, and GBIF helpers. |
| `man/` | Function reference files generated from roxygen comments. |
| `tests/testthat/` | Unit tests and synthetic checklist fixtures. |
| `vignettes/` | Longer pkgdown articles such as usage and maintenance guides. |
| `_pkgdown.yml` | Documentation-site navigation and reference grouping. |
| `.github/workflows/` | GitHub Actions for R package check and pkgdown deployment. |

For a small package, this structure is enough. The key is to keep each
directory responsible for one kind of work: code in `R/`, tests in
`tests/`, longer documentation in `vignettes/`, and automation in
`.github/`.

## Design the Public API First

The core user workflow is:

``` r

library(jpplantnames)

scientific_name("コナラ")
scientific_name("コナラ", with_author = TRUE)
japanese_name_search("コナラ")
```

The package then exposes a few focused functions around that workflow:

| Function | Purpose |
|----|----|
| [`japanese_name_download()`](https://maple60.github.io/jpplantnames/reference/japanese_name_download.md) | Download the checklist Excel file into the user cache. |
| [`japanese_name_load()`](https://maple60.github.io/jpplantnames/reference/japanese_name_load.md) | Read the cached file as a `data.frame`. |
| [`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md) | Return the standard scientific name for an exact Japanese-name match. |
| [`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md) | Return candidate rows for manual inspection. |
| [`gbif_match()`](https://maple60.github.io/jpplantnames/reference/gbif_match.md) | Optionally check a scientific name against GBIF. |

This split keeps the simple use case simple, while still allowing
advanced users to inspect the underlying data.

## Keep Checklist Data Outside the Package

`jpplantnames` does not bundle checklist data. Instead, the data flow
is:

1.  [`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md),
    [`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md),
    or
    [`japanese_name_load()`](https://maple60.github.io/jpplantnames/reference/japanese_name_load.md)
    needs checklist data.
2.  If no cached file exists,
    [`japanese_name_download()`](https://maple60.github.io/jpplantnames/reference/japanese_name_download.md)
    downloads the checklist Excel file.
3.  The file is saved under the user’s R cache directory.
4.  Later lookups read the cached file instead of contacting the
    checklist server.

This design matters for two reasons. First, the package code can be MIT
licensed without redistributing checklist data. Second, repeated
analysis does not send a request to the checklist server for every
lookup.

Users can refresh the local copy intentionally:

``` r

japanese_name_download(overwrite = TRUE)
japanese_name_load(refresh = TRUE)
```

## Read the Checklist Excel File Explicitly

The checklist is read from the `JN_dataset` sheet with `readxl`:

``` r

readxl::read_excel(
  path = path,
  sheet = "JN_dataset",
  col_types = "text"
)
```

This is one of the most important implementation details. The package
normalizes the checklist columns into the stable lookup columns used
internally, such as `和名`, `別名`, `学名`, and `学名 withAuthor`.

The package stores column names internally with Unicode escapes where
that makes the source code safer to edit across environments.

## Make Lookup Conservative

[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
is designed for reproducible analysis, not fuzzy search. Its contract is
intentionally narrow:

- exact-match the checklist `和名` and `別名` columns;
- use only rows where `ステータス == "標準"`;
- return `NA_character_` when no standard exact match exists;
- error when multiple standard exact matches exist.

That behavior prevents a script from silently choosing a questionable
name. When a name is ambiguous, the user should inspect candidates with
[`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md).

## Test with Synthetic Fixtures

Unit tests should not download the full checklist file. Instead,
`jpplantnames` uses a small synthetic fixture that contains just enough
rows to test behavior:

- Excel sheet parsing;
- common-name versus alias lookup;
- no-hit handling;
- ambiguity errors;
- cache reuse and refresh behavior.

Network tests are kept optional. GBIF and checklist live checks are
useful as smoke tests, but they should not be required for every local
test or every pull request.

## Build Documentation with pkgdown

The documentation site is built with pkgdown:

- `README.md` becomes the English home page;
- `README.ja.md` provides the Japanese landing page;
- `vignettes/*.Rmd` become article pages;
- `_pkgdown.yml` controls navigation and reference grouping.

GitHub Actions runs pkgdown and publishes the generated site to GitHub
Pages. This keeps the package documentation close to the code and makes
every pushed change reproducible.

## Practical Extension Ideas

Good next features should preserve the conservative default behavior:

- add explicit hiragana-to-katakana or width normalization before
  searching;
- add richer candidate ranking to
  [`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md);
- add optional checks for WFO or Catalogue of Life;
- expose more metadata from the checklist when users need audit trails;
- add a small article showing how to join
  [`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
  results to a data frame.

The safest pattern is to make exploratory features explicit in search or
helper functions, while keeping
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
predictable for scripts.

## What to Read Next

- [Usage
  guide](https://maple60.github.io/jpplantnames/articles/get-started.md)
  explains how to use the package.
- [Maintenance
  guide](https://maple60.github.io/jpplantnames/articles/maintenance.md)
  maps common changes to the files to edit.
- [Function
  reference](https://maple60.github.io/jpplantnames/reference/index.md)
  documents each exported function.
