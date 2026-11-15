# poppler（fork）機械検査（2026-11-16）

規約: `security-audit-conventions.jp.md` v1.3 第1段。対象 commit: `d54eb914f2f7725edce5f93fff20362df40b998d`
（tag `poppler-26.11.0-sy.1`）。範囲は fork が足した・変えたファイル（`git diff poppler-26.11.0 HEAD`）と、
利用側のビルドの台本 2 本。上流のコードは対象外（threat-model.md §4）。

## 結果のまとめ

| 道具 | 対象 | 結果 | 判定 |
|---|---|---|---|
| shellcheck 0.11.0（`-S warning`） | `fork/build-pdftotext.sh`・`fork/sync-verify.sh` | 0 件 | — |
| 同 | 利用側の `build-pdftotext-stream.sh`（Zeteion・PDFViewer） | Zeteion 1 件（SC2010、`ls` を `grep` に流す） | 参考。PDFViewer の写しでは直っている（2026-11-10 の点検）。Zeteion の側の話 |
| 同 | repo の残りの `*.sh`（上流） | `test/ossfuzz/build_fuzzers.sh` に 13 件（SC2046・SC2155・SC2115） | 対象外。上流の oss-fuzz 用で、ここではビルドしない（`not_built`） |
| semgrep（`--metrics=off`・`p/default`・`p/c`・`p/secrets`。C/C++ に効く規則 57） | `fork/`・`utils/pdftotext.cc`・`poppler/TextOutputDev.{cc,h}` | 0 件 | — |
| clang static analyzer（Apple clang、`--analyze`。cmake の設定だけをスクラッチに作り、`compile_commands.json` と同じ `-I`・`-D` を渡した。コンパイル・リンクはしていない） | `poppler/TextOutputDev.cc`・`utils/pdftotext.cc` | 8 件、**fork の行は 0 件** | 下の表。全部上流の行（`git blame` で確認） |
| 秘密情報（`git log --all -p` を鍵の正規表現で検索: AWS・秘密鍵・GitHub・Slack・OpenAI/Anthropic・Google） | 全履歴 9,685 commit（上流を含む） | 0 件 | — |
| cmake の設定の出力 | `fork/build-pdftotext.sh` と同じ旗 | `Manually-specified variables were not used by the project: ENABLE_DCTDECODER`、`use libjpeg: yes`・`use libopenjpeg2: yes` | **指摘 P1**（audit-20261116.md）。旗が効かず、止めたつもりの decoder が入る |

## clang static analyzer の個別の判定

| 場所 | 内容 | 判定 |
|---|---|---|
| `poppler/TextOutputDev.cc:1005` | `word->base / textPoolStep` の左が未初期化かもしれない（core.UndefinedBinaryOperatorResult） | 上流（`79fda4c5b`）。`TextPool::addWord` の呼び手は語を作るときに `base` を設定する。fork は触れていない |
| `poppler/TextOutputDev.cc:3196`・`3243`・`3542`・`5367` | 書いた値を読まない（deadcode.DeadStores） | 上流。無害 |
| `utils/pdftotext.cc:440`・`465` | `fopen` した stream を閉じない（unix.Stream） | 上流（`be94b9c1d`）。メタ情報を書いたあと、プロセスの終わりで閉じる。利用側は使わない（`-htmlmeta`） |

## 依存（ビルドしたものがリンクするもの）

利用側に入っている `libpoppler.166.dylib` を `otool -L` で見た（2026-11-16）。版は Homebrew の今の版。

| 部品 | 版 | `pdftotext` が通るか |
|---|---|---|
| freetype | 2.15.0 | 通る（埋め込みフォント） |
| fontconfig | 2.18.3 | 通る（埋め込みでないフォントの代わり） |
| libpng | 1.6.59 | ほぼ通らない（画像の書き出し用） |
| jpeg-turbo（libjpeg） | 3.2.1 | **通る**（インライン画像の DCTDecode を読み飛ばすとき） |
| openjpeg | 2.5.4_1 | **通る**（同じく JPXDecode） |
| brotli | 1.2.1 | 通る（BrotliDecode のストリーム） |
| harfbuzz・harfbuzz-subset | 15.1.0 | 通らない（保存時のフォントの subset だけ） |
| zlib（`/usr/lib`）・libc++ | macOS | 通る |

どれも `brew upgrade` で直る。fork 側の固定（commit）とは別に動く。監視の台帳（`security-assessments.json`）の `gaps` は
poppler 本体だけを挙げている（指摘 P1 の直し方）。
