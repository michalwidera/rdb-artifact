#!/usr/bin/env bash
# Remeasure the deterministic quantities of the paper with the prebuilt engine
# bundles and compare every one exactly with the stored result. No git and no
# compiler: the engine comes from the bundles that MANIFEST.md section 7
# declares, the apparatus and the stored results from the pinned trees.
#
#   bash bin/reproduce_remeasure.sh --workspace DIR [--out DIR] [--jobs N]
#
# DIR holds the inputs at DIR/<repository>/<path>: the snapshot that
# bin/fetch_mirror.sh fetches with REMEASURE.tsv (what bin/review.sh
# --remeasure does), or clones at the pins.
#
# Options:
#   --workspace DIR  the inputs (required)
#   --out DIR        products, logs and the unpacked bundles
#                    (default: ./tables/remeasure)
#   --jobs N         parallel compilations of the k24 group (default: nproc)
#   -h, --help       this text
#
# Groups, in this order; a group runs only when the groups it needs passed, so
# a failed bundles group stops the run before anything is measured:
#   bundles    SHA-256 of each bundle of this architecture equals MANIFEST.md;
#              every binary reports the pinned revision; xretractor
#              --build-info equals its profile row of profiles.tsv
#   plans      84 plan dumps and 4 rejected controls of the H9 corpus
#              (validate_corpus.py), identical to the stored evidence
#   p6         the H9 runs on the main data, 4 profiles x 21 plans
#              (run_main_rdb.sh, unchanged): every file identical to the stored
#              tree (LOGICAL write bytes per public record, WORK counter, public
#              artifacts)
#   gates      corpus_validity, oracle_mutants, public_identity,
#              near_miss_controls and no_materialization clean in every family;
#              reduction at Q=8 within the predeclared tolerance
#   mechanism  substrate counts, R1/R2 and counters of the Q grid: the RDB rows
#              of K26v3 matrix/mechanism.tsv; the Flink rows are taken from that
#              record and not measured again
#   k24        tail accounting on 10 010 plans, K24e and K24f, two seeds each:
#              raw CSV and VERDICT identical to the stored ones
#   ecg        traffic ratio of examples/ecg/rec205_h10 at 100/200/300/500 s:
#              records and bytes equal to the pinned values below
#
# What it does not claim: the bundle sums prove that the declared bundles ran,
# not that they were built from the declared sources (that proof is a build
# from the pinned sources, REPRODUCE.md section 4). Time is not measured. The
# p6 and ecg runs are paced in real time and take about 45 and 20 minutes.
#
# Exit status: 0 - every group OK, 1 - a group failed, 2 - usage or environment.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE=""
OUT="./tables/remeasure"
JOBS=""
H9="results_20261103_R593_H9"
K24E="results_20260818_K24e"
K24F="results_20260912_K24f"
TOOLS=(awk cat cmp column cp cut diff find grep gzip head mkdir mktemp nproc pgrep rm sed sha256sum sort stat tail tar timeout uname wc)

# Expected results.tsv of examples/ecg/rec205_h10/experiment.sh for the four
# runs. Measured for the paper (research plan section 14.32 of the paper
# repository, commit 6dec187, engine of that date) and reproduced on the pinned
# engine e389edd3 on x86_64 on 2026-11-08 (retractordb #588, step 0); the
# experiment data are not in rdb-experiment, so the values are pinned here.
ECG_SLOTS="36000 72000 108000 180000"
ECG_EXPECTED='slots	sec	raw_rec	raw_b	ship_rec	ship_b	ratio	tail_deficit
36000	100.0	35999	287992	3540	28320	10.1692	59
72000	200.0	71999	575992	7140	57120	10.0839	59
108000	300.0	107999	863992	10740	85920	10.0558	59
180000	500.0	179999	1439992	17940	143520	10.0334	59'

usage() { sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
fail() { echo "ERROR: $*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace) [ "$#" -ge 2 ] || fail "--workspace needs a value"; WORKSPACE="$2"; shift 2 ;;
    --out)       [ "$#" -ge 2 ] || fail "--out needs a value";       OUT="$2";       shift 2 ;;
    --jobs)      [ "$#" -ge 2 ] || fail "--jobs needs a value";      JOBS="$2";      shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done
