# Suggest lookup rows for an approximate Japanese plant name

`japanese_name_suggest()` is a small interactive helper for finding
likely lookup rows before converting Japanese names to scientific names.
It searches only the cached lookup Japanese-name column and does not
change or autocorrect
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
results.

## Usage

``` r
japanese_name_suggest(query, n = 10, max_distance = NULL)

ylist_suggest(query, n = 10, max_distance = NULL)
```

## Arguments

- query:

  Character scalar Japanese plant name to search for.

- n:

  Maximum number of candidate rows to return.

- max_distance:

  Maximum string distance for fuzzy matches. If `NULL`, the default is 1
  for normalized queries with 3 or fewer characters and 2 for longer
  queries.

## Value

A data frame containing lookup rows plus `query`, `matched_value`,
`distance`, `score`, and `match_type`.

## Details

`ylist_suggest()` is retained as a deprecated compatibility wrapper. Use
`japanese_name_suggest()` for new code.

## Examples

``` r
if (FALSE) { # \dontrun{
japanese_name_suggest("\u30b3\u30ca\u30e9")
japanese_name_suggest("\u30ca\u30e9")
} # }
```
