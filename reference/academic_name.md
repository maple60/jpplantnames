# Look up scientific names from Japanese plant names

Exact-matches Japanese names in the YList `和名` column and returns the
standard scientific name where `ステータス == "標準"`.

## Usage

``` r
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

## Examples

``` r
if (FALSE) { # \dontrun{
academic_name("コナラ")
academic_name("コナラ", with_author = TRUE)
} # }
```