[ -n "$WORKSPACE" ] || { usage >&2; fail "--workspace is required"; }
for t in "${TOOLS[@]}"; do
  command -v "$t" >/dev/null || fail "$t not found on PATH"
done
command -v python3 >/dev/null || fail "python3 not found on PATH"
JOBS="${JOBS:-$(nproc)}"
[[ "$JOBS" =~ ^[1-9][0-9]*$ ]] || fail "--jobs must be a positive integer"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"
EXP="$WORKSPACE/rdb-experiment"
ENG="$WORKSPACE/retractordb"
[ -d "$EXP/$H9" ] || fail "no $H9 in $EXP"
case "$(uname -m)" in
  x86_64|amd64) ARCH=x86_64 ;;
  aarch64|arm64) ARCH=aarch64 ;;
  *) fail "no bundles for $(uname -m); they exist for x86_64 and aarch64" ;;
esac
# run_main_rdb.sh refuses to start when any command line on the machine contains
# the word xretractor (a leaked engine once broke 22 later runs); ask the same
# question before anything runs, not 2 minutes in.
if pgrep -af '[x]retractor' >/dev/null; then
  pgrep -af '[x]retractor' | cut -c1-160 >&2
  fail "a process whose command line names xretractor is running (above); run_main_rdb.sh refuses to start next to it"
fi

PIN="$(sed -nE 's/^\| `retractordb` \| [^|]* \| `([0-9a-f]{40})` \|.*/\1/p' "$HERE/MANIFEST.md" | head -n 1)"
BPIN="$(sed -nE 's/^\| `rdb-binaries` \| [^|]* \| `([0-9a-f]{40})` \|.*/\1/p' "$HERE/MANIFEST.md" | head -n 1)"
[ -n "$PIN" ] || fail "no retractordb pin in MANIFEST.md section 1"
[ -n "$BPIN" ] || fail "no rdb-binaries pin in MANIFEST.md section 1"
BUNDLE_DIR="$WORKSPACE/rdb-binaries/$PIN"
[ -d "$BUNDLE_DIR" ] || fail "no bundles for the engine pin in $BUNDLE_DIR"

mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
WORK="$OUT/work"
rm -rf "$WORK"
mkdir -p "$WORK"
STATUS_FILE="$OUT/status.tsv"
: >"$STATUS_FILE"
record() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$STATUS_FILE"; }
export PYTHONDONTWRITEBYTECODE=1

# The profile rows of the H9 campaign: profile, slug, dedup, share, commutative, factor.
PROFILES_TSV="$EXP/$H9/profiles.tsv"
mapfile -t ROWS < <(awk -F'\t' 'NR > 1 && NF == 6' "$PROFILES_TSV")
SHIM="$WORK/shim"           # CODE_REPO for the apparatus: build/R593-<slug>/src/retractor/xretractor
DEFAULT_BIN="$WORK/bundles/DEFAULT/bin"

