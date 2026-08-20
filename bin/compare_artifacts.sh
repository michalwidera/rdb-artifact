#!/usr/bin/env bash
# Compare two artifact trees. Only bytes 0..7 of files ending exactly in .meta
# are excluded. Empty comparisons and empty data streams are errors.

set -euo pipefail

LEFT="${1:-}"
RIGHT="${2:-}"
MIN_FILES="${3:-1}"

fail() { echo "ERROR: $*" >&2; exit 2; }
[[ -d "$LEFT" ]] || fail "missing left directory: $LEFT"
[[ -d "$RIGHT" ]] || fail "missing right directory: $RIGHT"
[[ "$MIN_FILES" =~ ^[1-9][0-9]*$ ]] || fail "minimum file count must be positive"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

(cd "$LEFT" && find . -type f -printf '%P\n' | LC_ALL=C sort) >"$TMP/left"
(cd "$RIGHT" && find . -type f -printf '%P\n' | LC_ALL=C sort) >"$TMP/right"
cmp "$TMP/left" "$TMP/right" >/dev/null \
  || fail "artifact trees contain different file sets"

COMPARED="$(wc -l <"$TMP/left")"
[[ "$COMPARED" -ge "$MIN_FILES" ]] \
  || fail "compared $COMPARED files, expected at least $MIN_FILES"

DATA_FILES=0
while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  case "$path" in
    *.meta)
      [[ "$(stat -c %s "$LEFT/$path")" -ge 8 ]] \
        || fail "$path is shorter than the eight-byte metadata header"
      [[ "$(stat -c %s "$RIGHT/$path")" -ge 8 ]] \
        || fail "$path is shorter than the eight-byte metadata header"
      cmp <(tail -c +9 "$LEFT/$path") <(tail -c +9 "$RIGHT/$path") >/dev/null \
        || fail "metadata body differs: $path"
      ;;
    *)
      cmp "$LEFT/$path" "$RIGHT/$path" >/dev/null \
        || fail "artifact differs: $path"
      case "$path" in
        *.desc|*.shadow) ;;
        *)
          [[ -s "$LEFT/$path" && -s "$RIGHT/$path" ]] \
            || fail "data artifact is empty: $path"
          DATA_FILES=$((DATA_FILES + 1))
          ;;
      esac
      ;;
  esac
done <"$TMP/left"

[[ "$DATA_FILES" -gt 0 ]] || fail "zero non-empty data artifacts"
echo "OK: compared=$COMPARED nonempty_data=$DATA_FILES excluded_bytes_per_meta=8"
