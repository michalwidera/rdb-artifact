#!/usr/bin/env bash
# Verify that an engine binary identifies the expected source revision.
# Current RetractorDB binaries expose a seven-hex commit prefix in --help.

set -euo pipefail

EXPECTED="${1:-}"
BINARY="${2:-${RDB_XRETRACTOR:-}}"

fail() { echo "ERROR: $*" >&2; exit 2; }

[[ "$EXPECTED" =~ ^[0-9a-f]{40}$ ]] \
  || fail "expected revision must be a full 40-character SHA"
[[ -n "$BINARY" ]] || fail "pass xretractor path as argument 2 or RDB_XRETRACTOR"
[[ -x "$BINARY" ]] || fail "binary is not executable: $BINARY"

HELP="$($BINARY --help 2>&1)" || fail "cannot read build identity from $BINARY"
EMBEDDED="$(sed -nE 's/^Branch: [^:]+:([0-9a-f]{7,40}),.*/\1/p' <<<"$HELP" | head -n 1)"
[[ -n "$EMBEDDED" ]] || fail "binary does not expose Branch:<name>:<sha> in --help"

if [[ "$EXPECTED" == "$EMBEDDED"* ]]; then
  echo "OK   binary revision $EMBEDDED matches $EXPECTED"
else
  fail "binary revision $EMBEDDED does not match $EXPECTED"
fi
