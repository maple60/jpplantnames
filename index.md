# ylistjp

`ylistjp` is an unofficial R package for looking up scientific plant
names from Japanese plant names using the public tab-delimited data file
from [YList](http://www.ylist.info/), the “植物和名-学名インデックス”.

Documentation site: <https://maple60.github.io/ylistjp/>

日本語で読みたい場合は [日本語
README](https://maple60.github.io/ylistjp/README.ja.html) または
[日本語ガイド](https://maple60.github.io/ylistjp/articles/ja-get-started.html)
を参照してください。

## Installation

``` r

# install.packages("pak")
pak::pak("maple60/ylistjp")
```

## Quick Start

``` r

library(ylistjp)

academic_name("コナラ")
#> [1] "Quercus serrata"

academic_name("コナラ", with_author = TRUE)
#> [1] "Quercus serrata Murray"

ylist_search("コナラ")
```

The first function call that needs YList data downloads the public
tab-delimited file into the user’s local R cache. To refresh the cached
file:

``` r

ylist_download(overwrite = TRUE)
ylist_load(refresh = TRUE)
```

## Guides

- [Usage
  guide](https://maple60.github.io/ylistjp/articles/get-started.html)
- [日本語:
  使い方ガイド](https://maple60.github.io/ylistjp/articles/ja-get-started.html)
- [Maintenance
  guide](https://maple60.github.io/ylistjp/articles/maintenance.html)
- [日本語:
  メンテナンスガイド](https://maple60.github.io/ylistjp/articles/ja-maintenance.html)
- [Function
  reference](https://maple60.github.io/ylistjp/reference/index.html)

## International Name Checks

[`gbif_match()`](https://maple60.github.io/ylistjp/reference/gbif_match.md)
is a small optional helper around the GBIF species match API. It is
intended for checking the scientific name returned from YList against an
international biodiversity data source.

``` r

gbif_match("Quercus serrata")
```

## Data Source and Citation

This package is not affiliated with or endorsed by YList.

When using YList data, cite the original source:

> 米倉浩司・梶田忠 (2003-)「BG Plants
> 和名－学名インデックス」（YList），<http://ylist.info>

The package code is MIT licensed. YList data is not included in the
package and is not covered by this package’s license.
