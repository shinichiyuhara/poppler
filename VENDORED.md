# この fork の記録

規約: `~/Developer/Claude/Conventions/vendored-source-conventions.jp.md` §6.2.4。機械可読な宣言は `vendored.json`。

## なぜ分岐したか

`pdftotext` の既定は読み取りはよいが、座標で並べ直すため縦書きと段組で語句が切れる。`-raw` は字間に空白が入る。
語の組み立てはそのまま、出力だけ描画順にする `-streamorder` を足した。測定と経緯は Zeteion の
`docs/pdftotext-mode-20261101.jp.md`。Zeteion の索引が使う。本家への提案は未実施（提案して採用されれば畳む）。

## 上流

- 本家は gitlab.freedesktop.org/poppler/poppler（GitHub に公式ミラーはない。2026-11-01 確認）。
  そのため GitHub の Fork 機能ではなく、本家の履歴をそのまま push した普通のリポジトリである。
- 本家の remote は `upstream`、GitHub は `origin`。別の Mac では clone のあとに次を打つ。
  `git remote add upstream https://gitlab.freedesktop.org/poppler/poppler.git`

## 局所修正

| 版 | ファイル | 中身 |
|---|---|---|
| sy.1 | `poppler/TextOutputDev.{cc,h}`・`utils/pdftotext.cc` | `-streamorder`。GPL の変更の明示は各ファイルの見出しにある |

上流のファイルで変えたのはこの 3 本だけ。他の追加は `fork/`・`.github/README.md`・`VENDORED.md`・
`vendored.json`・`CHANGELOG-streamorder.md` で、本家の README と衝突しないよう README は `.github/` に置いた。

## 追随

routine の `fork-sync`（`Conventions/tools/fork-sync.py`）が毎日本家のタグを見る。新しい版があれば、別の作業場所で
merge し、`fork/build-pdftotext.sh` でビルドし、`fork/sync-verify.sh` で出力を比べる。すべて通れば push してタグを付け、
Zeteion の版の固定を上げて知らせる。衝突・ビルドの失敗・出力の違いのときは何も push せず知らせる。

出力の違いで止まったら、差を読んで判断する。`-streamorder` の出力が変わる版を入れると、索引の読み直しが要ることがある。

比べる PDF の一覧は蔵書の書名を含むので、このリポジトリに入れない
（`~/Library/Application Support/fork-sync/poppler-samples.txt`）。

## 配布

バイナリは配らない。ソースだけを公開し、各 Mac で Zeteion の `scripts/build-pdftotext-stream.sh` がビルドする。
