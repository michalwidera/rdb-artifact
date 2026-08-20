#!/usr/bin/env bash
# Analytic reproduction: regenerate the paper's tables and headline numbers from
# stored campaign data. No engine build, no measurement hardware, no worker.
#
# Every group runs the campaign's own frozen analysis code over data already in
# the pinned rdb-experiment checkout, writes its products under tables/<group>/,
# and reports CARDINALITIES rather than a bare "OK" -- a check that cannot state
# how much it compared is not a check (K9b step 6).
#
# The workspace is disposable by design: groups whose frozen scripts write next
# to their inputs are allowed to do so there, and the script reports how many
# files they touched. Nothing is ever written to a repository outside it.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="${RDB_WORKSPACE:-./artifact-workspace}"
OUT="$HERE/tables"
GROUP="all"
XRETRACTOR="${RDB_XRETRACTOR:-}"
XQRY="${RDB_XQRY:-}"
ALL_GROUPS=(k6c k22v5 k24e k26v3 g3 k19 k18 ecg)

usage() {
  cat <<'EOF'
Usage: ./bin/reproduce_analytic.sh [options]

Options:
  --workspace DIR   pinned checkout produced by bin/checkout.sh
                    (default: $RDB_WORKSPACE or ./artifact-workspace)
  --group NAME      one of: k6c k22v5 k24e k26v3 g3 k19 k18 ecg, or "all"
  --out DIR         where to write regenerated products (default: ./tables)
  --xretractor P    engine binary, needed only by the ecg group (fig:qrs)
  --xqry P          query client, needed only by the ecg group (fig:qrs)
  -h, --help        this text

Runs bin/verify_pins.sh first and refuses to regenerate anything if the
workspace does not match MANIFEST.md.
EOF
}

fail() { echo "ERROR: $*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace) [ "$#" -ge 2 ] || fail "--workspace needs a value"; WORKSPACE="$2"; shift 2 ;;
    --group)     [ "$#" -ge 2 ] || fail "--group needs a value";     GROUP="$2";     shift 2 ;;
    --out)       [ "$#" -ge 2 ] || fail "--out needs a value";       OUT="$2";       shift 2 ;;
    --xretractor) [ "$#" -ge 2 ] || fail "--xretractor needs a value"; XRETRACTOR="$2"; shift 2 ;;
    --xqry)       [ "$#" -ge 2 ] || fail "--xqry needs a value";       XQRY="$2";       shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

[ -d "$WORKSPACE" ] || fail "workspace not found: $WORKSPACE (run bin/checkout.sh first)"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"
EXP="$WORKSPACE/rdb-experiment"
[ -d "$EXP/.git" ] || fail "no rdb-experiment checkout in $WORKSPACE"
command -v python3 >/dev/null || fail "python3 not found"

mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

if [[ "$GROUP" == all ]]; then
  SELECTED=("${ALL_GROUPS[@]}")
else
  # shellcheck disable=SC2076
  [[ " ${ALL_GROUPS[*]} " == *" $GROUP "* ]] || fail "unknown group: $GROUP"
  SELECTED=("$GROUP")
fi

echo "=== 0. Provenance gate ==="
RDB_WORKSPACE="$WORKSPACE" "$HERE/bin/verify_pins.sh" snapshot >"$OUT/verify_pins.log" 2>&1 \
  || { cat "$OUT/verify_pins.log" >&2; fail "verify_pins.sh failed; refusing to regenerate"; }
echo "OK    workspace matches MANIFEST.md (log: tables/verify_pins.log)"
echo

STATUS_FILE="$(mktemp)"
trap 'rm -f "$STATUS_FILE"' EXIT

record() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$STATUS_FILE"; }

# Compare a regenerated product against the revision stored in git.
# $1 repo-relative path  $2 regenerated file  $3 optional filter (sed program)
compare_stored() {
  local rel="$1" got="$2" filter="${3:-}"
  local stored; stored="$(mktemp)"
  git -C "$EXP" show "HEAD:$rel" >"$stored" 2>/dev/null || { rm -f "$stored"; echo "     stored copy absent: $rel"; return 0; }
  if [ -n "$filter" ]; then
    if diff -q <(sed "$filter" "$stored") <(sed "$filter" "$got") >/dev/null; then
      echo "     identical to stored $rel (modulo generation timestamp)"
    else
      echo "     DIFFERS from stored $rel"; rm -f "$stored"; return 1
    fi
  elif cmp -s "$stored" "$got"; then
    echo "     byte-identical to stored $rel"
  else
    echo "     DIFFERS from stored $rel"; rm -f "$stored"; return 1
  fi
  rm -f "$stored"
}

