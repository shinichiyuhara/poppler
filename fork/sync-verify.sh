#!/bin/bash
# Compare a newly built pdftotext with this fork's pdftotext from before the merge, on a private
# list of PDFs. exit 0: every -streamorder output is the same. exit 1: one differs or cannot be compared.
# The list stays outside this public repository: it names books. Output gives only line numbers.
#
# The baseline is the fork as it was before the upstream merge (HEAD^1 of the merge commit that
# fork-sync makes in its worktree, which is the current directory), so a difference can only come
# from upstream. It used to be the pdftotext installed by Zeteion, but that follows Zeteion's pin,
# which can lag the fork: on 2026-11-06 Zeteion was on -sy.1 while the fork was on -sy.2, and
# 26 of 30 samples differed because of -sy.2's own change, not upstream's. The baseline is built
# once per commit into a cache. FORK_SYNC_BASELINE names a tool to use instead.
set -uo pipefail

if [ $# -ne 2 ]; then
    echo "usage: sync-verify.sh NEW_PDFTOTEXT BUILD_DIR" >&2
    exit 2
fi
NEW="$1"
LIST="${FORK_SYNC_SAMPLES:-$HOME/Library/Application Support/fork-sync/poppler-samples.txt}"
[ -s "$LIST" ] || { echo "no sample list"; exit 1; }

if [ -n "${FORK_SYNC_BASELINE:-}" ]; then
    BASE="$FORK_SYNC_BASELINE"
else
    git rev-parse -q --verify HEAD^2 >/dev/null || { echo "HEAD is not a merge; set FORK_SYNC_BASELINE"; exit 1; }
    commit="$(git rev-parse HEAD^1)"
    CACHE="${FORK_SYNC_BASELINE_CACHE:-$HOME/Library/Caches/fork-sync/poppler-baseline}"
    BASE="$CACHE/$commit/build/utils/pdftotext"
    if [ ! -x "$BASE" ]; then
        # Only this script writes under $CACHE; older baselines are rebuilt from git if needed.
        mkdir -p "$CACHE"
        find "$CACHE" -mindepth 1 -maxdepth 1 -type d ! -name "$commit" -exec rm -rf {} +
        src="$CACHE/$commit/src"
        git worktree remove --force "$src" 2>/dev/null
        git worktree prune
        git worktree add -q --detach "$src" "$commit" || { echo "baseline: cannot check out $commit"; exit 1; }
        "$src/fork/build-pdftotext.sh" "$src" "$CACHE/$commit/build" >/dev/null 2>&1
        built=$?
        git worktree remove --force "$src"
        git worktree prune
        [ "$built" -eq 0 ] || { echo "baseline: build of $commit failed"; exit 1; }
    fi
    echo "baseline: fork at ${commit:0:9}"
fi
[ -x "$BASE" ] || { echo "no baseline tool"; exit 1; }

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
