#!/usr/bin/env bash
# Regenerate INPUTS.tsv: the files the analytic path actually reads, how the
# reviewer mirror serves each of them, and the counts the path must report.
# With --remeasure, the same for REMEASURE.tsv and bin/reproduce_remeasure.sh.
# An author's tool; a reviewer never runs it.
#
#   RDB_REDACTION_TERMS_FILE=<file> bin/make_inputs.sh --workspace DIR [--remeasure] [--keep DIR2]
#
# DIR is a clean pinned workspace from bin/checkout.sh (clones, with history);
# for --remeasure it also holds a clone of rdb-binaries at its MANIFEST.md pin.
# The terms file is the list of paper-arXiv/debs/procedura_anonimizacji.md
# section 4, one extended regular expression per line, kept outside every
# repository; the terms identify the author and are never printed.
#
# 1. bin/reproduce_analytic.sh runs over DIR under strace. Every file of the
#    rdb-experiment checkout that a group opens for reading, and every stored
#    product it compares with `git show`, is an input; the provenance gate and
#    git itself are not traced. The run leaves DIR modified (it is disposable).
#    With --remeasure, bin/reproduce_remeasure.sh runs instead and every file of
#    the retractordb, rdb-experiment and rdb-binaries clones it reads is an input.
# 2. Each input gets the size and SHA-256 of its blob at the pin and one check
#    (see bin/fetch_mirror.sh): gz for a text of 1.2 MB or more, which must
#    have a <path>.gz copy at the pin; masked for a text with a line matching a
#    term or a link, which the mirror rewrites; exact for everything else.
# 3. The COUNT lines of the run become "# expect" lines: bin/review.sh requires
#    the mirror path to report the same.
# 4. The new list is tried before it replaces INPUTS.tsv: a simulated mirror is
#    built from the pin (terms and links rewritten to XXXX, large texts as .gz
#    only, nothing that is not listed), and bin/review.sh must pass on it with
#    the new list. A masked input whose redaction changed a product fails here.
#    With --remeasure that trial runs with a PATH without git, a compiler or
#    cmake, so it also shows that the path needs none of them. --keep DIR2
#    keeps the trial's report, log and list, and the simulated mirror.
#
# Exit status: 0 - INPUTS.tsv written, 1 - the trial on the simulated mirror
# failed (INPUTS.tsv untouched), 2 - usage or environment.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE=""
REMEASURE=no
KEEP=""

usage() { sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
fail() { echo "ERROR: $*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace) [ "$#" -ge 2 ] || fail "--workspace needs a value"; WORKSPACE="$2"; shift 2 ;;
    --remeasure) REMEASURE=yes; shift ;;
    --keep)      [ "$#" -ge 2 ] || fail "--keep needs a value";      KEEP="$2";      shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

[ -n "$WORKSPACE" ] || { usage >&2; fail "--workspace is required"; }
[ -n "${RDB_REDACTION_TERMS_FILE:-}" ] || fail "RDB_REDACTION_TERMS_FILE is not set"
[ -r "$RDB_REDACTION_TERMS_FILE" ] || fail "cannot read $RDB_REDACTION_TERMS_FILE"
command -v strace >/dev/null || fail "strace not found"
command -v python3 >/dev/null || fail "python3 not found"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"
# The repositories whose files are inputs, each "name=clone=pin".
pin_of() { grep -E "^$1=\"[0-9a-f]{40}\"" "$HERE/bin/checkout.sh" | grep -oE '[0-9a-f]{40}'; }
REPOS=("rdb-experiment=$WORKSPACE/rdb-experiment=$(pin_of EXPERIMENT_SNAPSHOT)")
if [ "$REMEASURE" = yes ]; then
  BPIN="$(sed -nE 's/^\| `rdb-binaries` \| [^|]* \| `([0-9a-f]{40})` \|.*/\1/p' "$HERE/MANIFEST.md" | head -n 1)"
  REPOS+=("retractordb=$WORKSPACE/retractordb=$(pin_of ENGINE_SNAPSHOT)" "rdb-binaries=$WORKSPACE/rdb-binaries=$BPIN")
  RUNNER="$HERE/bin/reproduce_remeasure.sh"
  TARGET="REMEASURE.tsv"
