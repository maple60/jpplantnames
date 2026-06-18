# Suggest WFO Plant List names for a scientific name

Query the WFO Plant List GraphQL API for candidate names. This is a
small interactive helper for checking scientific names, such as names
returned by
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
or
[`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md).
It does not change checklist lookup results.

## Usage

``` r
wfo_suggest(
  scientific_name,
  limit = 10,
  rank = NULL,
  cache = TRUE,
  refresh = FALSE,
  delay = 0.2,
  backend = c("api", "local")
)
```

## Arguments

- scientific_name:

  Character vector of scientific names.

- limit:

  Integer. Maximum number of WFO suggestions to request per unique
  scientific name.

- rank:

  Optional character scalar. If supplied, candidate rows are filtered by
  WFO rank after retrieval, for example `"species"`, `"subspecies"`, or
  `"variety"`.

- cache:

  Logical. If `TRUE`, raw API responses are cached locally.

- refresh:

  Logical. If `TRUE`, ignore an existing cached response and fetch from
  the WFO API again.

- delay:

  Numeric. Seconds to wait between uncached API requests.

- backend:

  Character. Only `"api"` is implemented. `"local"` is reserved for
  future WFO release support.

## Value

A data frame with WFO candidate names, accepted-name fields, rank,
status, role, and cache status.

## Details

WFO accepted names are database- and release-dependent. For large-scale
or reproducible workflows, use cached results and record the WFO release
or use a future local WFO release workflow.

## Examples

``` r
if (FALSE) { # \dontrun{
wfo_suggest("Quercus serrata")
wfo_suggest(scientific_name("\u30b3\u30ca\u30e9"))
} # }
```
