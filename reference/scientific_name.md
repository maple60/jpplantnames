# Look up scientific names from Japanese plant names

Exact-matches Japanese names in the cached checklist data and returns
the scientific name.

## Usage

``` r
scientific_name(name, with_author = FALSE)

academic_name(name, with_author = FALSE)
```

## Arguments

- name:

  Character vector of Japanese plant names.

- with_author:

  Logical. If `TRUE`, return `学名 withAuthor`; otherwise return `学名`.

## Value

A character vector with one result per input name. Missing names return
`NA_character_`.

## Details

`academic_name()` is retained as a deprecated compatibility wrapper. Use
`scientific_name()` for new code.

## Examples

``` r
if (FALSE) { # \dontrun{
scientific_name("コナラ")
#> [1] "Quercus serrata"

scientific_name("コナラ", with_author = TRUE)
#> [1] "Quercus serrata Murray"
} # }
```