group_k6c() {
  local dir="$EXP/results_20260730_K6c" out="$OUT/k6c"
  mkdir -p "$out"
  ( cd "$dir" && python3 analyze.py \
      --runs ablation/study_*/runs.csv \
      --compile-runs results/compile_runs.csv \
      --rate-json results/rate.json \
      --output "$out" ) >"$out/analyze.log" 2>&1
  python3 - "$out/analysis.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
c = d["counts"]
print(f"COUNT runs={d['runs']}")
print(f"COUNT cells={d['cases']}")
print(f"COUNT class_A={c['A']} class_B={c['B']} class_C={c['C']}")
print(f"COUNT rate_checked_cells={d['rate_checked_cases']}")
PY
  compare_stored "results_20260730_K6c/results/analysis.json" "$out/analysis.json"
}

group_k22v5() {
  local out="$OUT/k22v5"
  mkdir -p "$out"
  python3 "$HERE/bin/analytic_k22v5.py" --campaign "$EXP/results_20260801_K22v5"
  local res="$EXP/results_20260801_K22v5/results"
  cp "$res/verdict.md" "$res/constructs.csv" "$res/modifications.csv" "$out/"
  compare_stored "results_20260801_K22v5/results/verdict.md" "$out/verdict.md"
  compare_stored "results_20260801_K22v5/results/constructs.csv" "$out/constructs.csv"
  compare_stored "results_20260801_K22v5/results/modifications.csv" "$out/modifications.csv"
}

group_k24e() {
  local dir="$EXP/results_20260818_K24e" out="$OUT/k24e"
  mkdir -p "$out"
  ( cd "$dir" && python3 verdict.py --raw raw/campaign_seed20260818.csv \
      --out "$out/VERDICT.md" --seed 20260818 --engine e2a61ff ) >"$out/in_sample.log" 2>&1
  ( cd "$dir" && python3 verdict.py --raw raw/campaign_seed20260820.csv \
      --out "$out/VERDICT_oos.md" --seed 20260820 --engine e2a61ff ) >"$out/out_of_sample.log" 2>&1
  python3 - "$out/VERDICT.md" "$out/VERDICT_oos.md" <<'PY'
import re, sys

SECTIONS = (("tail", r"^## 1\. ", r"^## 1b\. "), ("origin", r"^## 1b\. ", r"^## 2\. "))

for label, path in (("in_sample", sys.argv[1]), ("out_of_sample", sys.argv[2])):
    text = open(path, encoding="utf-8").read()
    nums = re.findall(r"\*\*(\d[\d ]*) plan[^*]*\*\*, \*\*(\d[\d ]*) obserwacji", text)
    if nums:
        plans, obs = (x.replace(" ", "") for x in nums[0])
        print(f"COUNT {label}_plans={plans} {label}_node_observations={obs}")
    for name, start, end in SECTIONS:
        head = re.search(start, text, re.M)
        tail = re.search(end, text, re.M)
        block = text[head.end():tail.start()] if head and tail else ""
        rows = re.findall(r"^\| `([A-Z]+)` \|.*\| dokładna \|", block, re.M)
        print(f"COUNT {label}_{name}_exact_classes={len(set(rows))}")
PY
  compare_stored "results_20260818_K24e/VERDICT.md" "$out/VERDICT.md"
  compare_stored "results_20260818_K24e/VERDICT_oos.md" "$out/VERDICT_oos.md"
}

group_k26v3() {
  local dir="$EXP/results_20260814_K26v3" out="$OUT/k26v3"
  mkdir -p "$out"
  ( cd "$dir" && python3 verdict.py --matrix matrix ) >"$out/verdict.txt" 2>&1
  python3 - "$out/verdict.txt" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
print(f"COUNT families_supporting={len(re.findall(r'RODZINA: SUPPORT', text))}")
print(f"COUNT families_total={len(re.findall(r'^--- F9-', text, re.M))}")
m = re.search(r"Rodzin wspierajacych H9: (\d+)/(\d+)", text)
if m:
    print(f"COUNT verdict_rule={m.group(1)}_of_{m.group(2)}")
print("COUNT verdict_supported=" + ("1" if "H9 WSPARTA" in text else "0"))
PY
  wc -l < "$EXP/results_20260814_K26v3/matrix/gates.tsv" | xargs printf 'COUNT gate_rows=%s\n'
}