else
  RUNNER="$HERE/bin/reproduce_analytic.sh"
  TARGET="INPUTS.tsv"
fi
for r in "${REPOS[@]}"; do
  IFS='=' read -r name clone pin <<<"$r"
  [ -n "$pin" ] || fail "no pin for $name"
  [ -d "$clone/.git" ] || fail "no $name clone in $WORKSPACE"
  [ -z "$(git -C "$clone" status --porcelain)" ] \
    || fail "$clone has local changes; make a fresh workspace with bin/checkout.sh"
  [ "$(git -C "$clone" rev-parse HEAD)" = "$pin" ] || fail "$clone is not at the pinned $pin"
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir "$TMP/trace"

echo "== 1. tracing bin/$(basename "$RUNNER") over $WORKSPACE"
strace -ff -y -qq -s 4096 -e trace=openat,execve,clone,clone3,vfork,fork -o "$TMP/trace/t" \
  bash "$RUNNER" --workspace "$WORKSPACE" --out "$TMP/tables" >"$TMP/run.log" 2>&1 \
  || { tail -n 30 "$TMP/run.log" >&2; fail "$(basename "$RUNNER") failed under strace"; }
tail -n 1 "$TMP/run.log" | sed 's/^/   /'

echo "== 2. classifying the inputs"
python3 -I - "$TMP/trace" "$RDB_REDACTION_TERMS_FILE" "$TMP/run.log" "$HERE/MANIFEST.md" \
  "$TMP/$TARGET" "$TMP/mirror" "$REMEASURE" "${REPOS[@]}" <<'PY'
import glob, gzip, hashlib, os, re, subprocess, sys

tdir, terms_file, run_log, manifest, out, mirror_dir, remeasure = sys.argv[1:8]
repos = [r.split("=", 2) for r in sys.argv[8:]]  # name, clone, pin
LIMIT = 1200000
MARKER = b"XXXX"
terms = [l.rstrip("\n") for l in open(terms_file, encoding="utf-8") if l.strip() and not l.startswith("#")]
# As the anonymizer matches: on word boundaries, ignoring case, ASCII word characters.
term_re = re.compile(rb"\b(?:" + b"|".join(t.encode() for t in terms) + rb")\b", re.I)
link_re = re.compile(rb"https?://\S+")

def git(clone, *args):
    return subprocess.run(["git", "-C", clone, *args], capture_output=True, check=True).stdout

# 1. Processes: each strace file is one process. Git and the provenance gate,
#    with everything they start, are not the analysis.
procs = {}
for f in glob.glob(os.path.join(tdir, "t.*")):
    procs[int(f.rsplit(".", 1)[1])] = open(f, encoding="utf-8", errors="replace").read().splitlines()
children, roots = {}, set()
for pid, lines in procs.items():
    for l in lines:
        m = re.match(r"(?:clone3?|vfork|fork)\(.*\)\s+=\s+(\d+)", l)
        if m:
            children.setdefault(pid, []).append(int(m.group(1)))
        m = re.match(r'execve\("([^"]*)"', l)
        if m and l.rstrip().endswith("= 0") and (m.group(1).endswith("/git") or "verify_pins.sh" in l):
            roots.add(pid)
excluded = set()
def exclude(p):
    excluded.add(p)
    for c in children.get(p, []):
        exclude(c)
for p in roots:
    exclude(p)

