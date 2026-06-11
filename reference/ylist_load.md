# Load cached YList data

Loads the cached YList tab-delimited data as a data frame. If the cache
does not exist, the public data file is downloaded first.

## Usage

``` r
ylist_load(refresh = FALSE)
```

## Arguments

- refresh:

  Logical. If `TRUE`, redownload the YList data before loading.

## Value

A data frame containing YList rows.
