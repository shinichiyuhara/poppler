# Changelog of the `streamorder` fork

Changes to this fork only; upstream's are in `NEWS`. Format follows
[Keep a Changelog](https://keepachangelog.com/). Tags are `<upstream tag>-sy.<n>`.

## [poppler-26.11.0-sy.6] - 2026-11-24

### Added

- `pdftotext -streamtsv`: the words of `-streamorder -tsv` with what the `-streamorder` text writes
  after each, in one pass. Columns `level page_num flow line left top width height after text`; only
  page (level 1) and word (level 5) rows. `after` is 0 nothing, 1 a space, 2 a line break, 3 a blank
  line, plus 4 when the word's last character is an end-of-line hyphen the text leaves out (the
  digit is what the text writes, so a removed hyphen at a line end goes with 0, at a flow end with
  2). The word's text keeps the hyphen, so that its box and its text agree. Boxes are written as
  `-tsv` writes them (`%.2f`; the page's size `%f`). Implies `-streamorder` and `-tsv`; refused with
  `-htmlmeta`, `-bbox`, `-layout` and `-raw`.
  Why: PDFViewer ran both `-streamorder -tsv` and `-streamorder` over every page and lined the
  two up word by word. That lining-up guessed wrong where a word is only an end-of-line hyphen
  (table dashes) or ends in a soft hyphen; the fork knows the answer.

### Checked

- On 60 PDFs from the library (first 200 pages each), the output of `-streamorder`,
  `-streamorder -tsv`, the default mode and `-layout` is the same as `-sy.5` (240 of 240).
- On the same 60, PDFViewer's words from one `-streamtsv` run equal those from the two runs lined
  up on 48; the 12 others differ only around end-of-line hyphens, where `-streamtsv` agrees with
  the text output and the lining-up did not.

## [poppler-26.11.0-sy.5] - 2026-11-23

### Fixed

- A marked-content span with `/ActualText` whose glyphs are drawn under different CTMs (each in its
  own `q … cm … Q`) is measured in the first glyph's user space: the end of a later glyph was taken
  in its own space and read in the first glyph's, so the span came out too short or too long. A
  generated "fi" span with the `i` under a scaling `cm` was 1.55 pt wide and a word of its own; it
  now joins "rm" as "firm". Under one CTM nothing changes (the conversion is skipped).
- A span left open at the end of a page (a `BDC` with no `EMC`) is closed there and its text added
  with its first glyph's state. It used to stay open and swallow every glyph until some later
  `EMC`: on a generated two-page PDF the span's own text and all of page 2 were missing. Upstream
  has the same fault.

### Checked

- On 38 PDFs (the 30 samples, PDFViewer's 7 test subsets and a landscape page), the output of
  `-streamorder`, `-streamorder -tsv`, the default mode and `-layout` is the same as `-sy.4`.
- Two generated PDFs show both faults with `-sy.4` and the fix with `-sy.5` (an open span across a
  page break; a span whose second glyph is under a scaling `cm`).

## [poppler-26.11.0-sy.4] - 2026-11-23

### Fixed

- The text of a marked-content span with `/ActualText` is placed with the graphics state of the
  span's first glyph, not the one current at its end (EMC). Producers that draw each such glyph
  inside its own `q … cm … Q` (Core Text draws every ligature as `/Span <</ActualText (fi)>> BDC q
  cm BT … Tj ET Q EMC`) had the `cm` and the font already undone at EMC: on a page whose text is
  turned (a landscape page with `/Rotate 90`, as pdflscape makes it) the ligature became a word of
  its own 1 pt wide, put where the unturned text would be, and `firm` came out as `rm` with `fi` on
  another line; with a scaling `cm` (`10 0 0 10 cm`, seen in an InDesign book) the span's text
  landed on a line of its own away from its neighbours. Upstream has the same fault (checked on
  `master` 9182fd5da).
  `ActualText` keeps a copy of the first glyph's `GfxState` (`copy(true)`, so the copy owns its
  path) and puts the font of that state in force while it adds the span's text.

### Checked

- On 30 PDFs, the output of `-streamorder`, `-streamorder -tsv`, the default mode and `-layout` is
  the same as `-sy.3`. Of PDFViewer's 9 test PDFs one differs: the `ActualText` span above, now on
  the line of the glyphs before it.
- Three generated pages (no rotation; `/Rotate 90` with turned text; turned text without `/Rotate`)
  with `fi`/`fl` ligatures give the plain text in both `-streamorder` and the default mode.

## [poppler-26.11.0-sy.3] - 2026-11-20

### Security

Five fixes taken from upstream `master` ahead of its next release (`git cherry-pick -x`, so each commit
names its upstream original). pdftotext runs these paths: it evaluates a PostScript (Type 4) function
to work out the colour of text drawn in a Separation or DeviceN colour space.

- `PostScriptFunction::exec`: `sub`, `abs` and `neg` on integers no longer overflow a signed int
  (undefined behaviour); a result out of range becomes a real number. Upstream 835bcfe34, f3d12745a,
  f58dcd84d. The `sub` fix is adapted to this version, which declares `i1` and `i2` at the top of the
  function.
- `PostScriptFunction::exec`: `bitshift` by 32 or more places, either way, no longer shifts by more
  than the width of an int (undefined behaviour); it reports an error and gives 0. A left shift is
  done on an unsigned int. Upstream 5c95e5f71, adapted the same way.
- `pdftotext -htmlmeta`: a document-information string that starts with a UTF-16 byte-order mark
  and has an odd length is skipped instead of read one byte past its end. Upstream d27c83dd4.

### Checked

- On 30 PDFs, the output of `-streamorder` (`fork/sync-verify.sh`), `-streamorder -tsv`, the default
  mode and `-layout` is the same as `-sy.2`.
- A PDF whose text colour comes from a Type 4 function doing `neg`, `abs`, `sub` at the int limits
  and `bitshift` by 40: built with `-fsanitize=undefined`, `-sy.2` reports undefined behaviour and
  `-sy.3` does not.

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
