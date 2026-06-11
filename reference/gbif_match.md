# Match scientific names against GBIF

Thin helper around the GBIF species match API.

## Usage

``` r
gbif_match(scientific_name)
```

## Arguments

- scientific_name:

  Character vector of scientific names.

## Value

A data frame with selected GBIF match fields.

## Examples

``` r
if (FALSE) { # \dontrun{
gbif_match("Quercus serrata")
} # }
```