group_g3() {
  local dir="$EXP/results_20260726_G3" out="$OUT/g3"
  mkdir -p "$out"
  ( cd "$dir" && python3 make_summary.py ) >"$out/make_summary.log" 2>&1
  cp "$dir/results/summary.md" "$out/summary.md"
  python3 - "$dir/results/equivalence.json" "$dir/results/engine.json" <<'PY'
import json, sys
eq = json.load(open(sys.argv[1], encoding="utf-8"))
en = json.load(open(sys.argv[2], encoding="utf-8"))
totals = eq["totals"]
print(f"COUNT oracle_cases={totals['cases']}")
print(f"COUNT oracle_positions={totals['positions']}")
print(f"COUNT oracle_mismatches={totals['mismatches']}")
print(f"COUNT mutations={len(eq['mutations'])}")
print(f"COUNT engine_identity_checks={len(en['cases'])}")
print(f"COUNT oracle_verdict={eq['verdict']} engine_verdict={en['verdict']}")
PY
  compare_stored "results_20260726_G3/results/summary.md" "$out/summary.md" '/^- wygenerowano:/d'
}

group_k19() {
  local dir="$EXP/results_20260728_K19" out="$OUT/k19"
  mkdir -p "$out"
  ( cd "$dir" && python3 test_boundaries.py --limit 24 --json "$out/oracle.json" ) >"$out/oracle.txt" 2>&1
  python3 - "$out/oracle.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
print(f"COUNT subtract_phase_checks={d['subtract_phase_checks']}")
print(f"COUNT agse_phase_checks={d['agse_phase_checks']}")
print(f"COUNT mutations={len(d['mutations'])}")
print(f"COUNT verdict={d['verdict']}")
PY
  compare_stored "results_20260728_K19/results/oracle.json" "$out/oracle.json"
}

group_k18() {
  local dir="$EXP/results_20260728_K18/exactness" out="$OUT/k18"
  mkdir -p "$out"
  [ -f "$dir/replay_compare.txt" ] || fail "K18: stored replay comparison missing"
  cp "$dir/replay_compare.txt" "$dir/roundtrip_compare.txt" "$dir/results.md" "$out/"
  local artifacts meta identical checks
  artifacts=$(wc -l <"$out/replay_compare.txt")
  meta=$(grep -c '^IDENT-PO-TIMESTAMP' "$out/replay_compare.txt" || true)
  identical=$(grep -c '^IDENTYCZNY' "$out/replay_compare.txt" || true)
  checks=$(grep -c ': True$' "$out/roundtrip_compare.txt" || true)
  echo "COUNT replay_artifacts_compared=$artifacts"
  echo "COUNT meta_compared_after_timestamp=$meta"
  echo "COUNT byte_identical=$identical"
  echo "COUNT roundtrip_checks_passed=$checks"
  grep -q '^VERDICT: OK$' "$out/roundtrip_compare.txt" || fail "K18: stored round-trip verdict is not OK"
  grep -q '^ROZNY' "$out/replay_compare.txt" && fail "K18: stored replay comparison contains a mismatch"
  [ "$artifacts" -gt 0 ] || fail "K18: empty comparison set"
  echo "COUNT verdict=OK"
}

# fig:qrs is the one figure that needs a running engine, so it is the one group
# that can be skipped without failing the run. The window rule is what makes it
# deterministic: -p 400,400 fixes the window SIZE, -m 1671 fixes its POSITION.
QRS_SAMPLES=1671
QRS_PEAKS="128 372"

