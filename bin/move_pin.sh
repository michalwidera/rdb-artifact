#!/usr/bin/env bash
# Move one source-repository pin of the artifact package. The procedure around
# it -- re-pointing the reviewer mirror and the acceptance trial -- is in
# REVIEW_MIRROR.md, section "Moving a pin".
#
#   bin/move_pin.sh <repository> <new-sha>            # dry run, changes nothing
#   bin/move_pin.sh <repository> <new-sha> --apply    # write the pin, then verify
#
# <repository> is retractordb, rdb-experiment, dokumentacja-rdb or
# documentation-rdb. paper-arXiv is pinned by the annotated tag artifact/K9b
# (MANIFEST.md section 1) and moves with that tag, not with this script.
#
# The new revision is inspected in a local clone, $RDB_SOURCES/<repository>
# (default: the directory that holds this repository). The dry run reports:
#   1. that <new-sha> is a full commit of that clone and a descendant of the pin;
#   2. the delta since the pin, file by file;
#   3. text files of 1.2 MB or more in the delta: the reviewer mirror answers
#      HTTP 502 for them, so each needs a <name>.gz copy in the same revision;
#   4. lines of the delta matching the redaction terms, which step 3 of the
#      acceptance trial has to find redacted on the mirror. The terms identify
#      the author, so they are never written here: pass them through
#      RDB_REDACTION_TERMS_FILE, one extended regular expression per line (the
#      list in paper-arXiv/debs/procedura_anonimizacji.md). Without it the
#      check is reported as SKIP. A file of the delta that is an input of the
#      analytic path (INPUTS.tsv) and matches a term or a link is named: the
#      mirror serves it redacted, and --apply checks that no product depends
#      on the redacted lines;
#   5. the four places that declare the pin, as a unified diff: MANIFEST.md,
#      bin/verify_pins.sh and bin/checkout.sh (compared by section 0 of
#      verify_pins.sh) and the mirror table of REVIEW_MIRROR.md (compared by
#      nothing, which is why it is moved here together with the other three).
#
# --apply writes those four places, clones the pinned workspace afresh with
# bin/checkout.sh into a temporary directory and runs bin/verify_pins.sh snapshot
# against it, then renews INPUTS.tsv with bin/make_inputs.sh, which runs
# bin/reproduce_analytic.sh there and bin/review.sh on a simulated mirror of the
# new pins, products outside this repository. --apply needs
# RDB_REDACTION_TERMS_FILE and strace. It never commits, pushes or touches a
# mirror.
#
# Exit status: 0 - clean, 1 - findings, 2 - usage or environment.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SOURCES="${RDB_SOURCES:-$(cd "$ROOT/.." && pwd)}"
MIRROR_TEXT_LIMIT=1200000

usage() { sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "ERROR: $*" >&2; exit 2; }

[[ $# -ge 2 && $# -le 3 ]] || { usage; exit 2; }
REPO="$1"
NEW="$2"
APPLY=no
if [[ $# -eq 3 ]]; then
  [[ "$3" == --apply ]] || die "unknown option $3"
  APPLY=yes
  [[ -n "${RDB_REDACTION_TERMS_FILE:-}" ]] || die "--apply renews INPUTS.tsv and needs RDB_REDACTION_TERMS_FILE"
  command -v strace >/dev/null || die "--apply renews INPUTS.tsv and needs strace"
fi

case "$REPO" in
  retractordb) VAR=ENGINE_SNAPSHOT ;;
  rdb-experiment) VAR=EXPERIMENT_SNAPSHOT ;;
  dokumentacja-rdb) VAR=DOCS_PL_SNAPSHOT ;;
  documentation-rdb) VAR=DOCS_EN_SNAPSHOT ;;
  paper-arXiv) die "paper-arXiv is pinned by the tag artifact/K9b; move the tag, not this pin" ;;
  *) die "unknown repository $REPO" ;;
esac
[[ "$NEW" =~ ^[0-9a-f]{40}$ ]] || die "<new-sha> must be a full 40-character SHA"

