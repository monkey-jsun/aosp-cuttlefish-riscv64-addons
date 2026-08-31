#!/bin/bash
# Fetch and verify the pinned third-party APKs listed in prebuilts/apk-pins.tsv.
# Idempotent: an artifact already present with the right checksum is left alone,
# so this is safe to run before every build.
#
#   tools/fetch-apks.sh                fetch what is missing, verify everything
#   tools/fetch-apks.sh --verify-only  verify only; non-zero exit on any mismatch
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINS="$REPO_DIR/prebuilts/apk-pins.tsv"
VERIFY_ONLY=0
[[ "${1:-}" == "--verify-only" ]] && VERIFY_ONLY=1

[[ -f "$PINS" ]] || { echo "ERROR: $PINS not found" >&2; exit 1; }

fail=0
while IFS=$'\t' read -r fetch dest bytes sha primary upstream; do
    [[ -z "${fetch:-}" || "${fetch:0:1}" == "#" ]] && continue
    path="$REPO_DIR/$dest"

    if [[ -f "$path" ]]; then
        have=$(sha256sum "$path" | cut -d' ' -f1)
        if [[ "$have" == "$sha" ]]; then
            echo "ok       $dest"
            continue
        fi
        echo "MISMATCH $dest"
        echo "           expected $sha"
        echo "           actual   $have"
        fail=1
        continue
    fi

    if [[ "$fetch" != "yes" ]]; then
        echo "MISSING  $dest (committed artifact, not fetchable)"; fail=1; continue
    fi
    if (( VERIFY_ONLY )); then
        echo "MISSING  $dest"; fail=1; continue
    fi

    mkdir -p "$(dirname "$path")"
    got=""
    for url in "$primary" "$upstream"; do
        [[ "$url" == "-" || -z "$url" ]] && continue
        echo "fetch    $dest"
        echo "           <- $url"
        # Download to .part and rename only after verification, so a truncated or
        # wrong file is never left where Soong would happily package it.
        if curl -fL --retry 3 --retry-delay 5 --connect-timeout 30 \
                -o "$path.part" "$url"; then
            got=1; break
        fi
        echo "           failed, trying next source"
        rm -f "$path.part"
    done
    if [[ -z "$got" ]]; then
        echo "ERROR    $dest: all sources failed"; fail=1; continue
    fi

    actual_bytes=$(stat -c%s "$path.part")
    actual_sha=$(sha256sum "$path.part" | cut -d' ' -f1)
    if [[ "$actual_bytes" != "$bytes" || "$actual_sha" != "$sha" ]]; then
        echo "ERROR    $dest: verification failed, discarding"
        echo "           expected $bytes bytes / $sha"
        echo "           actual   $actual_bytes bytes / $actual_sha"
        rm -f "$path.part"; fail=1; continue
    fi
    mv "$path.part" "$path"
    echo "ok       $dest ($actual_bytes bytes)"
done < "$PINS"

exit $fail
