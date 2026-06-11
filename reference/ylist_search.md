# Search YList rows

Search YList rows by Japanese name, scientific name, alias, or all of
those fields.

## Usage

``` r
ylist_search(query, field = c("japanese", "scientific", "alias", "all"), exact = FALSE)
```

## Arguments

- query:

  Character scalar to search for.

- field:

  Field to search: `japanese`, `scientific`, `alias`, or `all`.

- exact:

  Logical. If `TRUE`, use exact matching; otherwise use partial
  fixed-string matching.

## Value

A data frame of matching YList rows.