# --- bundles ------------------------------------------------------------------
group_bundles() {
  [ "${#ROWS[@]}" -ge 1 ] || { echo "FAIL  no profile rows in $PROFILES_TSV"; return 1; }
  local row profile slug dedup share commutative factor name archive want got dir expected actual b n=0
  for row in "${ROWS[@]}"; do
    IFS=$'\t' read -r profile slug dedup share commutative factor <<<"$row"
    name="rdb-${PIN:0:12}-h9-$slug-linux-$ARCH.tar.gz"
    archive="$BUNDLE_DIR/$name"
    want="$(sed -nE "s/^\| \`${name//./\\.}\` \| [^|]* \| [^|]* \| \`([0-9a-f]{64})\` \|.*/\1/p" "$HERE/MANIFEST.md" | head -n 1)"
    [ -n "$want" ] || { echo "FAIL  $name: not declared in MANIFEST.md section 7"; return 1; }
    [ -r "$archive" ] || { echo "FAIL  $name: missing from $BUNDLE_DIR"; return 1; }
    got="$(sha256sum "$archive" | cut -d' ' -f1)"
    [ "$got" = "$want" ] || { echo "FAIL  $name: SHA-256 $got, MANIFEST.md declares $want"; return 1; }
    dir="$WORK/bundles/$slug"
    mkdir -p "$dir"
    tar -xzf "$archive" -C "$dir" --strip-components=1
    for b in xretractor xqry xtrdb; do
      [ -x "$dir/bin/$b" ] || { echo "FAIL  $name: no executable bin/$b"; return 1; }
      if ! bash "$HERE/bin/verify_binary.sh" "$PIN" "$dir/bin/$b" >/dev/null 2>"$WORK/verify.err"; then
        echo "FAIL  $name: bin/$b: $(cat "$WORK/verify.err")"
        # A binary that does not start (an older glibc, say) says why on its first lines.
        if grep -q "cannot read build identity" "$WORK/verify.err"; then
          "$dir/bin/$b" --help 2>&1 | head -n 2 | sed 's/^/      /'
        fi
        return 1
      fi
    done
    expected="$(printf '%s\n' \
      "RDB_OPT_DEDUP_SUBSTRATES=$dedup" \
      "RDB_OPT_SHARE_EQUIVALENT_SELECTS=$share" \
      "RDB_OPT_COMMUTATIVE_ADD=$commutative" \
      "RDB_OPT_FACTOR_MATCHED_HASH_TIMEMOVES=$factor" \
      "RDB_BENCH_PROBE=ON" \
      "RDB_OPT_SIMPLIFY_EXPRESSIONS=ON")"
    actual="$("$dir/bin/xretractor" --build-info 2>&1)" || true
    if [ "$actual" != "$expected" ]; then
      echo "FAIL  $name: xretractor --build-info is not profile $profile:"
      diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") | sed 's/^/      /' || true
      return 1
    fi
    mkdir -p "$SHIM/build/R593-$slug/src/retractor"
    ln -sf "$dir/bin/xretractor" "$SHIM/build/R593-$slug/src/retractor/xretractor"
    echo "OK    $name: SHA-256 as declared, revision ${PIN:0:12}, profile $profile"
    n=$((n + 1))
  done
  [ -x "$DEFAULT_BIN/xretractor" ] || { echo "FAIL  no DEFAULT bundle"; return 1; }
  echo "COUNT bundles_verified=$n binaries_verified=$((3 * n))"
}

# A working copy of the H9 apparatus: validate_corpus.py writes its evidence next
# to itself and refuses to overwrite it, so the stored evidence stays apart.
APP="$WORK/apparatus/$H9"
prepare_apparatus() {
  # data/calib is not run here, but validate_corpus.py checks the whole generated corpus.
  mkdir -p "$APP"
  (cd "$EXP/$H9" \
    && cp -p analyze_r593.py gen_corpus.py mechanism_table.py oracle_values.py reduce_results.py \
         run_gates.py validate_corpus.py verdict.py run_main_rdb.sh profiles.tsv "$APP/" \
    && cp -rp rql data "$APP/")
}

# --- plans --------------------------------------------------------------------
group_plans() {
  prepare_apparatus
  RDB_CODE_REPO="$SHIM" python3 -I - "$APP" "$EXP/$H9/corpus_validation" "$PIN" <<'PY'
import re, sys
from pathlib import Path

app, stored, pin = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
sys.path.insert(0, str(app))
import validate_corpus as vc

# The evidence records the engine revision through git. Here the revision is
# established by the bundles group (sums against MANIFEST.md, revision in every
# binary), so the git query is replaced by that result; nothing else changes.
def checked_code_sha(expected=None):
    if expected is not None and expected != pin:
        raise vc.GateError(f"engine SHA {pin}, evidence/start pin {expected}")
    return pin
vc.checked_code_sha = checked_code_sha

valid, rejected, checksums = vc.run_gate(app / "corpus_validation")
print(f"COUNT valid_compilations={valid} invalid_controls_rejected={rejected}")
new = app / "corpus_validation"
timing = re.compile(r"^COMPILE_NS .*\n", re.M)
workdir = re.compile(r"\S*/k26-compile-[^/\s]+/")
def norm(text):
    return workdir.sub("<work>/", timing.sub("", text))
dumps = same = logs = same_logs = 0
problems = []
for path in sorted((stored / "plans").rglob("*")):
    if not path.is_file():
        continue
    rel = path.relative_to(stored)
    mine = new / rel
    if not mine.is_file():
        problems.append(f"{rel}: not produced")
        continue
    if path.suffix == ".stderr":
        logs += 1
        same_logs += norm(path.read_text()) == norm(mine.read_text())
        if norm(path.read_text()) != norm(mine.read_text()):
            problems.append(f"{rel}: differs (compile timing and work directory aside)")
    else:
        dumps += 1
        same += path.read_bytes() == mine.read_bytes()
        if path.read_bytes() != mine.read_bytes():
            problems.append(f"{rel}: differs")
extra = sorted(str(p.relative_to(new)) for p in (new / "plans").rglob("*")
               if p.is_file() and not (stored / p.relative_to(new)).is_file())
problems += [f"{p}: not in the stored evidence" for p in extra]
cut = lambda f: [l.split("\t")[:4] for l in f.read_text().splitlines()]
if cut(stored / "corpus-validation.tsv") != cut(new / "corpus-validation.tsv"):
    problems.append("corpus-validation.tsv: columns 1-4 differ")
print(f"COUNT plan_dumps_identical={same}/{dumps} plan_logs_identical={same_logs}/{logs}")
for p in problems:
    print(f"DIFFERS {p}")
if not problems:
    print("     byte-identical to the stored evidence corpus_validation/plans (logs without COMPILE_NS)")
sys.exit(1 if problems else 0)
PY
}

# --- p6 -----------------------------------------------------------------------
group_p6() {
  local stored="$WORK/stored-p6" t0
  t0="$(date -u +%s)"
  (cd "$APP" && CODE_REPO="$SHIM" OUT="$WORK/p6" bash ./run_main_rdb.sh) >"$OUT/p6.log" 2>&1 \
    || { tail -n 15 "$OUT/p6.log"; echo "FAIL  run_main_rdb.sh, log $OUT/p6.log"; return 1; }
  tail -n 1 "$OUT/p6.log" | sed 's/^/     /'
  echo "     $(( $(date -u +%s) - t0 )) s"
  mkdir -p "$stored"
  tar -xzf "$EXP/artifacts/R593/r593_gates_rdb.tar.gz" -C "$stored"
  python3 -I - "$stored/gates_rdb" "$WORK/p6" <<'PY'
import hashlib, sys
from pathlib import Path
a, b = Path(sys.argv[1]), Path(sys.argv[2])
files = lambda root: {str(p.relative_to(root)): p for p in root.rglob("*") if p.is_file()}
fa, fb = files(a), files(b)
same = sum(1 for k in fa if k in fb and fa[k].read_bytes() == fb[k].read_bytes())
print(f"COUNT p6_files_identical={same}/{len(fa)} p6_files_produced={len(fb)}")
bad = sorted(k for k in fa if k not in fb or fa[k].read_bytes() != fb[k].read_bytes())
extra = sorted(set(fb) - set(fa))
for k in bad[:20]:
    print(f"DIFFERS {k}" if k in fb else f"DIFFERS {k}: not produced")
for k in extra[:20]:
    print(f"DIFFERS {k}: not in the stored tree")
if not bad and not extra:
    print("     byte-identical to the stored tree artifacts/R593/r593_gates_rdb.tar.gz")
sys.exit(1 if bad or extra else 0)
PY
}

# --- gates --------------------------------------------------------------------
group_gates() {
  mkdir -p "$WORK/mutants"
  RDB_CODE_REPO="$SHIM" XTRDB="$DEFAULT_BIN/xtrdb" python3 -I - "$APP" "$WORK/p6" "$PIN" "$WORK/mutants" <<'PY'
import sys
from pathlib import Path

app, p6, pin, work = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3], Path(sys.argv[4])
sys.path.insert(0, str(app))
import validate_corpus as vc

def checked_code_sha(expected=None):  # as in the plans group
    if expected is not None and expected != pin:
        raise vc.GateError(f"engine SHA {pin}, evidence/start pin {expected}")
    return pin
vc.checked_code_sha = checked_code_sha
import analyze_r593 as a

gates = a.run_p6_gates(p6, app / "corpus_validation" / "plans", work)
clean = failed = outside = 0
for family in a.verdict.FAMILIES:
    for g in a.GATES:
        if gates[family].get(g):
            failed += 1
            print(f"FAIL  {family} {g}: {gates[family][g]}")
        else:
            clean += 1
reductions = []
for family in a.verdict.FAMILIES:
    ablation = a.verdict.MINIMAL_ABLATION[family]
    red = a.verdict.reduction(a.logical_cell(p6, family, "DEFAULT"), a.logical_cell(p6, family, ablation))
    pred = a.verdict.PREDECLARED_RDB[family][a.Q]
    ok = abs(red - pred) <= a.verdict.CURVE_TOLERANCE
    outside += not ok
    reductions.append(f"{family}={red}")
    print(f"     {family}: reduction at Q={a.Q} {red} ({float(red):.6f}), predeclared {pred}"
          f" +- {a.verdict.CURVE_TOLERANCE} -> {'OK' if ok else 'OUTSIDE'}")
print(f"COUNT gates_clean={clean}/{clean + failed} reductions_within_tolerance={3 - outside}/3")
print("COUNT reduction_q8 " + " ".join(reductions))
sys.exit(1 if failed or outside else 0)
PY
}

# --- mechanism ----------------------------------------------------------------
group_mechanism() {
  python3 -I - "$APP" "$WORK/p6" "$APP/corpus_validation/plans" \
    "$EXP/results_20260814_K26v3/matrix/mechanism.tsv" "$OUT/mechanism_rdb.tsv" <<'PY'
import sys
from collections import Counter
from pathlib import Path

app, p6, plans, stored, out = (Path(x) for x in sys.argv[1:6])
sys.path.insert(0, str(app))
import mechanism_table
import reduce_results as rr

# The RDB part of reduce_results.mechanism_rows, on the same functions; the
# Flink rows are not measured here (they come from the stored record).
rql = app / "rql"
rows = []
for family in rr.FAMILIES:
    for q in rr.Q_GRID:
        plan = f"{rr.FAMILY_FILE[family]}_Q{q}"
        for profile in rr.PROFILES:
            cell_dir = p6 / profile / plan
            logical = rr.read_single_match(cell_dir / "cell.counters", rr.RDB_LOGICAL, "LOGICAL")
            work = rr.read_single_match(cell_dir / "cell.counters", rr.RDB_WORK, "WORK")
            shape = mechanism_table.cell(plans / profile / f"{plan}.plan",
                                         plans / profile / f"{plan}.stderr", rql / f"{plan}.rql")
            rows.append({
                "family": family, "system": "RDB", "profile": profile, "q": q,
                "instances": rr.rdb_instances(shape),
                "stream_selects": len(shape["selects"]),
                "substrates": len(shape["substrates"]),
                "r1": shape["r1"], "r2": shape["r2"],
                "substrate_bytes": logical[2], "public_appends": logical[3],
                "work_costly_evals": rr.costly_evals(family, logical[3], work[3]),
                "work_hash_picks": work[2], "work_add_merges": work[3],
            })
cols = rr.MECHANISM_COLUMNS
mine = sorted("\t".join(str(r[c]) for c in cols) for r in rows)
lines = stored.read_text().splitlines()
if lines[0].split("\t") != cols:
    sys.exit("FAIL  stored mechanism.tsv has other columns")
theirs = sorted(l for l in lines[1:] if l.split("\t")[1] == "RDB")
flink = [l for l in lines[1:] if l.split("\t")[1] != "RDB"]
out.write_text("\t".join(cols) + "\n" + "\n".join(mine) + "\n")
same = sum((Counter(mine) & Counter(theirs)).values())
print(f"COUNT mechanism_rdb_rows_identical={same}/{len(theirs)} mechanism_rows_produced={len(mine)}")
print(f"COUNT mechanism_flink_rows_from_record={len(flink)}")
if mine != theirs:
    for l in sorted(set(theirs) - set(mine))[:10]:
        print(f"DIFFERS stored row not reproduced: {l}")
    sys.exit(1)
print("     identical to the stored RDB rows of results_20260814_K26v3/matrix/mechanism.tsv")
PY
}

# --- k24 ----------------------------------------------------------------------
k24_run() {  # tag apparatus stored_csv seed verdict_cmd stored_verdict engine_label [flags]
  local tag=$1 app=$2 stored=$3 seed=$4 vcmd=$5 vstored=$6 engine=$7
  shift 7
  local out="$OUT/k24/$tag-$(basename "$stored")"
  (cd "$app" && python3 run_campaign.py --seed "$seed" --count 10010 --xretractor "$DEFAULT_BIN/xretractor" \
     --out "$out" --workers "$JOBS" "$@") >"$out.log" 2>&1 \
    || { tail -n 5 "$out.log"; echo "FAIL  $tag seed $seed: run_campaign.py, log $out.log"; return 1; }
  echo "     $tag seed $seed: $(tail -n 1 "$out.log")"
  # The engine label is the campaign's own (it is printed into VERDICT); the
  # engine that ran is the bundle checked by the bundles group.
  (cd "$app" && python3 $vcmd --raw "$out" --out "$out.verdict.md" --seed "$seed" --engine "$engine") \
    >"$out.verdict.log" 2>&1 || true
  K24_RUNS=$((K24_RUNS + 1))
  if cmp -s "$stored" "$out"; then K24_CSV=$((K24_CSV + 1)); echo "     byte-identical to the stored ${stored#"$EXP/"}"
  else echo "DIFFERS ${stored#"$EXP/"}: $(cmp "$stored" "$out" 2>&1 | head -n 1)"; fi
  if cmp -s "$vstored" "$out.verdict.md"; then K24_VERDICT=$((K24_VERDICT + 1)); echo "     byte-identical to the stored ${vstored#"$EXP/"}"
  else echo "DIFFERS ${vstored#"$EXP/"}"; fi
  echo "COUNT ${tag}_seed${seed}_observations=$(( $(wc -l <"$out") - 1 ))"
}
group_k24() {
  mkdir -p "$OUT/k24" "$WORK/k24"
  local e="$WORK/k24/$K24E" f="$WORK/k24/$K24F/apparatus"
  mkdir -p "$e/oracle" "$f/oracle"
  cp -p "$EXP/$K24E"/{run_campaign.py,generator.py,verdict.py} "$e/"
  cp -p "$EXP/$K24E"/oracle/*.py "$e/oracle/"
  cp -p "$EXP/$K24F/apparatus"/{run_campaign.py,generator.py,verdict.py,decision_rule.py} "$f/"
  cp -p "$EXP/$K24F/apparatus"/oracle/*.py "$f/oracle/"
  K24_RUNS=0 K24_CSV=0 K24_VERDICT=0
  k24_run k24e "$e" "$EXP/$K24E/raw/campaign_seed20260818.csv" 20260818 verdict.py "$EXP/$K24E/VERDICT.md" e2a61ff
  k24_run k24e "$e" "$EXP/$K24E/raw/campaign_seed20260820.csv" 20260820 verdict.py "$EXP/$K24E/VERDICT_oos.md" e2a61ff
  k24_run k24f "$f" "$EXP/$K24F/raw/h10_20260912.csv" 20260912 decision_rule.py "$EXP/$K24F/VERDICT.md" 098e531 --with-window
  k24_run k24f "$f" "$EXP/$K24F/raw/h10_20260913.csv" 20260913 decision_rule.py "$EXP/$K24F/VERDICT_oos.md" 098e531 --with-window
  echo "COUNT k24_csv_identical=$K24_CSV/$K24_RUNS k24_verdicts_identical=$K24_VERDICT/$K24_RUNS"
  [ "$K24_CSV" -eq 4 ] && [ "$K24_VERDICT" -eq 4 ]
}

# --- ecg ----------------------------------------------------------------------
group_ecg() {
  local root="$WORK/ecg" t0
  mkdir -p "$root/examples/ecg/rec205" "$root/examples/ecg/rec205_h10"
  cp -p "$ENG/examples/ecg/rec205"/{rec205,bp_coef.txt,d_coef.txt} "$root/examples/ecg/rec205/"
  cp -p "$ENG/examples/ecg/rec205_h10"/{experiment.sh,rec205-offload.rql} "$root/examples/ecg/rec205_h10/"
  t0="$(date -u +%s)"
  # experiment.sh takes the engine from PATH when its tree has no build directory.
  # shellcheck disable=SC2086
  (cd "$root/examples/ecg/rec205_h10" && PATH="$DEFAULT_BIN:$PATH" bash ./experiment.sh $ECG_SLOTS) \
    >"$OUT/ecg.log" 2>&1 || { tail -n 15 "$OUT/ecg.log"; echo "FAIL  experiment.sh, log $OUT/ecg.log"; return 1; }
  grep -E '^(silnik|PASS|FAIL|WERDYKT)' "$OUT/ecg.log" | sed 's/^/     /'
  echo "     $(( $(date -u +%s) - t0 )) s"
  cp "$root/examples/ecg/rec205_h10/results.tsv" "$OUT/ecg_results.tsv"
  local same
  same="$(LC_ALL=C comm -12 <(tail -n +2 "$OUT/ecg_results.tsv" | sort) <(printf '%s\n' "$ECG_EXPECTED" | tail -n +2 | sort) | wc -l)"
  echo "COUNT ecg_runs_identical=$same/4 tail_deficit=$(tail -n +2 "$OUT/ecg_results.tsv" | cut -f8 | sort -u | paste -sd, -)"
  if [ "$(cat "$OUT/ecg_results.tsv")" = "$ECG_EXPECTED" ]; then
    echo "     identical to the pinned values (examples/ecg/rec205_h10, four runs)"
  else
    echo "DIFFERS ecg results.tsv:"
    diff <(printf '%s\n' "$ECG_EXPECTED") "$OUT/ecg_results.tsv" | sed 's/^/      /' || true
    return 1
  fi
}

# What each group needs from the groups before it.
declare -A NEEDS=([plans]="bundles" [p6]="bundles plans" [gates]="p6" [mechanism]="p6" [k24]="bundles" [ecg]="bundles")
declare -A STATE=()

echo "Engine pin ${PIN:0:12}, bundles rdb-binaries ${BPIN:0:12}, $ARCH, $JOBS jobs"
echo
FAILED=0
for g in bundles plans p6 gates mechanism k24 ecg; do
  echo "=== $g ==="
  missing=""
  for d in ${NEEDS[$g]:-}; do
    [ "${STATE[$d]}" = OK ] || missing="$missing $d"
  done
  if [ -n "$missing" ]; then
    echo "     not run: needs${missing}, which did not pass"
    STATE[$g]=FAIL
    record "$g" FAIL "not run: needs${missing}"
    FAILED=$((FAILED + 1))
    echo
    continue
  fi
  set +e
  ( set -e; "group_$g" )
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    STATE[$g]=OK
    record "$g" OK ""
  else
    STATE[$g]=FAIL
    record "$g" FAIL "see output above"
    FAILED=$((FAILED + 1))
  fi
  echo
done

echo "=== summary ==="
printf '%-9s %-6s %s\n' GROUP STATUS NOTE
while IFS=$'\t' read -r g s n; do printf '%-9s %-6s %s\n' "$g" "$s" "$n"; done <"$STATUS_FILE"
echo
echo "Products: $OUT"
if [ "$FAILED" -gt 0 ]; then
  echo "RESULT: $FAILED group(s) failed"
  exit 1
fi
echo "RESULT: every deterministic quantity remeasured and identical to the stored result"
