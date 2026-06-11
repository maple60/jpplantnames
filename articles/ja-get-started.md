# ylistjp の使い方

`ylistjp` は、YList（植物和名-学名インデックス）の公開タブ区切りデータを
R から扱いやすくするための非公式パッケージです。

「コナラ」のような和名から、解析や表作成で使う学名を再現可能な形で取得する
ことを目的にしています。

## インストール

GitHub からインストールします。

``` r

# install.packages("pak")
pak::pak("maple60/ylistjp")
```

読み込みます。

``` r

library(ylistjp)
```

## まず和名から学名を調べる

和名から標準的な学名を取得するには
[`academic_name()`](https://maple60.github.io/ylistjp/reference/academic_name.md)
を使います。

``` r

academic_name("コナラ")
#> [1] "Quercus serrata"
```

命名者付きの学名が必要な場合は `with_author = TRUE` を指定します。

``` r

academic_name("コナラ", with_author = TRUE)
#> [1] "Quercus serrata Murray"
```

複数の和名をまとめて渡すこともできます。

``` r

academic_name(c("コナラ", "ミズナラ"))
```

## YList データの取得とキャッシュ

`ylistjp` は YList
データをパッケージ内に同梱しません。最初にデータが必要に
なった時点で、YList の公開タブ区切りファイルをユーザーの R キャッシュへ
ダウンロードして読み込みます。

明示的にダウンロードしたい場合は次のようにします。

``` r

ylist_download()
```

既存のキャッシュを更新したい場合は `overwrite = TRUE` を使います。

``` r

ylist_download(overwrite = TRUE)
```

データ全体を `data.frame` として読み込みたい場合は
[`ylist_load()`](https://maple60.github.io/ylistjp/reference/ylist_load.md)
を使います。

``` r

ylist <- ylist_load()
head(ylist)
```

読み込み前に必ず再取得したい場合は `refresh = TRUE` を指定します。

``` r

ylist <- ylist_load(refresh = TRUE)
```

## `academic_name()` の考え方

[`academic_name()`](https://maple60.github.io/ylistjp/reference/academic_name.md)
は、解析で使いやすいように保守的な動作にしています。

- YList の `和名` 列を完全一致で検索します。
- `ステータス` が `標準` の行だけを使います。
- 見つからない場合は `NA_character_` を返します。
- 標準行が複数見つかった場合は、自動で一つに決めずエラーにします。

この挙動にしている理由は、学名の対応付けで曖昧な候補を静かに採用すると、
後の解析や報告で誤りに気づきにくくなるためです。

## 候補を確認する

部分一致や別名も含めて候補を確認したい場合は
[`ylist_search()`](https://maple60.github.io/ylistjp/reference/ylist_search.md)
を使います。

``` r

ylist_search("コナラ")
```

検索対象の列を指定できます。

``` r

# 学名から検索
ylist_search("Quercus serrata", field = "scientific")

# 別名から検索
ylist_search("ナラ", field = "alias")

# 和名・別名・学名をまとめて検索
ylist_search("コナラ", field = "all")
```

完全一致で候補を確認したい場合は `exact = TRUE` を指定します。

``` r

ylist_search("コナラ", exact = TRUE)
```

## 実用的なワークフロー

データ整理では、次のような流れにすると扱いやすくなります。

1.  和名リストに対して
    [`academic_name()`](https://maple60.github.io/ylistjp/reference/academic_name.md)
    を使い、標準学名を付与します。
2.  `NA` になったものや確認が必要なものを
    [`ylist_search()`](https://maple60.github.io/ylistjp/reference/ylist_search.md)
    で調べます。
3.  元の和名と取得した学名を両方残します。
4.  論文、報告書、公開データで使う場合は YList を引用します。

例:

``` r

plants <- data.frame(
  japanese_name = c("コナラ", "ミズナラ", "存在しない植物名"),
  stringsAsFactors = FALSE
)

plants$scientific_name <- academic_name(plants$japanese_name)
plants
```

## GBIF で国際的な学名情報を確認する

YList から得た学名を国際的なデータベースと照合したい場合は、
[`gbif_match()`](https://maple60.github.io/ylistjp/reference/gbif_match.md)
を使えます。

``` r

gbif_match("Quercus serrata")
```

これは GBIF species match API を呼び出す薄い補助関数です。利用には
`jsonlite` パッケージが必要です。

## データソースと引用

`ylistjp` は YList の公式パッケージではなく、YList から承認・推奨された
ものでもありません。YList の公開タブ区切りデータを R から扱いやすくする
ための小さな補助パッケージです。

YList データを利用する場合は、YList 本体を引用してください。

> 米倉浩司・梶田忠 (2003-)「BG Plants
> 和名－学名インデックス」（YList），<http://ylist.info>

このパッケージのコードは MIT ライセンスです。ただし、YList データは
パッケージに同梱しておらず、このパッケージのライセンス対象ではありません。
