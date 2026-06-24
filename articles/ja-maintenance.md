# メンテナンスガイド

このガイドは、`jpplantnames`
を保守するときに「何を直したい場合、どのファイルを
見ればよいか」を素早く判断するための開発者向けメモです。

English version: [Maintenance
guide](https://maple60.github.io/jpplantnames/articles/maintenance.md)

## どこを直すか

| 直したいこと | 主に見るファイル |
|----|----|
| チェックリストのダウンロード URL、キャッシュファイル名、キャッシュ場所 | `R/cache.R` |
| チェックリスト Excel ファイルの読み込み方法 | `R/load.R` |
| [`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md) の挙動 | `R/lookup.R`, `tests/testthat/test-lookup.R` |
| [`japanese_name_search()`](https://maple60.github.io/jpplantnames/reference/japanese_name_search.md) の検索対象やマッチ規則 | `R/lookup.R`, `tests/testthat/test-lookup.R` |
| [`japanese_name_suggest()`](https://maple60.github.io/jpplantnames/reference/japanese_name_suggest.md) の正規化、順位付け、fuzzy match | `R/lookup.R`, `tests/testthat/test-japanese-name-suggest.R` |
| [`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md) の summary 列や任意の WFO/GBIF 統合 | `R/japanese_name_info.R`, `tests/testthat/test-japanese-name-info.R` |
| WFO の返却列、accepted name の要約、レスポンスキャッシュ | `R/wfo.R`, `tests/testthat/test-wfo.R` |
| GBIF API の返却列や挙動 | `R/gbif.R`, `tests/testthat/test-gbif.R` |
| export する関数 | `R/*.R` の roxygen コメント。`NAMESPACE` と `man/*.Rd` は再生成する |
| パッケージ情報、依存関係、サイト URL | `DESCRIPTION` |
| README と pkgdown トップページ | `README.md` |
| 日本語 README | `README.ja.md` |
| pkgdown のナビゲーションや reference 分類 | `_pkgdown.yml` |
| 使い方ガイド | `vignettes/get-started.qmd`, `vignettes/ja-get-started.qmd` |
| メンテナンスガイド | `vignettes/maintenance.qmd`, `vignettes/ja-maintenance.qmd` |
| パッケージ開発チュートリアル | `vignettes/package-development.qmd`, `vignettes/ja-package-development.qmd` |
| R パッケージチェックの GitHub Actions | `.github/workflows/R-CMD-check.yaml` |
| GitHub Pages / pkgdown deploy | `.github/workflows/pkgdown.yaml` |

## 関数ごとの保守ポイント

### `japanese_name_download()`

実装は `R/cache.R` です。

ここを直す典型例:

- チェックリスト Excel ファイルの URL が変わった。
- キャッシュファイル名を変えたい。
- テスト用 fixture のコピー方法を変えたい。
- キャッシュディレクトリの決め方を変えたい。

返り値は、現在の仕様ではキャッシュ済みファイルパスを invisibly
に返します。 キャッシュ関連のテストは `tests/testthat/test-cache-load.R`
にあります。

### `japanese_name_load()`

実装は `R/load.R` です。

ここを直す典型例:

- チェックリストのシート名や必須列が変わった。
- 読み込み後の整形処理を追加したい。

現在はチェックリスト Excel ファイルの `JN_dataset`
シートを読み込んでいます。
単体テストでは本番の巨大ファイルを直接ダウンロードせず、小さな合成
fixture で列構造を確認します。

### JBIF チェックリストのバージョンを更新する

現在の対象は「維管束植物和名チェックリスト ver. 1.10」です。JBIF
から新版が公開された場合は、 変更範囲が追跡できるように小さく進めます。

1.  JBIF の新版ページ、Excel URL、バージョン表記、引用文を確認する。
2.  新旧の Excel
    ファイルをパッケージキャッシュとは別の場所に保存し、シート名と
    `JN_dataset` の列名差分を確認する。
3.  `R/cache.R` の `CHECKLIST_URL` と `CHECKLIST_CACHE_FILE`
    を更新する。
4.  シート名や必須列が変わった場合は、`R/load.R` の
    `checklist_japanese_name_sheet`、
    `required_checklist_columns`、`normalize_checklist_japanese_name_dataset()`
    を必要最小限で更新する。
5.  `tests/testthat/helper-fixture.R` の合成 Excel fixture
    を新しい列構造に合わせる。
    単体テストでは本番ファイルを直接ダウンロードしない。
6.  広い package check の前に
    [`testthat::test_local()`](https://testthat.r-lib.org/reference/test_package.html)
    を実行する。
7.  `README.md`、`README.ja.md`、日英の使い方ガイド、このメンテナンスガイドの
    バージョン表記、URL、引用文を同期する。

列名差分の確認は、手作業ではなく `readxl` で直接確認します。

``` r

old <- readxl::read_excel("old-checklist.xlsx", sheet = "JN_dataset",
                          n_max = 0, .name_repair = "minimal")
new <- readxl::read_excel("new-checklist.xlsx", sheet = "JN_dataset",
                          n_max = 0, .name_repair = "minimal")
setdiff(names(new), names(old))
setdiff(names(old), names(new))
```

### `scientific_name()`

実装は `R/lookup.R` です。

ここを直す典型例:

- 完全一致のルールを変えたい。
- synonym の扱いを変えたい。
- 見つからない場合の返り値を変えたい。
- 複数候補がある場合の挙動を変えたい。
- 学名だけでなく ID や科名なども返したい。

現在の仕様は保守的です。

- チェックリストの `和名` 列と `別名` 列を完全一致で検索します。
- `ステータス == "標準"` の行だけを使います。
- 見つからない場合は `NA_character_` を返します。
- 標準行が複数ある場合は自動で選ばず、エラーにします。

この仕様を変えた場合は、README、日英の使い方ガイド、テストも一緒に更新します。

### `japanese_name_search()`

実装は `R/lookup.R` です。

ここを直す典型例:

- `field` の選択肢を増やしたい。
- 部分一致の挙動を変えたい。
- ひらがな・カタカナ変換などの正規化を入れたい。
- 候補のランキングを追加したい。

検索機能は、候補を人間が確認できるようにするための関数です。
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
を暗黙の fuzzy lookup
に変えるより、検索候補を明示的に返す設計を優先します。

### `japanese_name_suggest()`

実装は `R/lookup.R` です。

ここを直す典型例:

- 和名の正規化ルールを変えたい。
- 完全一致、部分一致、fuzzy match の並び順を変えたい。
- 既定の `max_distance`、スコア、候補順位を変えたい。
- 任意依存の `stringi` や `stringdist` を使う挙動を変えたい。
- `matched_value`、`distance`、`score`、`match_type`
  などの返却メタデータを変えたい。

この関数は、キャッシュ済みチェックリストの和名列だけを検索します。目的は候補行の提案であり、
[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
の自動補正ではありません。[`scientific_name()`](https://maple60.github.io/jpplantnames/reference/scientific_name.md)
は完全一致で保守的なままにします。 テストは
`tests/testthat/test-japanese-name-suggest.R` にあります。

### `japanese_name_info()`

実装は `R/japanese_name_info.R` です。

ここを直す典型例:

- summary の列や print 表示を変えたい。
- 優先するチェックリスト候補の選び方を変えたい。
- 任意の WFO または GBIF 連携を変えたい。
- 外部 API 失敗時の要約方法を変えたい。
- 非推奨互換 wrapper の
  [`ylist_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
  を変えたい。

既定では、[`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
はキャッシュ済みチェックリストデータだけを使います。 WFO は
`wfo = TRUE`、GBIF は `gbif = TRUE` のときだけ呼びます。WFO と GBIF
の結果は チェックリストの summary
に並べて保持し、チェックリストの学名を上書きしません。外部 API が
失敗した場合は、関数全体を止めず、warning と error status
の行で返します。テストは `tests/testthat/test-japanese-name-info.R`
にあります。

### `wfo_suggest()` と `wfo_accepted_name()`

実装は `R/wfo.R` です。

ここを直す典型例:

- WFO GraphQL endpoint、query、返却列を変えたい。
- accepted name の要約、rank の優先、`with_author` の挙動を変えたい。
- WFO キャッシュのファイル名、保存場所、読み書きの挙動を変えたい。
- `backend = "local"` を実装したい。

WFO へのアクセスは、小規模な任意の外部 API 確認です。`cache = TRUE` では
raw API response を ローカルに保存し、`refresh = TRUE`
では既存キャッシュを無視して再取得します。既定のキャッシュ場所は
`tools::R_user_dir("jpplantnames", which = "cache")/wfo`
で、`options(jpplantnames.wfo_cache_dir = ...)`
を設定すると変更できます。WFO
の結果は和名チェックリストの結果を置き換えません。単体テストでは live
WFO request ではなく、`options(jpplantnames.wfo_graphql = ...)` による
mock response を使います。

### `gbif_match()`

実装は `R/gbif.R` です。

ここを直す典型例:

- GBIF から返す列を増やしたい。
- API エラー時の扱いを変えたい。
- [`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
  が使う任意の GBIF API wrapper の挙動を変えたい。

GBIF の live test は通常 skip
されます。ネットワークテストを明示的に走らせる場合は
`JPPLANTNAMES_RUN_NETWORK_TESTS=true` を設定します。

## 外部 API とキャッシュ

ネットワークに依存する挙動は、examples と tests
で明示的に扱います。チェックリストデータは
ダウンロード後のパッケージキャッシュから読み込みます。[`japanese_name_info()`](https://maple60.github.io/jpplantnames/reference/japanese_name_info.md)
は、WFO または GBIF の確認を明示した場合だけ外部 API を呼びます。

WFO response は上記の引数でキャッシュ・再取得できます。GBIF
にはパッケージ側の response cache が ないため、live GBIF test は opt-in
のままにします。外部 API を追加・変更するときは、単体テストを mock
にし、新しい cache や refresh
の挙動を文書化し、外部データの結果を中心となる
チェックリスト検索から分けて保持します。

## ドキュメントの方針

pkgdown のトップページは `README.md`
から生成されます。そのため、トップページは
英語を正にし、日本語で読みたい人には `README.ja.md`
と日本語ガイドへ誘導します。

関数リファレンスは `R/*.R` の roxygen
コメントから生成します。人間が保守する原本は roxygen
コメントです。`man/` 以下の `.Rd`
ファイルは自動生成物なので、直接編集しません。
引数説明、examples、details、alias、非推奨 wrapper
の説明を変える場合は、関数の近くの roxygen block を直します。

役割分担は次の通りです。

- `README.md`: 英語のトップページ。
- `README.ja.md`: 日本語のトップページ。
- `vignettes/get-started.qmd`: 英語の使い方ガイド。
- `vignettes/ja-get-started.qmd`: 日本語の使い方ガイド。
- `vignettes/maintenance.qmd`: 英語のメンテナンスガイド。
- `vignettes/ja-maintenance.qmd`: 日本語のメンテナンスガイド。
- `vignettes/package-development.qmd`:
  英語のパッケージ開発チュートリアル。
- `vignettes/ja-package-development.qmd`:
  日本語のパッケージ開発チュートリアル。
- `_pkgdown.yml`: サイトのナビゲーション、記事分類、reference 分類。

## ローカルでのドキュメント更新手順

関数リファレンスを変える場合:

1.  `R/*.R` の roxygen コメントを編集します。
2.  reference 用ファイルを再生成します。

``` powershell
Rscript -e "roxygen2::roxygenise()"
```

3.  生成された差分を確認します。

``` powershell
git diff -- R/ man/ NAMESPACE
```

README、vignette、pkgdown のナビゲーションを変えた場合は、可能なら
pkgdown サイトも ローカルでビルドします。

``` r

pkgdown::build_site(preview = FALSE)
```

`docs/` が空ではなく、pkgdown
が作ったサイトとして認識されないというエラーが出た場合は、
ローカル生成物を消してから作り直します。

``` r

pkgdown::clean_site(force = TRUE)
pkgdown::build_site(preview = FALSE)
```

このリポジトリでは `docs/` はローカル確認用で、`.gitignore`
に入っています。公開サイトは GitHub Actions が `gh-pages` ブランチへ
deploy するため、通常のドキュメント更新では ローカルの `docs/` を stage
しません。

Windows でローカル pkgdown build を行う場合、Pandoc と書き込み可能な R
cache を 環境変数で指定する必要があることがあります。

``` powershell
$env:RSTUDIO_PANDOC = "C:\Program Files\RStudio\resources\app\bin\quarto\bin\tools"
$env:R_USER_CACHE_DIR = "C:\Users\Konrai\github\ylistjp\work\r-cache"
```

`realfavicongenerator.net`、`cloud.r-project.org`、Bioconductor
への接続で ローカル build
が失敗する場合は、ドキュメント原本の問題ではなく、ローカル環境または
ネットワーク制限による失敗として扱います。その場合は roxygen と vignette
の変更を push し、 ネットワークのある CI 環境で動く GitHub Actions の
pkgdown workflow を確認します。

## テストと確認

単体テスト:

``` powershell
Rscript -e "testthat::test_local('.', reporter = 'summary')"
```

パッケージ build/check:

``` powershell
R CMD build .
R CMD check jpplantnames_0.1.0.tar.gz --no-manual
```

Windows で Pandoc が `PATH` にない場合は、vignettes や pkgdown の build
前に `RSTUDIO_PANDOC` をインストール済み Pandoc
のディレクトリへ向けます。

ドキュメントだけの変更でも、commit
前には最終的な対象ファイルを確認します。

``` powershell
git status --short
```

commit するのは、編集した原本と roxygen 生成物です。たとえば `R/*.R`、
`man/*.Rd`、変更があれば `NAMESPACE`
を含めます。通常の運用では、ローカルの pkgdown build でできた `docs/` は
commit しません。

## 変更前後のチェックリスト

保守変更を push する前に、次を確認します。

1.  挙動を変えた場合はテストを更新する。
2.  ユーザーに見える挙動を変えた場合は README
    と日英の使い方ガイドを更新する。
3.  roxygen コメントを変えた場合は `roxygen2::roxygenise()` を実行する。
4.  [`testthat::test_local()`](https://testthat.r-lib.org/reference/test_package.html)
    を実行する。
5.  `R CMD build` と `R CMD check` を実行する。
6.  ドキュメントを変えた場合は pkgdown をローカル build する。
7.  push 後に GitHub Actions の 2 つの workflow を確認する。
8.  <https://maple60.github.io/jpplantnames/>
    が更新されているか確認する。
