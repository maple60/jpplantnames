# Using jpplantnames

`jpplantnames` is an unofficial R package for looking up scientific
plant names from Japanese plant names using the Vascular Plant Japanese
Name Checklist ver. 1.10.

The checklist is useful when your starting point is a Japanese plant
name, such as `コナラ`, and you want the corresponding scientific name
in a reproducible R workflow.

## Installation

Install the package from GitHub:

``` r

# install.packages("pak")
pak::pak("maple60/jpplantnames")
```

Then load it:

``` r

library(jpplantnames)
```

## First Lookup

Use
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
when you have a Japanese plant name and want the standard scientific
name.

``` r

scientific_name("コナラ")
#> [1] "Quercus serrata"
```

If you want the author string as recorded in the checklist, set
`with_author = TRUE`.

``` r

scientific_name("コナラ", with_author = TRUE)
#> [1] "Quercus serrata Murray"
```

The function is vectorized:

``` r

scientific_name(c("コナラ", "ミズナラ"))
```

If you want a compact summary from a Japanese name, use
[`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
as a convenient entry point.

``` r

japanese_name_info("コナラ")
```

By default,
[`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
uses only the cached checklist data. It does not call WFO or GBIF unless
you ask for those optional checks.

## How the Data Is Loaded

`jpplantnames` does not bundle or redistribute checklist data. The first
call that needs the data downloads the checklist Excel file and stores
it in the user’s local R cache.

After the checklist has been cached, the standard lookup helpers read
from that local file. Routine calls such as
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md),
[`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md),
and the default
[`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
do not query an external server for every lookup.

You can also download or refresh the file explicitly:

``` r

japanese_name_download()
japanese_name_download(overwrite = TRUE)
```

Load the cached data as a regular data frame:

``` r

checklist <- japanese_name_load()
head(checklist)
```

To force a refresh before loading:

``` r

checklist <- japanese_name_load(refresh = TRUE)
```

## Exact Lookup Behavior

[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
is intentionally conservative:

- it exact-matches the checklist `和名` and `別名` columns;
- it only uses rows where `ステータス` is `標準`;
- it returns `NA_character_` when there is no standard exact match;
- it errors if more than one standard exact match is found, so you can
  inspect the candidates manually.

This behavior is designed for scripts and analyses where silent fuzzy
matching would be risky.

## Searching Candidates

Use
[`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md)
when you want to inspect possible matches.

``` r

japanese_name_search("コナラ")
```

By default,
[`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md)
searches Japanese names with partial matching. You can search specific
fields:

``` r

japanese_name_search("Quercus serrata", field = "scientific")
japanese_name_search("ナラ", field = "alias")
japanese_name_search("コナラ", field = "all")
```

Use exact matching when you want only exact candidate rows:

``` r

japanese_name_search("コナラ", exact = TRUE)
```

## A Practical Workflow

A typical workflow is:

1.  Use
    [`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
    for names that should be standard and unambiguous.
2.  Use
    [`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md)
    for names that return `NA` or need manual checking.
3.  Keep both the original Japanese name and returned scientific name in
    your analysis table.
4.  Cite the checklist when you use checklist-based names in a report,
    paper, or dataset.

Example:

``` r

plants <- data.frame(
  japanese_name = c("コナラ", "ミズナラ", "存在しない植物名"),
  stringsAsFactors = FALSE
)

plants$scientific_name <- scientific_name(plants$japanese_name)
plants
```

## Optional WFO and GBIF Checks

The checklist name is the package’s lookup result.
[`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
can also run optional checks against international name sources:

``` r

japanese_name_info("コナラ", wfo = TRUE)
japanese_name_info("コナラ", wfo = TRUE, gbif = TRUE)
```

These `wfo = TRUE` and `gbif = TRUE` checks depend on external API
availability and the content of those databases. WFO results are
reported as external interpretations; they do not automatically replace
the scientific name returned from the checklist.

[`gbif_match()`](https://maple60.github.io/jpplantnames/reference/gbif_match.md)
is a small optional helper around the GBIF species match API. Use it
after obtaining a scientific name from the checklist when you want to
check how the name is represented in an international biodiversity data
source.

``` r

gbif_match("Quercus serrata")
```

This function requires the suggested package `jsonlite`.

## Data Source and Citation

This package uses the Vascular Plant Japanese Name Checklist ver. 1.10
as the lookup source. The checklist includes YList-derived/update data,
but this package is not affiliated with or endorsed by JBIF, YList, or
the checklist authors.

When using checklist-based results, cite the checklist:

> Yamanouchi, T., Shutoh, K., Osawa, T., Yonekura, K., Kato, S., Shiga,
> T. 2019. A checklist of Japanese plant names
> (https://gbif.jp/activities/checklist/wamei_checklist_110)

The package code is MIT licensed. Checklist data is not included in the
package and is not covered by the package license.
