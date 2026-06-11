# Using ylistjp

`ylistjp` is an unofficial R package for looking up scientific plant
names from Japanese plant names using YList data.

YList is especially useful when your starting point is a Japanese plant
name, such as `コナラ`, and you want the corresponding scientific name
in a reproducible R workflow.

## Installation

Install the package from GitHub:

``` r

# install.packages("pak")
pak::pak("maple60/ylistjp")
```

Then load it:

``` r

library(ylistjp)
```

## First Lookup

Use
[`academic_name()`](https://maple60.github.io/ylistjp/reference/academic_name.md)
when you have a Japanese plant name and want the standard scientific
name.

``` r

academic_name("コナラ")
#> [1] "Quercus serrata"
```

If you want the author string as recorded in YList, set
`with_author = TRUE`.

``` r

academic_name("コナラ", with_author = TRUE)
#> [1] "Quercus serrata Murray"
```

The function is vectorized:

``` r

academic_name(c("コナラ", "ミズナラ"))
```

## How the Data Is Loaded

`ylistjp` does not bundle or redistribute YList data. The first call
that needs the data downloads the public tab-delimited YList file and
stores it in the user’s local R cache.

You can also download or refresh the file explicitly:

``` r

ylist_download()
ylist_download(overwrite = TRUE)
```

Load the cached data as a regular data frame:

``` r

ylist <- ylist_load()
head(ylist)
```

To force a refresh before loading:

``` r

ylist <- ylist_load(refresh = TRUE)
```

## Exact Lookup Behavior

[`academic_name()`](https://maple60.github.io/ylistjp/reference/academic_name.md)
is intentionally conservative:

- it exact-matches the YList `和名` column;
- it only uses rows where `ステータス` is `標準`;
- it returns `NA_character_` when there is no standard exact match;
- it errors if more than one standard exact match is found, so you can
  inspect the candidates manually.

This behavior is designed for scripts and analyses where silent fuzzy
matching would be risky.

## Searching Candidates

Use
[`ylist_search()`](https://maple60.github.io/ylistjp/reference/ylist_search.md)
when you want to inspect possible matches.

``` r

ylist_search("コナラ")
```

By default,
[`ylist_search()`](https://maple60.github.io/ylistjp/reference/ylist_search.md)
searches Japanese names with partial matching. You can search specific
fields:

``` r

ylist_search("Quercus serrata", field = "scientific")
ylist_search("ナラ", field = "alias")
ylist_search("コナラ", field = "all")
```

Use exact matching when you want only exact candidate rows:

``` r

ylist_search("コナラ", exact = TRUE)
```

## A Practical Workflow

A typical workflow is:

1.  Use
    [`academic_name()`](https://maple60.github.io/ylistjp/reference/academic_name.md)
    for names that should be standard and unambiguous.
2.  Use
    [`ylist_search()`](https://maple60.github.io/ylistjp/reference/ylist_search.md)
    for names that return `NA` or need manual checking.
3.  Keep both the original Japanese name and returned scientific name in
    your analysis table.
4.  Cite YList when you use YList-derived names in a report, paper, or
    dataset.

Example:

``` r

plants <- data.frame(
  japanese_name = c("コナラ", "ミズナラ", "存在しない植物名"),
  stringsAsFactors = FALSE
)

plants$scientific_name <- academic_name(plants$japanese_name)
plants
```

## Checking Names with GBIF

[`gbif_match()`](https://maple60.github.io/ylistjp/reference/gbif_match.md)
is a small optional helper around the GBIF species match API. Use it
after obtaining a scientific name from YList when you want to check how
the name is represented in an international biodiversity data source.

``` r

gbif_match("Quercus serrata")
```

This function requires the suggested package `jsonlite`.

## Data Source and Citation

This package is not affiliated with or endorsed by YList. It is only a
small R interface for working with the public YList tab-delimited data
file.

When using YList data, cite the original source:

> 米倉浩司・梶田忠 (2003-)「BG Plants
> 和名－学名インデックス」（YList），<http://ylist.info>

The package code is MIT licensed. YList data is not included in the
package and is not covered by the package license.
