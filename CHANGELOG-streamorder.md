# Changelog of the `streamorder` fork

Changes to this fork only; upstream's are in `NEWS`. Format follows
[Keep a Changelog](https://keepachangelog.com/). Tags are `<upstream tag>-sy.<n>`.

## [poppler-26.10.0-sy.1] - 2026-11-01

### Added

- `pdftotext -streamorder`: assemble words as the default mode does, but output them in content
  stream order. Includes joining vertical columns drawn one character per word, and moving ruby to the
  end of its column.
- `fork/build-pdftotext.sh` and `fork/sync-verify.sh`, used to build and to compare a new version.