FILES=(MANIFEST.md bin/verify_pins.sh bin/checkout.sh REVIEW_MIRROR.md)
for f in "${FILES[@]}" INPUTS.tsv; do
  [[ -z "$(git -C "$ROOT" status --porcelain -- "$f")" ]] || die "$f has uncommitted changes; commit or revert them first"
done

OLD="$(grep -E "^$VAR=\"[0-9a-f]{40}\"" "$HERE/checkout.sh" | head -n 1 | grep -oE '[0-9a-f]{40}')"
[[ -n "$OLD" ]] || die "no $VAR in bin/checkout.sh"
[[ "$OLD" != "$NEW" ]] || die "$REPO is already pinned at $NEW"
CLONE="$SOURCES/$REPO"
[[ -d "$CLONE/.git" ]] || die "no local clone $CLONE (set RDB_SOURCES)"

FINDINGS=0
SKIPPED=0
finding() { echo "FINDING $*"; FINDINGS=$((FINDINGS + 1)); }
skip() { echo "SKIP    $*"; SKIPPED=$((SKIPPED + 1)); }

echo "== $REPO: $OLD -> $NEW"

echo
echo "== 1. revision"
git -C "$CLONE" cat-file -e "$OLD^{commit}" 2>/dev/null || die "$CLONE lacks the current pin $OLD; fetch first"
git -C "$CLONE" cat-file -e "$NEW^{commit}" 2>/dev/null || die "$CLONE lacks $NEW; fetch first"
if git -C "$CLONE" merge-base --is-ancestor "$OLD" "$NEW"; then
  echo "ok      $NEW descends from the pin ($(git -C "$CLONE" rev-list --count "$OLD..$NEW") commits)"
else
  finding "$NEW does not descend from the pin $OLD: a pin only moves forward"
fi
if git -C "$CLONE" branch -r --contains "$NEW" 2>/dev/null | grep -q .; then
  echo "ok      $NEW is on a remote-tracking branch of the clone"
else
  finding "$NEW is on no remote-tracking branch: push it before the pin moves"
fi

echo
echo "== 2. delta"
git -C "$CLONE" diff --name-status "$OLD" "$NEW" | sed 's/^/        /'

echo
echo "== 3. text files the mirror refuses (>= $MIRROR_TEXT_LIMIT bytes)"
LARGE=0
while IFS=$'\t' read -r added deleted path; do
  [[ "$added" == - ]] && continue  # binary: served byte for byte
  git -C "$CLONE" cat-file -e "$NEW:$path" 2>/dev/null || continue  # deleted
  size="$(git -C "$CLONE" cat-file -s "$NEW:$path")"
  [[ "$size" -ge "$MIRROR_TEXT_LIMIT" ]] || continue
  LARGE=$((LARGE + 1))
  if git -C "$CLONE" cat-file -e "$NEW:$path.gz" 2>/dev/null; then
    echo "ok      $path ($size bytes) has $path.gz"
  else
    finding "$path ($size bytes) has no $path.gz in $NEW"
  fi
done < <(git -C "$CLONE" diff --numstat "$OLD" "$NEW")
[[ $LARGE -gt 0 ]] || echo "ok      none"

echo
echo "== 4. identifying terms in the delta"
if [[ -n "${RDB_REDACTION_TERMS_FILE:-}" ]]; then
  [[ -r "$RDB_REDACTION_TERMS_FILE" ]] || die "cannot read $RDB_REDACTION_TERMS_FILE"
  TERMS="$(mktemp)"
  grep -v -e '^#' -e '^$' "$RDB_REDACTION_TERMS_FILE" >"$TERMS"
  # Counts only: printing the matched lines would repeat the identifying text.
  HITS=0
  while read -r path; do
    n="$(git -C "$CLONE" diff "$OLD" "$NEW" -- "$path" | grep -E '^\+' | grep -v '^+++' \
      | grep -c -i -E -f "$TERMS" || true)"
    [[ "$n" -gt 0 ]] || continue
    echo "note    $path: $n added line(s) match a term; the trial must find them redacted on the mirror"
    HITS=$((HITS + n))
    if [[ "$REPO" == rdb-experiment ]] && cut -f2 "$ROOT/INPUTS.tsv" | grep -qxF -- "$path"; then
      echo "note    $path is an input of the analytic path: the mirror serves it redacted (masked in INPUTS.tsv)"
    fi
  done < <(git -C "$CLONE" diff --name-only --diff-filter=AM "$OLD" "$NEW")
  rm -f "$TERMS"
  [[ $HITS -gt 0 ]] || echo "ok      no added line matches a term"
