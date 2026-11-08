#!/usr/bin/env bash
# One command for a reviewer: fetch the inputs, verify them, regenerate the
# analytic products, compare them with the stored ones, and write a report.
#
#   bash bin/review.sh                    # from the reviewer mirror: no git, no account
#   bash bin/review.sh --workspace DIR    # from clones made by bin/checkout.sh
#
# Options:
#   --workspace DIR  use the pinned clones in DIR (verified by bin/verify_pins.sh)
#                    instead of fetching from the mirror
#   --dest DIR       where the mirror path keeps its inputs and both paths their
#                    products (default: ./review-workspace)
#   --report FILE    the report (default: ./review-report.md)
#   --source DIR     a local directory in place of the mirror service (see
#                    bin/fetch_mirror.sh); for the author's checks only
#   -h, --help       this text
#
# Needs bash 4 or later, python3 3.8 or later, the POSIX tools named below and
# 100 MB of free space. The mirror path downloads about 8 MB in under 100
# requests; the service paces requests (bin/fetch_mirror.sh), so a run usually
# takes a few minutes and can take longer when the address has spent its budget.
#
# The run passes when every input matches INPUTS.tsv, every group regenerates
# (the ecg group is skipped, with its reason, unless the engine binaries are
# given to bin/reproduce_analytic.sh), every product with a stored copy equals
# it, and every COUNT line equals the one INPUTS.tsv expects.
#
# Exit status: 0 - PASS, 1 - FAIL (the report names what failed), 2 - a
# prerequisite is missing or the options are wrong.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE=""
DEST="./review-workspace"
REPORT="./review-report.md"
SOURCE=""
INPUTS="${RDB_INPUTS:-$HERE/INPUTS.tsv}"
TOOLS=(awk cat cksum cmp comm cp cut diff find grep head mkdir mktemp rm sed sort tail tee uname wc)

usage() { sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
fail() { echo "ERROR: $*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace) [ "$#" -ge 2 ] || fail "--workspace needs a value"; WORKSPACE="$2"; shift 2 ;;
    --dest)      [ "$#" -ge 2 ] || fail "--dest needs a value";      DEST="$2";      shift 2 ;;
    --report)    [ "$#" -ge 2 ] || fail "--report needs a value";    REPORT="$2";    shift 2 ;;
    --source)    [ "$#" -ge 2 ] || fail "--source needs a value";    SOURCE="$2";    shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done
[ -z "$WORKSPACE" ] || [ -z "$SOURCE" ] || fail "--workspace and --source exclude each other"

echo "=== prerequisites ==="
[ "${BASH_VERSINFO[0]}" -ge 4 ] || fail "bash ${BASH_VERSION} is too old; bash 4 or later is needed"
for t in "${TOOLS[@]}"; do
  command -v "$t" >/dev/null || fail "$t not found on PATH"
done
command -v python3 >/dev/null || fail "python3 not found on PATH"
python3 -c 'import sys; sys.exit(sys.version_info < (3, 8))' \
  || fail "python3 $(python3 -c 'import platform; print(platform.python_version())') is too old; 3.8 or later is needed"
[ -r "$INPUTS" ] || fail "cannot read $INPUTS"
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"
free_kb="$(df -Pk "$DEST" | awk 'NR == 2 { print $4 }')"
[ "${free_kb:-0}" -ge 102400 ] || fail "less than 100 MB free in $DEST"
PYVER="$(python3 -c 'import platform; print(platform.python_version())')"
echo "OK    bash $BASH_VERSION, python3 $PYVER, $((free_kb / 1024)) MB free"
echo

START="$(date -u +%s)"
STARTED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LOG="$DEST/review.log"
: >"$LOG"
FETCH_RC=0
FETCH_LINE=""
if [ -z "$WORKSPACE" ]; then
  MODE="reviewer mirror"
  [ -z "$SOURCE" ] || MODE="local directory $SOURCE (author's check, not the mirror)"
  echo "=== fetching the inputs from the $MODE ===" | tee -a "$LOG"
  set +e
  bash "$HERE/bin/fetch_mirror.sh" --dest "$DEST" ${SOURCE:+--source "$SOURCE"} 2>&1 | tee -a "$LOG"
  FETCH_RC="${PIPESTATUS[0]}"
  set -e
  FETCH_LINE="$(grep '^FETCH ' "$LOG" | tail -n 1 || true)"
  ANALYTIC=(--snapshot --workspace "$DEST")
else
  MODE="pinned clones in $WORKSPACE"
  ANALYTIC=(--workspace "$WORKSPACE")
fi
echo | tee -a "$LOG"

RUN_RC=0
if [ "$FETCH_RC" -eq 0 ]; then
  set +e
  bash "$HERE/bin/reproduce_analytic.sh" "${ANALYTIC[@]}" --out "$DEST/tables" 2>&1 | tee -a "$LOG"
  RUN_RC="${PIPESTATUS[0]}"
  set -e
else
  RUN_RC=skipped
fi
ELAPSED=$(( $(date -u +%s) - START ))

