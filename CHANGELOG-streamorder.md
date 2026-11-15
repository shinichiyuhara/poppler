# Changelog of the `streamorder` fork

Changes to this fork only; upstream's are in `NEWS`. Format follows
[Keep a Changelog](https://keepachangelog.com/). Tags are `<upstream tag>-sy.<n>`.

## [poppler-26.11.0-sy.2] - 2026-11-16

### Security

From this fork's security audit of 2026-11-16 (`docs/security/audit-20261116.md`).

- `TextPage::streamItems()` finds the flow of a run of small marks moved after their line (emphasis
  dots and the like) in linear time. It used to look back and ahead word by word, which made a long
  run quadratic: on a crafted page, `-streamorder` took 1.0 s more than the default mode with 64,000
  such marks and 3.3 s more with 128,000; it now takes no more. The output is the same (P2).
- `fork/build-pdftotext.sh` turns the image decoders off with the options this version has
  (`ENABLE_LIBJPEG`, `ENABLE_LIBOPENJPEG`, `ENABLE_BROTLI` and `ENABLE_HARFBUZZ` set to `OFF`).
  `ENABLE_LIBOPENJPEG=none` counted as true and `ENABLE_DCTDECODER` does not exist, so libjpeg,
  openjpeg, brotli and harfbuzz were built in, and the DCT, JPX and Brotli decoders ran on inline
  images, which pdftotext reads only to skip. The script now also fails if `libpoppler` links any of
  them (P1).
- `fork/sync-verify.sh` deletes old baselines only in a folder named `poppler-baseline`, and only
  folders named by a commit hash. A mistyped `FORK_SYNC_BASELINE_CACHE` could have emptied any
  folder (P4).
- `fork/upstream-signing-keys.asc`: the key upstream signs its release tags with (Albert Astals Cid,
  `CA26 2C6C 83DE 4D2F B28A  332A 3A6A 4DB8 39EA A6D7`). The automatic merge now checks the tag
  against it before merging (P3).

### Checked

- On 30 PDFs, the output of `-streamorder`, `-streamorder -tsv`, the default mode and `-layout` is
  the same as `-sy.1`.

## [poppler-26.11.0-sy.1] - 2026-11-06

### Changed

- Merged upstream `poppler-26.11.0`.
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
