# Package index

## Overview

- [`jpplantnames`](https://maple60.github.io/jpplantnames/reference/jpplantnames-package.md)
  [`jpplantnames-package`](https://maple60.github.io/jpplantnames/reference/jpplantnames-package.md)
  : Unofficial Japanese Plant Name Lookup Tools

## Data access

Download and load the checklist Excel file.

- [`japanese_name_download()`](https://maple60.github.io/jpplantnames/reference/japanese_name_download.md)
  [`ylist_download()`](https://maple60.github.io/jpplantnames/reference/japanese_name_download.md)
  : Download the Japanese-name checklist data file
- [`japanese_name_load()`](https://maple60.github.io/jpplantnames/reference/japanese_name_load.md)
  [`ylist_load()`](https://maple60.github.io/jpplantnames/reference/japanese_name_load.md)
  : Load cached Japanese-name checklist data

## Name lookup

Search cached checklist rows and retrieve scientific names.

- [`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
  [`academic_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
  : Look up scientific names from Japanese plant names
- [`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md)
  [`ylist_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md)
  : Search cached checklist rows
- [`japanese_name_suggest()`](https://maple60.github.io/jpplantnames/reference/japanese_name_suggest.md)
  [`ylist_suggest()`](https://maple60.github.io/jpplantnames/reference/japanese_name_suggest.md)
  : Suggest lookup rows for an approximate Japanese plant name
- [`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
  [`print(`*`<japanese_name_info>`*`)`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
  [`ylist_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
  [`print(`*`<ylist_info>`*`)`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
  : Get a high-level Japanese-name checklist summary

## International checks

Optional helpers for checking scientific names against WFO and GBIF.

- [`wfo_suggest()`](https://maple60.github.io/jpplantnames/reference/wfo_suggest.md)
  : Suggest WFO Plant List names for a scientific name
- [`wfo_accepted_name()`](https://maple60.github.io/jpplantnames/reference/wfo_accepted_name.md)
  : Return the best accepted WFO Plant List name
- [`gbif_match()`](https://maple60.github.io/jpplantnames/reference/gbif_match.md)
  : Match scientific names against GBIF