paths = set()  # (repository, path)
prefixes = [(name, os.path.realpath(clone) + "/") for name, clone, _ in repos]
for pid, lines in procs.items():
    for l in lines:
        if l.startswith('execve("') and l.rstrip().endswith("= 0") and '"show"' in l:
            paths.update(("rdb-experiment", p) for p in re.findall(r'"HEAD:([^"]+)"', l))  # stored products
        if pid in excluded:
            continue
        m = re.match(r'openat\([^,]*, "[^"]*", ([A-Z_|]+)(?:, \d+)?\)\s+=\s+\d+<([^>]*)>', l)
        if not m or "O_DIRECTORY" in m.group(1):
            continue
        if re.search(r"O_WRONLY|O_RDWR|O_CREAT|O_TRUNC", m.group(1)):
            continue
        for name, prefix in prefixes:
            if m.group(2).startswith(prefix):
                rel = m.group(2)[len(prefix):]
                if "/__pycache__/" not in rel and not rel.startswith(".git/"):  # bytecode is rebuilt
                    paths.add((name, rel))
clone_of = {name: clone for name, clone, _ in repos}
tracked = {name: set(git(clone, "ls-tree", "-r", "--name-only", "HEAD").decode().splitlines())
           for name, clone, _ in repos}
if remeasure == "yes":
    # The traced run reads the bundles of this machine's architecture only; the
    # list carries every bundle of the engine pin, so that it serves both.
    engine_pin = [pin for name, _, pin in repos if name == "retractordb"][0]
    paths.update(("rdb-binaries", p) for p in tracked["rdb-binaries"]
                 if p.startswith(engine_pin + "/") and p.endswith(".tar.gz"))
untracked = sorted(f"{r}/{p}" for r, p in paths if p not in tracked[r])
if untracked:
    sys.exit("ERROR: inputs not tracked at the pin: " + ", ".join(untracked))

# 2. Classification, and the simulated mirror beside it.
mids = {}
for line in open(manifest, encoding="utf-8"):
    m = re.match(r"^\| `([^`]+)` \| [^|]* \| `[0-9a-f]{40}` \| [^|]* \| `([^`]+)` \|", line)
    if m and m.group(1) not in mids:
        mids[m.group(1)] = m.group(2)
for name, _, _ in repos:
    if name not in mids:
        sys.exit(f"ERROR: MANIFEST.md names no reviewer mirror for {name}")

def place(repo, path, data):
    target = os.path.join(mirror_dir, mids[repo], path)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, "wb") as f:
        f.write(data)

rows, counts, total = [], {"exact": 0, "gz": 0, "masked": 0}, 0
for repo, path in sorted(paths):
    blob = git(clone_of[repo], "cat-file", "blob", f"HEAD:{path}")
    sha = hashlib.sha256(blob).hexdigest()
    text = b"\0" not in blob
    lines = blob.split(b"\n")
    hit = text and any(term_re.search(l) or link_re.search(l) for l in lines)
    if text and len(blob) >= LIMIT:
        if f"{path}.gz" not in tracked[repo]:
            sys.exit(f"ERROR: {path} has {len(blob)} bytes and no {path}.gz at the pin; the mirror refuses it")
        gz = git(clone_of[repo], "cat-file", "blob", f"HEAD:{path}.gz")
        if gzip.decompress(gz) != blob:
            sys.exit(f"ERROR: {path}.gz at the pin does not decompress to {path}")
        if hit:
            sys.exit(f"ERROR: {path} is served only as .gz, which the mirror does not redact, and it matches a term")
        method, check = "gz", hashlib.sha256(gz).hexdigest()
        place(repo, path + ".gz", gz)
    elif hit:
        kept = b"".join(l + b"\n" for l in lines
                        if not (term_re.search(l) or link_re.search(l) or MARKER in l))
        method, check = "masked", f"{len(lines)}:{hashlib.sha256(kept).hexdigest()}"
        place(repo, path, link_re.sub(MARKER, term_re.sub(MARKER, blob)))
    else:
        method, check = "exact", "-"
        place(repo, path, blob)
    counts[method] += 1
    total += len(blob)
    rows.append(f"{repo}\t{path}\t{len(blob)}\t{sha}\t{method}\t{check}")