group_ecg() {
  local out="$OUT/ecg"
  mkdir -p "$out"
  if [ -z "$XRETRACTOR" ] || [ -z "$XQRY" ]; then
    cat <<EOF
SKIP  fig:qrs needs a running engine; pass --xretractor and --xqry to regenerate it.
      Deterministic recipe (also recorded in the paper source next to the figure):
        cd retractordb/examples/ecg/rec205
        xretractor rec205-qrs.rql -r -k -x -m $QRS_SAMPLES
        xqry -w -s qrs_out -p 400,400 -m $QRS_SAMPLES | gnuplot
      The final frame is always samples [$((QRS_SAMPLES - 400)),$((QRS_SAMPLES - 1))]
      of qrs_out, with QRS complexes at x=$QRS_PEAKS.
COUNT regenerated=0
EOF
    return 0
  fi

  # The figure must come from the pinned engine, not from whatever binary
  # happens to be on PATH, so the same gate the measurement mode uses applies.
  local engine_rev; engine_rev="$(git -C "$WORKSPACE/retractordb" rev-parse HEAD)"
  "$HERE/bin/verify_binary.sh" "$engine_rev" "$XRETRACTOR" \
    || fail "ecg: engine binary does not come from the pinned $engine_rev"

  local work; work="$(mktemp -d)"
  local src="$EXP/../retractordb/examples/ecg/rec205"
  [ -d "$src" ] || { rm -rf "$work"; fail "ECG inputs missing: $src"; }
  cp "$src"/rec205 "$src"/bp_coef.txt "$src"/d_coef.txt "$src"/rec205-qrs.rql "$work/"
  (
    cd "$work"
    "$XRETRACTOR" rec205-qrs.rql -r -k -x -m "$QRS_SAMPLES" >server.log 2>&1 &
    sleep 5
    "$XQRY" -w -s qrs_out -p 400,400 -m "$QRS_SAMPLES" >plot.txt 2>&1
  )
  local last; last="$(grep -n '^plot' "$work/plot.txt" | tail -1 | cut -d: -f1)"
  [ -n "$last" ] || { rm -rf "$work"; fail "ECG: xqry produced no plot frame"; }
  sed -n "$((last + 1)),\$p" "$work/plot.txt" >"$out/final_frame.txt"

  python3 - "$out/final_frame.txt" "$QRS_PEAKS" <<'PY'
import sys
rows = []
for line in open(sys.argv[1], encoding="utf-8"):
    parts = line.split()
    if len(parts) == 2 and parts[0].lstrip("-").isdigit():
        rows.append((int(parts[0]), int(parts[1])))
    if line.strip() == "e" and rows:
        break
peaks, run = [], []
for x, y in rows:
    if y > 200:
        run.append(x)
    elif run:
        peaks.append(sum(run) // len(run)); run = []
if run:
    peaks.append(sum(run) // len(run))
expected = [int(v) for v in sys.argv[2].split()]
print(f"COUNT samples_in_frame={len(rows)}")
print(f"COUNT qrs_complexes={len(peaks)}")
print(f"COUNT peak_positions={','.join(str(p) for p in sorted(peaks))}")
if len(rows) != 400:
    raise SystemExit(f"ERROR: frame holds {len(rows)} samples, expected 400")
if len(peaks) != len(expected) or any(abs(a - b) > 3 for a, b in zip(sorted(peaks), expected)):
    raise SystemExit(f"ERROR: peaks {sorted(peaks)} do not match the pinned window {expected}")
PY

  if command -v gnuplot >/dev/null 2>&1; then
    { echo "set term pngcairo size 636,476 font 'Sans,10'"
      echo "set output '$out/rec205-qrs.png'"
      sed -n '2,7p' "$work/plot.txt"
      sed -n "$last,\$p" "$work/plot.txt"; } >"$work/final.gp"
    gnuplot "$work/final.gp" && echo "     rendered $out/rec205-qrs.png"
  else
    echo "     gnuplot absent; frame data written, figure not rendered"
  fi
  rm -rf "$work"
}

FAILED=0
for g in "${SELECTED[@]}"; do
  echo "=== $g ==="
  before=$(git -C "$EXP" status --porcelain | wc -l)
  if "group_$g"; then
    if [[ "$g" == ecg && ( -z "$XRETRACTOR" || -z "$XQRY" ) ]]; then
      record "$g" SKIP "fig:qrs needs --xretractor and --xqry"
    else
      record "$g" OK ""
    fi
  else
    record "$g" FAIL "see output above"; FAILED=$((FAILED + 1))
  fi
  after=$(git -C "$EXP" status --porcelain | wc -l)
  echo "     workspace files touched by this group: $((after - before))"
  echo
done

echo "=== summary ==="
printf '%-8s %-6s %s\n' GROUP STATUS NOTE
while IFS=$'\t' read -r g s n; do printf '%-8s %-6s %s\n' "$g" "$s" "$n"; done <"$STATUS_FILE"
echo
echo "Products: $OUT"
echo "Workspace modifications are expected and confined to $EXP (disposable checkout)."

if [ "$FAILED" -gt 0 ]; then
  echo "RESULT: $FAILED group(s) failed"
  exit 1
fi
if grep -q $'\tSKIP\t' "$STATUS_FILE"; then
  echo "RESULT: all selected groups regenerated except skipped ones (see above)"
else
  echo "RESULT: all selected groups regenerated"
fi
