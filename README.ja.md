# ylistjp

`ylistjp` は、[YList](http://www.ylist.info/)（植物和名-学名インデックス）の
公開タブ区切りデータを利用して、和名から学名を調べるための非公式 R パッケージです。

ドキュメントサイト:
[https://maple60.github.io/ylistjp/](https://maple60.github.io/ylistjp/)

English README: [https://maple60.github.io/ylistjp/](https://maple60.github.io/ylistjp/)

## インストール

```r
# install.packages("pak")
pak::pak("maple60/ylistjp")
```

## すぐに使う

```r
library(ylistjp)

academic_name("コナラ")
#> [1] "Quercus serrata"

academic_name("コナラ", with_author = TRUE)
#> [1] "Quercus serrata Murray"

ylist_search("コナラ")
```

最初に YList データが必要になった時点で、公開タブ区切りファイルをユーザーの
R キャッシュへダウンロードします。その後の `academic_name()`、`ylist_search()`、
`ylist_load()` はローカルのキャッシュファイルを読むため、検索のたびに YList
サーバーへ問い合わせることはありません。これにより、YList への負荷は最小限に
抑えられます。キャッシュを明示的に更新したい場合は次のようにします。

```r
ylist_download(overwrite = TRUE)
ylist_load(refresh = TRUE)
```

`gbif_match()` は別扱いで、実行時に GBIF API へ問い合わせます。

## ガイド

- [日本語: 使い方ガイド](https://maple60.github.io/ylistjp/articles/ja-get-started.html)
- [English: Usage guide](https://maple60.github.io/ylistjp/articles/get-started.html)
- [日本語: メンテナンスガイド](https://maple60.github.io/ylistjp/articles/ja-maintenance.html)
- [English: Maintenance guide](https://maple60.github.io/ylistjp/articles/maintenance.html)
- [関数リファレンス](https://maple60.github.io/ylistjp/reference/index.html)

## 国際的な学名確認

`gbif_match()` は GBIF species match API を呼び出す薄い補助関数です。
YList から得た学名を国際的な生物多様性データソースで確認したい場合に使います。

```r
gbif_match("Quercus serrata")
```

## データソースと引用

`ylistjp` は YList の公式パッケージではなく、YList から承認・推奨されたものでもありません。

YList データを利用する場合は、YList 本体を引用してください。

> 米倉浩司・梶田忠 (2003-)「BG Plants 和名－学名インデックス」（YList），http://ylist.info

このパッケージのコードは MIT ライセンスです。ただし、YList データはパッケージに同梱しておらず、
このパッケージのライセンス対象ではありません。
