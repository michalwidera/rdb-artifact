#!/usr/bin/env bash
# Regenerate INPUTS.tsv: the files the analytic path actually reads, how the
# reviewer mirror serves each of them, and the counts the path must report.
# An author's tool; a reviewer never runs it.
#
#   RDB_REDACTION_TERMS_FILE=<file> bin/make_inputs.sh --workspace DIR
#
# DIR is a clean pinned workspace from bin/checkout.sh (clones, with history).
# The terms file is the list of paper-arXiv/debs/procedura_anonimizacji.md
# section 4, one extended regular expression per line, kept outside every
# repository; the terms identify the author and are never printed.
#
# 1. bin/reproduce_analytic.sh runs over DIR under strace. Every file of the
#    rdb-experiment checkout that a group opens for reading, and every stored
#    product it compares with `git show`, is an input; the provenance gate and
#    git itself are not traced. The run leaves DIR modified (it is disposable).
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
#
# Exit status: 0 - INPUTS.tsv written, 1 - the trial on the simulated mirror
# failed (INPUTS.tsv untouched), 2 - usage or environment.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE=""

usage() { sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
fail() { echo "ERROR: $*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace) [ "$#" -ge 2 ] || fail "--workspace needs a value"; WORKSPACE="$2"; shift 2 ;;
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
EXP="$WORKSPACE/rdb-experiment"
[ -d "$EXP/.git" ] || fail "no rdb-experiment clone in $WORKSPACE"
[ -z "$(git -C "$EXP" status --porcelain)" ] \
  || fail "$EXP has local changes; make a fresh workspace with bin/checkout.sh"
PIN="$(grep -E '^EXPERIMENT_SNAPSHOT="[0-9a-f]{40}"' "$HERE/bin/checkout.sh" | grep -oE '[0-9a-f]{40}')"
[ "$(git -C "$EXP" rev-parse HEAD)" = "$PIN" ] || fail "$EXP is not at the pinned $PIN"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir "$TMP/trace"

echo "== 1. tracing bin/reproduce_analytic.sh over $WORKSPACE"
strace -ff -y -qq -s 4096 -e trace=openat,execve,clone,clone3,vfork,fork -o "$TMP/trace/t" \
  bash "$HERE/bin/reproduce_analytic.sh" --workspace "$WORKSPACE" --out "$TMP/tables" >"$TMP/run.log" 2>&1 \
  || { tail -n 30 "$TMP/run.log" >&2; fail "reproduce_analytic.sh failed under strace"; }
tail -n 1 "$TMP/run.log" | sed 's/^/   /'

echo "== 2. classifying the inputs"
python3 -I - "$TMP/trace" "$EXP" "$PIN" "$RDB_REDACTION_TERMS_FILE" "$TMP/run.log" "$HERE/MANIFEST.md" \
  "$TMP/INPUTS.tsv" "$TMP/mirror" <<'PY'
import glob, gzip, hashlib, os, re, subprocess, sys

tdir, exp, pin, terms_file, run_log, manifest, out, mirror_dir = sys.argv[1:9]
LIMIT = 1200000
MARKER = b"XXXX"
terms = [l.rstrip("\n") for l in open(terms_file, encoding="utf-8") if l.strip() and not l.startswith("#")]
# As the anonymizer matches: on word boundaries, ignoring case, ASCII word characters.
term_re = re.compile(rb"\b(?:" + b"|".join(t.encode() for t in terms) + rb")\b", re.I)
link_re = re.compile(rb"https?://\S+")

def git(*args):
    return subprocess.run(["git", "-C", exp, *args], capture_output=True, check=True).stdout

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

paths = set()
prefix = os.path.realpath(exp) + "/"
for pid, lines in procs.items():
    for l in lines:
        if l.startswith('execve("') and l.rstrip().endswith("= 0") and '"show"' in l:
            paths.update(re.findall(r'"HEAD:([^"]+)"', l))  # stored products
        if pid in excluded:
            continue
        m = re.match(r'openat\([^,]*, "[^"]*", ([A-Z_|]+)(?:, \d+)?\)\s+=\s+\d+<([^>]*)>', l)
        if not m or not m.group(2).startswith(prefix) or "O_DIRECTORY" in m.group(1):
            continue
        if re.search(r"O_WRONLY|O_RDWR|O_CREAT|O_TRUNC", m.group(1)):
            continue
        rel = m.group(2)[len(prefix):]
        if "/__pycache__/" not in rel:  # Python rebuilds bytecode from the source
            paths.add(rel)
tracked = set(git("ls-tree", "-r", "--name-only", "HEAD").decode().splitlines())
untracked = sorted(p for p in paths if p not in tracked)
if untracked:
    sys.exit("ERROR: inputs not tracked at the pin: " + ", ".join(untracked))

# 2. Classification, and the simulated mirror beside it.
mid = None
for line in open(manifest, encoding="utf-8"):
    m = re.match(r"^\| `rdb-experiment` \| [^|]* \| `[0-9a-f]{40}` \| [^|]* \| `([^`]+)` \|", line)
    if m:
        mid = m.group(1)
        break
if not mid:
    sys.exit("ERROR: MANIFEST.md names no reviewer mirror for rdb-experiment")

def place(path, data):
    target = os.path.join(mirror_dir, mid, path)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, "wb") as f:
        f.write(data)

rows, counts, total = [], {"exact": 0, "gz": 0, "masked": 0}, 0
for path in sorted(paths):
    blob = git("cat-file", "blob", f"HEAD:{path}")
    sha = hashlib.sha256(blob).hexdigest()
    text = b"\0" not in blob
    lines = blob.split(b"\n")
    hit = text and any(term_re.search(l) or link_re.search(l) for l in lines)
    if text and len(blob) >= LIMIT:
        if f"{path}.gz" not in tracked:
            sys.exit(f"ERROR: {path} has {len(blob)} bytes and no {path}.gz at the pin; the mirror refuses it")
        gz = git("cat-file", "blob", f"HEAD:{path}.gz")
        if gzip.decompress(gz) != blob:
            sys.exit(f"ERROR: {path}.gz at the pin does not decompress to {path}")
        if hit:
            sys.exit(f"ERROR: {path} is served only as .gz, which the mirror does not redact, and it matches a term")
        method, check = "gz", hashlib.sha256(gz).hexdigest()
        place(path + ".gz", gz)
    elif hit:
        kept = b"".join(l + b"\n" for l in lines
                        if not (term_re.search(l) or link_re.search(l) or MARKER in l))
        method, check = "masked", f"{len(lines)}:{hashlib.sha256(kept).hexdigest()}"
        place(path, link_re.sub(MARKER, term_re.sub(MARKER, blob)))
    else:
        method, check = "exact", "-"
        place(path, blob)
    counts[method] += 1
    total += len(blob)
    rows.append(f"rdb-experiment\t{path}\t{len(blob)}\t{sha}\t{method}\t{check}")

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
    f.write("# INPUTS.tsv - the inputs of the analytic path and what it must report.\n")
    f.write("# Generated by bin/make_inputs.sh; do not edit by hand. Read by bin/fetch_mirror.sh,\n")
    f.write("# bin/reproduce_analytic.sh --snapshot and bin/review.sh.\n")
    f.write(f"# pin rdb-experiment {pin}\n")
    f.write("\n".join(expect) + "\n")
    f.write("repo\tpath\tbytes\tsha256\tmethod\tcheck\n")
    f.write("\n".join(rows) + "\n")
detail = ", ".join(f"{k} {v}" for k, v in counts.items())
print(f"   {len(rows)} inputs ({detail}), {total} bytes at the pin; {len(expect)} expected COUNT lines")
PY

echo "== 3. bin/review.sh on a simulated mirror with the new list"
if RDB_INPUTS="$TMP/INPUTS.tsv" bash "$HERE/bin/review.sh" --source "$TMP/mirror" \
     --dest "$TMP/review" --report "$TMP/review-report.md" >"$TMP/review.log" 2>&1; then
  grep -E '^(INPUTS|VERDICT)' "$TMP/review.log" | sed 's/^/   /'
else
  tail -n 40 "$TMP/review.log" >&2
  echo "RESULT: the new list fails on the simulated mirror; INPUTS.tsv left as it was"
  exit 1
fi

cp "$TMP/INPUTS.tsv" "$HERE/INPUTS.tsv"
echo "RESULT: INPUTS.tsv written for rdb-experiment $PIN"
