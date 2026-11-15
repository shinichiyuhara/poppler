# poppler（fork、`streamorder`）脅威モデル（2026-11-16）

規約: `~/Developer/Claude/Conventions/security-audit-conventions.jp.md` v1.3 第1段。
対象 commit: `d54eb914f2f7725edce5f93fff20362df40b998d`（`streamorder` ブランチの HEAD＝tag `poppler-26.11.0-sy.1`）。

**この repo は GitHub に公開している**（`origin`）。routine の `fork-sync` は上流の新しい版を merge すると
`streamorder` を自動で push するので、この記録も次の取り込みで公開される。そのため手元の絶対パス・メールアドレス・
蔵書の書名は書かない（`VENDORED.md`・`vendored.json`・`security-assessments.json` と同じ考え）。

## 1. どんなものか

- 上流 [Poppler](https://gitlab.freedesktop.org/poppler/poppler) の **fork**。上流の各リリースに、`pdftotext` の
  `-streamorder`（語の組み立ては既定のまま、出力だけ content stream の描画順にする）を足したもの。版は
  `poppler-X.Y.Z-sy.N`。上流の tag（`poppler-X.Y.Z`、上流の署名つき）は変えずに持つ。
- **fork が変えたもの**（`git diff poppler-26.11.0 HEAD`、7 ファイル +577／−1 行）:
  - `poppler/TextOutputDev.{cc,h}`: `TextStreamItem`・`TextPage::streamItems()`（約 220 行。語を描画順に並べ、
    縦組の 1 字ずつの列・ルビ・圏点・縦中横・柱を行につなぐ）、`dump()` の `streamOrder` の分岐、
    `TextWordList` の `streamOrder` の分岐、`TextOutputDev::setStreamOrder()`・`makeStreamItems()`
  - `utils/pdftotext.cc`: `-streamorder` の旗、`printTSVStream()`（`-tsv` と組み合わせたときの出力）
  - `fork/build-pdftotext.sh`（`pdftotext` だけをビルド）・`fork/sync-verify.sh`（取り込み後の出力の比較）
  - `.github/README.md`・`CHANGELOG-streamorder.md`（文書）
- 上流のコード（約 860 ファイル）は**読まない**。上流の既知の CVE・security fix と照らすだけにする（§4）。

### 配り方と利用側

- **バイナリは配らない**。各 Mac で利用側の台本が、固定した tag と commit を GitHub から clone し、
  `fork/build-pdftotext.sh` で `pdftotext` だけをビルドして、利用側の Application Support に
  `pdftotext-stream` と `libpoppler.NNN.dylib` を置く（`install_name_tool` で `@loader_path`、ad-hoc 署名、
  hardened runtime なし）。PATH には入れない。`libpoppler` は Homebrew の freetype・fontconfig・libpng・jpeg-turbo・
  openjpeg・brotli・harfbuzz を絶対パスで読む（2026-11-16 に `otool -L` で確認）。
- 利用側（`vendored.json` の `consumers`、2026-11-16 に各 repo の main で確認。どちらも `poppler-26.11.0-sy.1`＝
  `d54eb914f` に固定し、入っている `pdftotext-stream` も 26.11.0）:

| 利用側 | 置き場 | 呼び方 | 信用できない入力 | 守り |
|---|---|---|---|---|
| Zeteion（全文索引） | `~/Library/Application Support/Zeteion/poppler-stream/` | 索引作り（フォルダの監視で**自動**）: `-streamorder -enc UTF-8 -q <絶対パス> -`。余白の数字: `-q -bbox-layout`（`-streamorder` なし） | 蔵書の PDF（ダウンロードしたものを含む） | `sandbox-exec`（読めるのはその PDF 1 つと道具の置き場・書けない・通信なし、`ToolSandbox.swift`）、watchdog 300 秒、出力 512 MiB で打ち切り |
| PDFViewer | `~/Library/Application Support/PDFViewer/poppler-stream/` | PDF を開くと**自動**: `-f -l -enc UTF-8 -streamorder` と、同じ範囲の `-tsv`（`printTSVStream` を通る） | 利用者が開いた PDF | `sandbox-exec`（`ToolProcess`）、300 秒、出力の上限、取り消し |

## 2. 守るもの

1. **利用者の Mac で任意のコードが動かないこと**: `pdftotext-stream` は細工した PDF を、利用者の操作なしに
   （索引作り・開いただけで）読む。fork が足したコードがメモリ破壊を起こさないこと。
2. **利用側が止まらないこと**: 細工した PDF 1 つで、索引作りや表示が長く止まる・メモリを使い切ることがないこと。
3. **ビルドと配り方が改ざんされないこと**: 固定した commit だけがビルドされ、入れ替わらないこと。上流の取り込みで、
   悪いコードが自動で入って利用側まで届かないこと。
4. **上流の security fix が遅れずに届くこと**: fork であるがゆえに、`brew upgrade poppler` の修正は届かない。

## 3. 攻撃面（信用できない入力）

信用度: A＝インターネットの誰でも／B＝利用者が開いたもの／C＝同じ Mac の別プロセス／D＝利用者の設定・操作。

| ID | 攻撃面 | 入口のファイル | 信用度 | 想定する攻撃 | 第2段で見ること |
|---|---|---|---|---|---|
| S1 | fork が足した語の並べ替え | `poppler/TextOutputDev.cc` の `TextPage::streamItems()`・`dump()` の `streamOrder` 分岐・`TextWordList`、`TextOutputDev.h` | B | 細工した PDF の語の配置（空の語・大きさ 0 や NaN・回転・極端な数）で、範囲外の読み・ぶら下がり参照・終わらない／二乗のループ | 全部の添字・`chars.front()/back()`・`n-1`・ループの上限・計算量 |
| S2 | fork が足した出力 | `utils/pdftotext.cc` の `-streamorder`・`printTSVStream()`、`-bbox` での `makeWordList()` | B | 語の並びから TSV の block・line を作るときの範囲外、書式文字列、出力の取り違え | 添字、`appendf` の書式、上流の `printTSVBBox` との違い |
| S3 | ビルド | `fork/build-pdftotext.sh`（と、それを呼ぶ利用側の `scripts/build-pdftotext-stream.sh`） | D（中身は A の上流＋GitHub） | ビルドの設定の誤り（効かない旗で、思っていない decoder が入る）、固定した commit 以外のビルド | cmake の旗が本当に効くか、リンクされる部品、利用側の台本の固定の検査 |
| S4 | 取り込み後の比較 | `fork/sync-verify.sh` | D | 環境変数で指した場所の削除、worktree の扱い | `rm -rf`・`git worktree` の範囲 |
| S5 | 上流の追従 | `vendored.json`（`auto_merge`）・`Conventions/tools/fork-sync.py`（別 repo） | A（上流の gitlab）→ 自動で push・利用側の固定の書き換え | 上流（か gitlab）の改ざんがそのまま merge・push・固定の更新まで進む／上流の security fix の取り込み漏れ | tag の検証、上流の 26.11.0 以降の commit と CVE |
| S6 | 上流のコード（読まない） | `poppler/`・`fofi/`・`splash/`・`goo/` ほか | B | 上流の既知の穴 | CVE・security fix が HEAD に入っているかだけ |

`pdftotext` が上流のどこまで通るかの目安（S6 の重みづけ）: パーサ・xref・暗号（パスワードは利用側が渡さない）・
フィルタ（Flate・LZW・CCITT・JBIG2・**DCT（libjpeg）・JPX（openjpeg）・Brotli**。画像は描かないが、インライン画像は
読み飛ばすためにフィルタを通して読む、`Gfx.cc:4340`）・フォント（FoFi・FreeType・CMap）・Function（Type 4 の PostScript）・
Annot の外観。Splash・Cairo・保存・署名（NSS・GPG は OFF）は通らない。

## 4. 前提と対象外

- 自分専用。fork はソースだけを公開し、バイナリは配らない。上流には何も提案していない。
- **全 repo 共通の受容は数えない**（規約 §8）: X1。この repo には `install.sh` も Releases も無く、関係しない。
- 物理的な接触、Apple ID・Mac の侵害、root 権限の攻撃者は対象外。Homebrew の prefix を書き換えられる者は、
  すでに利用者の権限を持つ。
- 上流のコードそのものの欠陥は、既知の CVE と上流の修正の取り込みだけを見る（§3 S6）。Homebrew の部品
  （freetype ほか）の既知の穴は[既知脆弱性の監視](../../../Conventions/vulnerability-watch-conventions.jp.md)の仕事。
- `pdftotext-stream` を呼ぶ側のコード（sandbox・watchdog・出力の上限）は各アプリの点検（Zeteion・PDFViewer、
  どちらも `security-baseline-20261110`）で見た。ここでは、その守りが fork の穴の重さをどれだけ下げるかだけを書く。
- 上流の試験と開発用の台本（`test/`・`do-the-gnupg-2.4-dance.sh`、`vendored.json` の `not_built`）は作らないので対象外。
