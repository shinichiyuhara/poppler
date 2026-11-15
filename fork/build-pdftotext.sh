#!/bin/bash
# Build only pdftotext from this tree, against Homebrew's libraries. Installs nothing.
# Kept here so that a new upstream version is built with the flags that version is tested with.
set -euo pipefail

if [ $# -ne 2 ]; then
    echo "usage: build-pdftotext.sh SOURCE_DIR BUILD_DIR" >&2
    exit 2
fi
SRC="$1"
BUILD="$2"
PREFIX="$(brew --prefix)"
# Everything but the text path is off. The prefix only tells Poppler where poppler-data lives.
# The ENABLE_* options are CMake booleans: a value such as "none" counts as true, and an option
# this version does not have is ignored with only a warning. Until 2026-11-16 the image decoders
# were turned "off" that way and were built in (security audit 2026-11-16, P1). pdftotext draws
# no images, so DCT (libjpeg), JPX (openjpeg) and Brotli are left out: the decoders then do not
# run on a PDF's inline images, which pdftotext reads only to skip them (it finds their end by
# the EI that follows). HarfBuzz is used only to subset fonts when saving.
cmake -S "$SRC" -B "$BUILD" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DENABLE_QT5=OFF -DENABLE_QT6=OFF -DENABLE_GLIB=OFF -DENABLE_CPP=OFF -DENABLE_GTK_DOC=OFF -DENABLE_GPGME=OFF \
    -DENABLE_NSS3=OFF -DENABLE_LIBCURL=OFF -DENABLE_LIBTIFF=OFF -DENABLE_LCMS=OFF -DENABLE_LIBOPENJPEG=OFF \
    -DENABLE_LIBJPEG=OFF -DENABLE_BROTLI=OFF -DENABLE_HARFBUZZ=OFF -DENABLE_BOOST=OFF -DENABLE_UTILS=ON \
    -DBUILD_GTK_TESTS=OFF -DBUILD_QT5_TESTS=OFF -DBUILD_QT6_TESTS=OFF -DBUILD_CPP_TESTS=OFF -DBUILD_MANUAL_TESTS=OFF \
    -DRUN_GPERF_IF_PRESENT=OFF >/dev/null
ninja -C "$BUILD" -j "${JOBS:-4}" pdftotext
"$BUILD/utils/pdftotext" -h 2>&1 | grep -q -- -streamorder || { echo "built tool lacks -streamorder" >&2; exit 1; }
# What the flags above leave out must not be linked anyway (a renamed option, a dependency that
# pulls one in). Checked on the library, which is what links them.
lib=""
for f in "$BUILD"/libpoppler.*.dylib; do
    [[ "$(basename "$f")" =~ ^libpoppler\.[0-9]+\.dylib$ ]] && { lib="$f"; break; }
done
[ -n "$lib" ] || { echo "no libpoppler.NNN.dylib in $BUILD" >&2; exit 1; }
if otool -L "$lib" | grep -E -i 'jpeg|openjp|brotli|harfbuzz|tiff|lcms|curl|nss|gpgme'; then
    echo "libpoppler links a library the build turns off (listed above)" >&2
    exit 1
fi
