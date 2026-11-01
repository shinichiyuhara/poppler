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
cmake -S "$SRC" -B "$BUILD" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DENABLE_QT5=OFF -DENABLE_QT6=OFF -DENABLE_GLIB=OFF -DENABLE_CPP=OFF -DENABLE_GTK_DOC=OFF -DENABLE_GPGME=OFF \
    -DENABLE_NSS3=OFF -DENABLE_LIBCURL=OFF -DENABLE_LIBTIFF=OFF -DENABLE_LCMS=OFF -DENABLE_LIBOPENJPEG=none \
    -DENABLE_DCTDECODER=none -DENABLE_BOOST=OFF -DENABLE_UTILS=ON -DBUILD_GTK_TESTS=OFF -DBUILD_QT5_TESTS=OFF \
    -DBUILD_QT6_TESTS=OFF -DBUILD_CPP_TESTS=OFF -DBUILD_MANUAL_TESTS=OFF -DRUN_GPERF_IF_PRESENT=OFF >/dev/null
ninja -C "$BUILD" -j "${JOBS:-4}" pdftotext
"$BUILD/utils/pdftotext" -h 2>&1 | grep -q -- -streamorder || { echo "built tool lacks -streamorder" >&2; exit 1; }
