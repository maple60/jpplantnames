# Get a high-level Japanese-name checklist summary

`japanese_name_info()` is a convenient wrapper for users who want a
compact, browser-like summary from a Japanese plant name. It keeps the
cached Japanese-name checklist lookup separate from WFO or GBIF checks,
which are only run when explicitly requested.

## Usage

``` r
japanese_name_info(
  name,
  with_author = TRUE,
  wfo = FALSE,
  gbif = FALSE,
  rank = "species",
  limit = 10,
  cache = TRUE,
  refresh = FALSE,
  delay = 0.2,
  ...
)

# S3 method for class 'japanese_name_info'
print(x, ...)

ylist_info(
  name,
  with_author = TRUE,
  wfo = FALSE,
  gbif = FALSE,
  rank = "species",
  limit = 10,
  cache = TRUE,
  refresh = FALSE,
  delay = 0.2,
  ...
)

# S3 method for class 'ylist_info'
print(x, ...)
```

## Arguments

- name:

  Character vector of Japanese plant names.

- with_author:

  Logical. If `TRUE`, print and return WFO accepted names with authors
  where available.

- wfo:

  Logical. If `TRUE`, check the preferred checklist scientific name with
  [`wfo_accepted_name()`](https://maple60.github.io/jpplantnames/reference/wfo_accepted_name.md).

- gbif:

  Logical. If `TRUE`, check the preferred checklist scientific name with
  [`gbif_match()`](https://maple60.github.io/jpplantnames/reference/gbif_match.md).

- rank:

  Character scalar rank to prefer for WFO checks.

- limit:

  Integer. Maximum number of WFO suggestions to request per unique
  scientific name.

- cache:

  Logical. If `TRUE`, use the existing WFO response cache.

- refresh:

  Logical. If `TRUE`, ignore existing cached WFO responses.

- delay:

  Numeric. Seconds to wait between uncached WFO API requests.

- ...:

  Additional arguments passed to
  [`wfo_accepted_name()`](https://maple60.github.io/jpplantnames/reference/wfo_accepted_name.md)
  when `wfo = TRUE`.

- x:

  A `japanese_name_info` object.

## Value

A named list with class `"japanese_name_info"` containing:

- `query`: the original input vector.

- `summary`: one summary row per input name.

- `japanese_name`: checklist candidate rows with input metadata.

- `ylist`: deprecated compatibility alias for `japanese_name`.

- `wfo`: WFO accepted-name rows, or `NULL`.

- `gbif`: GBIF match rows, or `NULL`.

## Details

The summary keeps the preferred checklist match separate from optional
WFO and GBIF checks. Alternative checklist candidate rows are kept in
`x$japanese_name`; `x$ylist` is retained as a deprecated compatibility
alias. WFO and GBIF results do not overwrite checklist names.

`ylist_info()` is retained as a deprecated compatibility wrapper. Use
`japanese_name_info()` for new code.

## Examples

``` r
if (FALSE) { # \dontrun{
japanese_name_info("コナラ")
japanese_name_info(c("コナラ", "ミズナラ"))

japanese_name_info("コナラ", wfo = TRUE)
japanese_name_info("コナラ", wfo = TRUE, gbif = TRUE)
} # }
```