# 3. Expected counts, from the traced run.
expect, group = [], None
for line in open(run_log, encoding="utf-8"):
    m = re.match(r"^=== (\w+) ===$", line)
    if m:
        group = m.group(1)
    elif line.startswith("COUNT ") and group:
        expect.append(f"# expect {group} {line.rstrip()}")
if not expect:
    sys.exit("ERROR: the traced run reported no COUNT lines")

with open(out, "w", encoding="utf-8") as f:
    if remeasure == "yes":
        f.write("# REMEASURE.tsv - the inputs of the remeasure path and what it must report.\n")
        f.write("# Generated by bin/make_inputs.sh --remeasure; do not edit by hand. Read by\n")
        f.write("# bin/fetch_mirror.sh and bin/review.sh --remeasure.\n")
    else:
        f.write("# INPUTS.tsv - the inputs of the analytic path and what it must report.\n")
        f.write("# Generated by bin/make_inputs.sh; do not edit by hand. Read by bin/fetch_mirror.sh,\n")
        f.write("# bin/reproduce_analytic.sh --snapshot and bin/review.sh.\n")
    for name, _, pin in repos:
        f.write(f"# pin {name} {pin}\n")
    f.write("\n".join(expect) + "\n")
    f.write("repo\tpath\tbytes\tsha256\tmethod\tcheck\n")
    f.write("\n".join(rows) + "\n")
detail = ", ".join(f"{k} {v}" for k, v in counts.items())
print(f"   {len(rows)} inputs ({detail}), {total} bytes at the pin; {len(expect)} expected COUNT lines")
PY

echo "== 3. bin/review.sh on a simulated mirror with the new list"
TRIAL_PATH="$PATH"
TRIAL_OPTS=()
if [ "$REMEASURE" = yes ]; then
  # Every program on PATH except git, compilers and build tools.
  TRIAL_OPTS=(--remeasure)
  mkdir "$TMP/path"
  IFS=: read -ra dirs <<<"$PATH"
  for d in "${dirs[@]}"; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      b="$(basename "$f")"
      case "$b" in
        git|git-*|cc|c++|cpp|gcc|g++|gcc-*|g++-*|*-gcc|*-g++|*-gcc-*|*-g++-*|clang|clang++|clang-*) continue ;;
        cmake|ctest|cpack|ccmake|ninja|make|conan) continue ;;
      esac
      [ -f "$f" ] && [ -x "$f" ] && [ ! -e "$TMP/path/$b" ] && ln -s "$f" "$TMP/path/$b"
    done
  done
  for t in git cc gcc g++ cmake; do
    ! PATH="$TMP/path" command -v "$t" >/dev/null || fail "$t is still reachable on the trial PATH"
  done
  TRIAL_PATH="$TMP/path"
  echo "   PATH without git, cc, gcc, g++ or cmake"
fi
if PATH="$TRIAL_PATH" RDB_INPUTS="$TMP/$TARGET" bash "$HERE/bin/review.sh" "${TRIAL_OPTS[@]}" \
     --source "$TMP/mirror" --dest "$TMP/review" --report "$TMP/review-report.md" >"$TMP/review.log" 2>&1; then
  grep -E '^(INPUTS|FETCH|VERDICT)' "$TMP/review.log" | sed 's/^/   /'
  [ -z "$KEEP" ] || { mkdir -p "$KEEP" && cp -r "$TMP/review-report.md" "$TMP/review.log" "$TMP/$TARGET" "$TMP/mirror" "$KEEP/"; }
else
  tail -n 40 "$TMP/review.log" >&2
  [ -z "$KEEP" ] || { mkdir -p "$KEEP" && cp "$TMP/review-report.md" "$TMP/review.log" "$TMP/$TARGET" "$KEEP/" 2>/dev/null || true; }
  echo "RESULT: the new list fails on the simulated mirror; $TARGET left as it was"
  exit 1
fi

cp "$TMP/$TARGET" "$HERE/$TARGET"
echo "RESULT: $TARGET written for ${REPOS[*]##*=}"