else
  skip "RDB_REDACTION_TERMS_FILE not set; step 3 of the acceptance trial still has to search the changed files"
fi

echo
echo "== 5. declarations"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"
for f in "${FILES[@]}"; do cp "$ROOT/$f" "$WORK/$f"; done
# Exactly one line per file; anything else means the layout changed under us.
replace() {
  local file="$1" pattern="$2" count
  count="$(grep -c -E "$pattern" "$WORK/$file")"
  [[ "$count" -eq 1 ]] || die "$file: expected one line matching '$pattern', found $count"
  sed -i -E "/$pattern/ s/$OLD/$NEW/" "$WORK/$file"
}
replace MANIFEST.md "^\\| \`$REPO\` \\| .*$OLD"
replace bin/verify_pins.sh "^$VAR=\"$OLD\""
replace bin/checkout.sh "^$VAR=\"$OLD\""
replace REVIEW_MIRROR.md "^\\| .* \\| \`$REPO\` \\| \`$OLD\` \\|"
for f in "${FILES[@]}"; do
  diff -u --label "a/$f" --label "b/$f" "$ROOT/$f" "$WORK/$f"
done

if [[ "$APPLY" == no ]]; then
  echo
  echo "RESULT: dry run, $FINDINGS finding(s), $SKIPPED skipped; nothing written"
  [[ $FINDINGS -eq 0 ]] && exit 0 || exit 1
fi

[[ $FINDINGS -eq 0 ]] || { echo "RESULT: $FINDINGS finding(s); refusing to apply"; exit 1; }
for f in "${FILES[@]}"; do cp "$WORK/$f" "$ROOT/$f"; done
echo
echo "== written: ${FILES[*]}"

CHECK="$(mktemp -d)"
echo
echo "== 6. fresh pinned workspace in $CHECK"
"$HERE/checkout.sh" "$CHECK/workspace" snapshot >"$CHECK/checkout.log" 2>&1 \
  || { echo "ERROR checkout.sh failed, see $CHECK/checkout.log"; exit 1; }
tail -n 8 "$CHECK/checkout.log" | sed 's/^/        /'
echo
echo "== 7. verify_pins.sh snapshot"
RDB_WORKSPACE="$CHECK/workspace" "$HERE/verify_pins.sh" snapshot >"$CHECK/verify_pins.log" 2>&1
status=$?
grep -E '^(ERROR|SKIP|RESULT)' "$CHECK/verify_pins.log" | sed 's/^/        /'
[[ $status -eq 0 ]] || { echo "ERROR verify_pins.sh exit $status, see $CHECK/verify_pins.log"; exit 1; }
echo
echo "== 8. INPUTS.tsv: reproduce_analytic.sh traced, review.sh on a simulated mirror"
bash "$HERE/make_inputs.sh" --workspace "$CHECK/workspace" >"$CHECK/make_inputs.log" 2>&1
status=$?
sed 's/^/        /' "$CHECK/make_inputs.log" | tail -n 12
[[ $status -eq 0 ]] || { echo "ERROR make_inputs.sh exit $status, see $CHECK/make_inputs.log"; exit 1; }
echo
echo "RESULT: $REPO pinned at $NEW in ${#FILES[@]} files and INPUTS.tsv; verify_pins.sh, reproduce_analytic.sh and review.sh exit 0 in $CHECK"
echo "        (their SKIP lines above are not passes; the acceptance trial covers them)"
echo "Next: commit and push this repository, then REVIEW_MIRROR.md 'Moving a pin', steps 3-5."