# Verdict and report from the log; the expected counts are the "# expect" lines of INPUTS.tsv.
set +e
python3 -I - "$LOG" "$INPUTS" "$HERE/MANIFEST.md" "$REPORT" "$MODE" "$STARTED" "$ELAPSED" \
  "$FETCH_RC" "$RUN_RC" "$FETCH_LINE" "$PYVER" "$(uname -sm)" <<'PY'
import re, sys

(log, inputs, manifest, report, mode, started, elapsed, fetch_rc, run_rc, fetch_line,
 pyver, platform) = sys.argv[1:13]
text = open(log, encoding="utf-8", errors="replace").read()

expected = {}
for line in open(inputs, encoding="utf-8"):
    m = re.match(r"^# expect (\w+) (COUNT .*)$", line.rstrip("\n"))
    if m:
        expected.setdefault(m.group(1), []).append(m.group(2))
pins = []
for line in open(manifest, encoding="utf-8"):
    m = re.match(r"^\| `([^`]+)` \| [^|]* \| `([0-9a-f]{40})` \|", line)
    if m and m.group(1) not in [p[0] for p in pins]:
        pins.append((m.group(1), m.group(2)))

groups, status, current = {}, {}, None
for line in text.splitlines():
    m = re.match(r"^=== (\w+) ===$", line)
    if m:
        current = m.group(1)
        groups[current] = []
        continue
    if line.startswith("=== "):
        current = None
        continue
    if current:
        groups[current].append(line)
for line in text.split("=== summary ===")[-1].splitlines():
    m = re.match(r"^(\w+)\s+(OK|SKIP|FAIL)\b\s*(.*)$", line)
    if m and m.group(1) != "GROUP":
        status[m.group(1)] = (m.group(2), m.group(3))

problems = []
if fetch_rc != "0":
    problems.append("inputs: " + ("; ".join(re.findall(r"^FAIL  (.*)$", text, re.M)) or "fetch failed"))
if fetch_rc == "0" and run_rc != "0":
    problems.append(f"bin/reproduce_analytic.sh exit {run_rc}")
rows, counts_ok, counts_all = [], 0, 0
for g, exp in expected.items():
    got = [l for l in groups.get(g, []) if l.startswith("COUNT ")]
    same = sum(1 for a, b in zip(exp, got) if a == b) if len(exp) == len(got) else 0
    counts_ok += same
    counts_all += len(exp)
    st, note = status.get(g, ("not run", ""))
    stored = [l.strip() for l in groups.get(g, []) if "stored" in l]
    identical = sum(1 for l in stored if l.startswith(("byte-identical", "identical")))
    differs = [l for l in stored if l.startswith(("DIFFERS", "stored copy absent"))]
    rows.append((g, st, note, f"{same}/{len(exp)}", f"{identical}/{len(stored)}" if stored else "-"))
    if fetch_rc != "0":
        continue  # nothing ran; the inputs are the finding
    if st == "FAIL" or st == "not run":
        problems.append(f"group {g}: {st}")
    if differs:
        problems.append(f"group {g}: " + "; ".join(differs))
    if same != len(exp):
        problems.append(f"group {g}: {same} of {len(exp)} COUNT lines as expected")

verdict = "FAIL" if problems else "PASS"
inputs_line = (re.findall(r"^(?:OK    )?(INPUTS .*)$", text, re.M)
               or ["INPUTS: pinned clones, verified by bin/verify_pins.sh"
                   if mode.startswith("pinned clones") else "INPUTS not checked"])[-1]
out = [f"# Review report", "",
       f"**Verdict: {verdict}**", "",
       f"- source of the inputs: {mode}",
       f"- started: {started}; elapsed: {elapsed} s",
       f"- platform: {platform}, python3 {pyver}",
       f"- {inputs_line}"]
if fetch_line:
    out.append(f"- {fetch_line}")
out.append(f"- COUNT lines as expected: {counts_ok} of {counts_all}")
out += ["", "## Pins (MANIFEST.md section 1)", ""] + [f"- `{r}` `{s}`" for r, s in pins]
out += ["", "## Groups", "", "| group | status | COUNT lines | stored products identical | note |",
        "|---|---|---|---|---|"]
out += [f"| {g} | {st} | {c} | {i} | {note} |" for g, st, note, c, i in rows]
if problems:
    out += ["", "## What failed", ""] + [f"- {p}" for p in problems]
out += ["", f"Full transcript: `{log}`.", ""]
open(report, "w", encoding="utf-8").write("\n".join(out))
print()
print("=== review ===")
for g, st, note, c, i in rows:
    print(f"{g:8} {st:6} counts {c:6} stored {i:6} {note}")
print(inputs_line)
if fetch_line:
    print(fetch_line)
for p in problems:
    print(f"FAIL  {p}")
print(f"VERDICT {verdict}: {len(rows)} groups, {counts_ok} of {counts_all} COUNT lines as expected; report {report}")
sys.exit(1 if problems else 0)
PY
rc=$?
set -e
exit "$rc"
