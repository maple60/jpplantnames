# メンテナンスガイド

このガイドは、`ylistjp`
を保守するときに「何を直したい場合、どのファイルを
見ればよいか」を素早く判断するための開発者向けメモです。

English version: [Maintenance
guide](https://maple60.github.io/ylistjp/articles/maintenance.md)

## どこを直すか

| 直したいこと | 主に見るファイル |
|----|----|
| YList のダウンロード URL、キャッシュファイル名、キャッシュ場所 | `R/cache.R` |
| タブ区切り YList ファイルの読み込み方法 | `R/load.R` |
| [`academic_name()`](https://maple60.github.io/ylistjp/reference/academic_name.md) の挙動 | `R/lookup.R`, `tests/testthat/test-lookup.R` |
| [`ylist_search()`](https://maple60.github.io/ylistjp/reference/ylist_search.md) の検索対象やマッチ規則 | `R/lookup.R`, `tests/testthat/test-lookup.R` |
| GBIF API の返却列や挙動 | `R/gbif.R`, `tests/testthat/test-gbif.R` |
| export する関数 | `NAMESPACE`, `man/` 以下の対応する `.Rd` |
| パッケージ情報、依存関係、サイト URL | `DESCRIPTION` |
| README と pkgdown トップページ | `README.md` |
| 日本語 README | `README.ja.md` |
| pkgdown のナビゲーションや reference 分類 | `_pkgdown.yml` |
| 使い方ガイド | `vignettes/get-started.Rmd`, `vignettes/ja-get-started.Rmd` |
| メンテナンスガイド | `vignettes/maintenance.Rmd`, `vignettes/ja-maintenance.Rmd` |
| R パッケージチェックの GitHub Actions | `.github/workflows/R-CMD-check.yaml` |
| GitHub Pages / pkgdown deploy | `.github/workflows/pkgdown.yaml` |

## 関数ごとの保守ポイント

### `ylist_download()`

実装は `R/cache.R` です。

ここを直す典型例:

- YList の公開タブ区切りファイル URL が変わった。
- キャッシュファイル名を変えたい。
- テスト用 fixture のコピー方法を変えたい。
- キャッシュディレクトリの決め方を変えたい。

返り値は、現在の仕様ではキャッシュ済みファイルパスを invisibly
に返します。 キャッシュ関連のテストは `tests/testthat/test-cache-load.R`
にあります。

### `ylist_load()`

実装は `R/load.R` です。

ここを直す典型例:

- YList ファイルの文字コードが変わった。
- 区切り文字やヘッダーの扱いが変わった。
- 読み込み後の整形処理を追加したい。

現在は YList の公開タブ区切りファイルを CP932 として読み込んでいます。
単体テストでは本番の巨大ファイルを直接ダウンロードせず、小さな合成
fixture で文字コードと列構造を確認します。

### `academic_name()`

実装は `R/lookup.R` です。

ここを直す典型例:

- 完全一致のルールを変えたい。
- synonym の扱いを変えたい。
- 見つからない場合の返り値を変えたい。
- 複数候補がある場合の挙動を変えたい。
- 学名だけでなく ID や科名なども返したい。

現在の仕様は保守的です。

- YList の `和名` 列を完全一致で検索します。
- `ステータス == "標準"` の行だけを使います。
- 見つからない場合は `NA_character_` を返します。
- 標準行が複数ある場合は自動で選ばず、エラーにします。

この仕様を変えた場合は、README、日英の使い方ガイド、テストも一緒に更新します。

### `ylist_search()`

実装は `R/lookup.R` です。

ここを直す典型例:

- `field` の選択肢を増やしたい。
- 部分一致の挙動を変えたい。
- ひらがな・カタカナ変換などの正規化を入れたい。
- 候補のランキングを追加したい。

検索機能は、候補を人間が確認できるようにするための関数です。
[`academic_name()`](https://maple60.github.io/ylistjp/reference/academic_name.md)
を暗黙の fuzzy lookup
に変えるより、検索候補を明示的に返す設計を優先します。

### `gbif_match()`

実装は `R/gbif.R` です。

ここを直す典型例:

- GBIF から返す列を増やしたい。
- API エラー時の扱いを変えたい。
- WFO や Catalogue of Life など別の国際 API を追加したい。

GBIF の live test は通常 skip
されます。ネットワークテストを明示的に走らせる場合は
`YLISTJP_RUN_NETWORK_TESTS=true` を設定します。

## ドキュメントの方針

pkgdown のトップページは `README.md`
から生成されます。そのため、トップページは
英語を正にし、日本語で読みたい人には `README.ja.md`
と日本語ガイドへ誘導します。

役割分担は次の通りです。

- `README.md`: 英語のトップページ。
- `README.ja.md`: 日本語のトップページ。
- `vignettes/get-started.Rmd`: 英語の使い方ガイド。
- `vignettes/ja-get-started.Rmd`: 日本語の使い方ガイド。
- `vignettes/maintenance.Rmd`: 英語のメンテナンスガイド。
- `vignettes/ja-maintenance.Rmd`: 日本語のメンテナンスガイド。
- `_pkgdown.yml`: サイトのナビゲーション、記事分類、reference 分類。

ドキュメントを変えた後は、可能なら pkgdown
サイトをローカルでビルドします。

``` r

pkgdown::build_site(preview = FALSE)
```

## テストと確認

単体テスト:

``` r

testthat::test_local(".", reporter = "summary")
```

パッケージ build/check:

``` sh
R CMD build .
R CMD check ylistjp_0.1.0.tar.gz --no-manual
```

Windows で Pandoc が `PATH` にない場合は、vignettes や pkgdown の build
前に `RSTUDIO_PANDOC` をインストール済み Pandoc
のディレクトリへ向けます。

## 変更前後のチェックリスト

保守変更を push する前に、次を確認します。

1.  挙動を変えた場合はテストを更新する。
2.  ユーザーに見える挙動を変えた場合は README
    と日英の使い方ガイドを更新する。
3.  [`testthat::test_local()`](https://testthat.r-lib.org/reference/test_package.html)
    を実行する。
4.  `R CMD build` と `R CMD check` を実行する。
5.  ドキュメントを変えた場合は pkgdown をローカル build する。
6.  push 後に GitHub Actions の 2 つの workflow を確認する。
7.  <https://maple60.github.io/ylistjp/> が更新されているか確認する。
