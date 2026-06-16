# jpplantnames

`jpplantnames` is an unofficial R package for looking up scientific
plant names from Japanese plant names using the Vascular Plant Japanese
Name Checklist ver. 1.10 published by
[JBIF](https://gbif.jp/activities/checklist/wamei_checklist_110/).

Documentation site: <https://maple60.github.io/jpplantnames/>

日本語で読みたい場合は [日本語
README](https://maple60.github.io/jpplantnames/README.ja.html) または
[日本語ガイド](https://maple60.github.io/jpplantnames/articles/ja-get-started.html)
を参照してください。

## Installation

``` r

# install.packages("pak")
pak::pak("maple60/jpplantnames")
```

## Quick Start

``` r

library(jpplantnames)

japanese_name_info("コナラ")

scientific_name("コナラ")
#> [1] "Quercus serrata"

scientific_name("コナラ", with_author = TRUE)
#> [1] "Quercus serrata Murray"

japanese_name_search("コナラ")
```

The first function call that needs checklist data downloads the Excel
file into the user’s local R cache. After that,
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md),
[`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md),
and
[`japanese_name_load()`](https://maple60.github.io/jpplantnames/reference/japanese_name_load.md)
read from the cached local file and do not query an external server for
every lookup. To refresh the cached file intentionally:

``` r

japanese_name_download(overwrite = TRUE)
japanese_name_load(refresh = TRUE)
```

[`gbif_match()`](https://maple60.github.io/jpplantnames/reference/gbif_match.md)
is separate: it calls the GBIF API when you run it.

[`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
is the recommended convenient entry point when you want a compact
summary. By default it uses only cached checklist data. WFO and GBIF
checks are optional and may depend on external database content and API
availability:

``` r

japanese_name_info("コナラ", wfo = TRUE)
japanese_name_info("コナラ", wfo = TRUE, gbif = TRUE)
```

## Guides

- [Usage
  guide](https://maple60.github.io/jpplantnames/articles/get-started.html)
- [日本語:
  使い方ガイド](https://maple60.github.io/jpplantnames/articles/ja-get-started.html)
- [Maintenance
  guide](https://maple60.github.io/jpplantnames/articles/maintenance.html)
- [日本語:
  メンテナンスガイド](https://maple60.github.io/jpplantnames/articles/ja-maintenance.html)
- [Package development
  tutorial](https://maple60.github.io/jpplantnames/articles/package-development.html)
- [日本語:
  パッケージ開発チュートリアル](https://maple60.github.io/jpplantnames/articles/ja-package-development.html)
- [Function
  reference](https://maple60.github.io/jpplantnames/reference/index.html)

## International Name Checks

### WFO Plant List checks

[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
returns the checklist scientific name.
[`wfo_suggest()`](https://maple60.github.io/jpplantnames/reference/wfo_suggest.md)
checks WFO candidate names, and
[`wfo_accepted_name()`](https://maple60.github.io/jpplantnames/reference/wfo_accepted_name.md)
summarizes the best WFO accepted-name interpretation. These functions do
not change checklist lookup results. WFO API use should stay
small-scale; for larger workflows, keep caching enabled and record the
WFO release or version used.

``` r

sci <- scientific_name("コナラ")
sci
#> [1] "Quercus serrata"

wfo_suggest(sci)
wfo_accepted_name(sci)
```

### GBIF checks

[`gbif_match()`](https://maple60.github.io/jpplantnames/reference/gbif_match.md)
is a small optional helper around the GBIF species match API. It is
intended for checking the scientific name returned from the checklist
lookup against an international biodiversity data source.

``` r

gbif_match("Quercus serrata")
```

## Data Source and Citation

This package uses the Vascular Plant Japanese Name Checklist ver. 1.10
as the lookup source. The checklist includes YList-derived/update data,
but this package is not affiliated with or endorsed by JBIF, YList, or
the checklist authors.

When using checklist-based results, cite the checklist:

> Yamanouchi, T., Shutoh, K., Osawa, T., Yonekura, K., Kato, S., Shiga,
> T. 2019. A checklist of Japanese plant names
> (<https://gbif.jp/activities/checklist/wamei_checklist_110>)

The package code is MIT licensed. Checklist data is not included in the
package and is not covered by this package’s license.

The older
[`academic_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
and `ylist_*()` function names are retained as deprecated compatibility
wrappers.
