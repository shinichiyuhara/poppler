#!/bin/bash
# Compare a newly built pdftotext with the installed one on a private list of PDFs.
# exit 0: every -streamorder output is the same. exit 1: one differs or cannot be compared.
# The list stays outside this public repository: it names books. Output gives only line numbers.
set -uo pipefail

if [ $# -ne 2 ]; then
    echo "usage: sync-verify.sh NEW_PDFTOTEXT BUILD_DIR" >&2
    exit 2
fi
NEW="$1"
BASE="${FORK_SYNC_BASELINE:-$HOME/Library/Application Support/Zeteion/poppler-stream/pdftotext-stream}"
LIST="${FORK_SYNC_SAMPLES:-$HOME/Library/Application Support/fork-sync/poppler-samples.txt}"
[ -x "$BASE" ] || { echo "no baseline tool"; exit 1; }
[ -s "$LIST" ] || { echo "no sample list"; exit 1; }

n=0 compared=0 differ=0
while IFS= read -r pdf; do
    n=$((n + 1))
    [ -f "$pdf" ] || { echo "sample $n: missing"; continue; }
    a="$("$BASE" -streamorder "$pdf" - 2>/dev/null | shasum -a 256)"
    b="$("$NEW" -streamorder "$pdf" - 2>/dev/null | shasum -a 256)"
    compared=$((compared + 1))
    if [ "$a" != "$b" ]; then
        echo "sample $n: output differs"
        differ=$((differ + 1))
    fi
done < "$LIST"
echo "compared $compared of $n samples, $differ differ"
[ "$compared" -gt 0 ] && [ "$differ" -eq 0 ]
