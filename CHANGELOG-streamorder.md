# Changelog of the `streamorder` fork

Changes to this fork only; upstream's are in `NEWS`. Format follows
[Keep a Changelog](https://keepachangelog.com/). Tags are `<upstream tag>-sy.<n>`.

## [Unreleased]

### Changed

- `fork/sync-verify.sh` compares the new build with this fork as it was before the upstream merge
  (built once per commit into `~/Library/Caches/fork-sync/poppler-baseline/`), not with the
  pdftotext a consumer has installed, which can lag the fork. A difference now comes from upstream only.

## [poppler-26.10.0-sy.2] - 2026-11-05

### Changed

- `-streamorder` keeps on their line what used to cut it: emphasis dots (moved to just after the
  line), tate-chu-yoko in vertical columns, words on the same baseline that the layout analysis had
  put on other lines (running heads, brackets after a squeezed 、, subscripts). A soft hyphen where two
  such words join is left out, as at a line end.
- `-tsv` and `-bbox` with `-streamorder` follow the order and the lines of the text output.
- The order and the separators are computed once, in `TextPage::streamItems()`
  (`TextOutputDev::makeStreamItems()`), for the text output and both of these.

### Checked

- Without `-streamorder` (default, `-raw`, `-layout`, `-bbox-layout`), the output is the same as
  `-sy.1` on 60 PDFs (first 6 pages each). With it, the characters are the same (whitespace aside)
  on all 60; line breaks are 6.1% fewer.

## [poppler-26.10.0-sy.1] - 2026-11-01

### Added

- `pdftotext -streamorder`: assemble words as the default mode does, but output them in content
  stream order. Includes joining vertical columns drawn one character per word, and moving ruby to the
  end of its column.
- `fork/build-pdftotext.sh` and `fork/sync-verify.sh`, used to build and to compare a new version.
