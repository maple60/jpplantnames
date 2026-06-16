# Return the best accepted WFO Plant List name

Summarise WFO Plant List suggestions into one accepted-name
interpretation per input scientific name. Lookup functions such as
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
handle Japanese name to scientific name lookup; this helper handles
scientific name to WFO candidate, accepted name, WFO ID, rank, and
status checks.

## Usage

``` r
wfo_accepted_name(
  scientific_name,
  rank = "species",
  with_author = TRUE,
  limit = 10,
  cache = TRUE,
  refresh = FALSE,
  delay = 0.2,
  backend = c("api", "local")
)
```

## Arguments

- scientific_name:

  Character vector of scientific names.

- rank:

  Character scalar rank to prefer, usually `"species"`.

- with_author:

  Logical. If `TRUE`, return the accepted name with authors when
  available. If `FALSE`, return the no-author accepted name in
  `accepted_name`.

- limit:

  Integer. Maximum number of WFO suggestions to request per unique
  scientific name.

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

A data frame with one row per input and a clear `match_status`.

## Details

WFO API access is intended for small-scale interactive checks. These
functions do not automatically replace checklist names with WFO accepted
names. Accepted names are database- and release-dependent.

## Examples

``` r
if (FALSE) { # \dontrun{
wfo_accepted_name("Quercus serrata")
wfo_accepted_name("Quercus serrata", with_author = FALSE)
wfo_accepted_name(scientific_name("コナラ"))
} # }
```
