# Poppler with `pdftotext -streamorder`

A personal fork of [Poppler](https://gitlab.freedesktop.org/poppler/poppler), kept here so that one
small change can follow upstream through git. **For anything else, use upstream:** source, releases
and bug reports all live on freedesktop's GitLab. This repository publishes source only; there are no
binaries.

## What differs from upstream

The default mode of `pdftotext` assembles characters into words and lines well, then sorts the blocks
by their coordinates. On vertical Japanese text and on multi-column pages that sort cuts sentences
apart. `-raw` keeps the drawn order but skips the assembly, so spaces appear between characters and
overlapping text comes out twice.

`-streamorder` keeps the default assembly and replaces only the output order:

- Words are written in content-stream order. A blank line separates flows, as in the default mode.
- No space is written between two words when either side is CJK, so `第1審` does not become `第 1 審`.
- In a vertical column drawn one character per word, the characters are joined instead of being put
  on separate lines.
- Ruby, drawn between the characters it annotates, moves to the end of its column as separate lines.
  No character is dropped.
- Emphasis dots (bouten) and other small marks drawn between two words of a line move to just after
  that line, so that the line is not cut in two. No character is dropped.
- One to four Latin letters or digits set across a vertical column (tate-chu-yoko: `X1`, `24`) stay in
  the column instead of breaking it before and after.
- A word drawn next on the same baseline, in the same size, just after the previous one stays on its
  line: running heads with wide tracking, a bracket in another font, a subscript.
- With `-tsv` and `-bbox`, words come in the same order, and `-tsv` lines and blocks are the lines and
  blank-line-separated blocks of the text output. `-bbox-layout` is not changed.

Without `-streamorder`, the output is meant to be the same as upstream's.

To see the whole change:

```bash
git diff poppler-26.10.0 poppler-26.10.0-sy.1 -- poppler utils
```

## Branches and tags

| Name | What it is |
|---|---|
| `streamorder` (default) | upstream's latest release merged with this change |
| `poppler-X.Y.Z` | upstream's signed tag, unchanged |
| `poppler-X.Y.Z-sy.N` | this change on top of that release |

## Build

`fork/build-pdftotext.sh` builds only `pdftotext`, against Homebrew's libraries:

```bash
git clone --branch poppler-26.10.0-sy.1 https://github.com/shinichiyuhara/poppler.git
```

```bash
poppler/fork/build-pdftotext.sh poppler poppler/build
```

## License

Poppler is licensed under the GPL; see [COPYING](../COPYING) and [COPYING3](../COPYING3), and the
[history section of upstream's README](../README.md#history-and-gpl-licensing). This change is under
the same terms, and each changed file says so in its header.

Changes to this fork are listed in [CHANGELOG-streamorder.md](../CHANGELOG-streamorder.md).
