#!/bin/bash
# Apply the AOSP patches in this directory to a checked-out AOSP tree.
#
#   patches/apply.sh [AOSP_TREE]     (default: $ANDROID_BUILD_TOP, else cwd)
#
# Each patch declares its target with a "Project:" header line, relative to the tree root.
# Patches are applied in filename order. REJECTED-* are records of approaches that were
# measured to make things worse -- they are never applied.
#
# Idempotent: a patch already present is reported and skipped, so this is safe to re-run
# before every build.
set -u
TOP="${1:-${ANDROID_BUILD_TOP:-$PWD}}"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -d "$TOP/build/make" ] || { echo "not an AOSP tree: $TOP" >&2; exit 1; }
rc=0 applied=0 already=0 skipped=0
for p in "$HERE"/*.patch; do
  b=$(basename "$p")
  case "$b" in REJECTED-*) echo "skip     $b (rejected -- see its header)"; skipped=$((skipped+1)); continue;; esac
  proj=$(sed -n 's/^Project: *//p' "$p" | head -1)
  [ -n "$proj" ] || { echo "ERROR    $b has no 'Project:' header" >&2; rc=1; continue; }
  d="$TOP/$proj"
  [ -d "$d" ] || { echo "ERROR    $b: project $proj not in tree" >&2; rc=1; continue; }
  if git -C "$d" apply --reverse --check "$p" 2>/dev/null; then
    echo "present  $b -> $proj"; already=$((already+1))
  elif git -C "$d" apply --check "$p" 2>/dev/null; then
    git -C "$d" apply "$p" && { echo "APPLIED  $b -> $proj"; applied=$((applied+1)); } || rc=1
  else
    echo "ERROR    $b does not apply to $proj (tree moved? already partly applied?)" >&2; rc=1
  fi
done
echo "---"
echo "applied=$applied already-present=$already skipped=$skipped"
[ $rc -eq 0 ] || echo "SOME PATCHES FAILED -- do not cut a release from this tree" >&2
exit $rc
