#!/usr/bin/env bash
# Fetch the inputs of the analytic path from the reviewer mirrors, one file at a
# time, and verify every file against INPUTS.tsv. No git, no account, no listing
# of directories: the list says which files to ask for, and each answer is
# checked before it is kept.
#
#   bash bin/fetch_mirror.sh [--dest DIR]          # fetch what is missing, verify all
#   bash bin/fetch_mirror.sh --check [--dest DIR]  # verify DIR only, no network
#
# Options:
#   --dest DIR     workspace to fill; a file lands at DIR/<repository>/<path>
#                  (default: ./review-workspace)
#   --source DIR   read DIR/<mirror-id>/<path> from a local directory instead of
#                  the mirror service; used by bin/make_inputs.sh and by the
#                  controlled-failure checks, never needed by a reviewer
#   -h, --help     this text
#
# Every entry of INPUTS.tsv names one of three checks:
#   exact   the served bytes have the SHA-256 of the blob at the pin;
#   gz      the file is a text of 1.2 MB or more, which the mirror refuses
#           (HTTP 502); its <path>.gz is fetched instead, must have the SHA-256
#           of the .gz blob, and must decompress to the SHA-256 of the blob;
#   masked  the blob at the pin carries identifying terms or links, which the
#           mirror rewrites to XXXX; the served file must have the same number
#           of lines, and the lines without XXXX must have the declared SHA-256.
#           Only the redacted lines escape the check, and bin/make_inputs.sh
#           verified that the regenerated products do not depend on them.
#
# The mirror service allows about 175 requests per 15 minutes from one address
# and says so in its ratelimit-* headers; the script paces itself by them and
# waits out HTTP 429 for its Retry-After. An interrupted run resumes: files
# already in DIR that verify are not fetched again.
#
# RDB_INPUTS names another list than INPUTS.tsv; bin/make_inputs.sh uses it to
# try a new list before it replaces the old one.
#
# Exit status: 0 - every input verified, 1 - at least one input failed (named,
# with the reason: missing, truncated, redacted, differs, http-<code>),
# 2 - usage or environment.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="./review-workspace"
INPUTS="${RDB_INPUTS:-$HERE/INPUTS.tsv}"
SOURCE=""
CHECK=no

usage() { sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
fail() { echo "ERROR: $*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dest)   [ "$#" -ge 2 ] || fail "--dest needs a value";   DEST="$2";   shift 2 ;;
    --source) [ "$#" -ge 2 ] || fail "--source needs a value"; SOURCE="$2"; shift 2 ;;
    --check)  CHECK=yes; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

command -v python3 >/dev/null || fail "python3 not found"
[ -r "$INPUTS" ] || fail "cannot read $INPUTS"
mkdir -p "$DEST"

exec python3 -I - "$INPUTS" "$HERE/MANIFEST.md" "$DEST" "$SOURCE" "$CHECK" <<'PY'
import gzip, hashlib, http.client, os, re, sys, time, urllib.error, urllib.parse, urllib.request, zlib

inputs, manifest, dest, source, check_only = sys.argv[1:6]
check_only = check_only == "yes"
# Assembled at run time: the mirror rewrites every link in the text it serves,
# this script included, to XXXX. A host name without a scheme survives.
BASE = "https:" + "//" + "anonymous.4open.science" + "/api/repo"
MARKER = b"XXXX"

def die(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(2)

# Mirror IDs and pins from MANIFEST.md section 1. Rows are found by the
# repository name, which stays off the redaction list (REVIEW_MIRROR.md).
ROW = re.compile(r"^\| `([^`]+)` \| [^|]* \| `([0-9a-f]{40})` \| [^|]* \| `([^`]+)` \|")
mirror, pin = {}, {}
for line in open(manifest, encoding="utf-8"):
    m = ROW.match(line)
    if m and m.group(1) not in pin:
        pin[m.group(1)], mirror[m.group(1)] = m.group(2), m.group(3)

rows, declared = [], {}
for line in open(inputs, encoding="utf-8"):
    line = line.rstrip("\n")
    if line.startswith("# pin "):
        _, _, repo, sha = line.split()
        declared[repo] = sha
        continue
    if not line or line.startswith("#") or line.startswith("repo\t"):
        continue
    repo, path, size, sha, method, check = line.split("\t")
    rows.append((repo, path, int(size), sha, method, check))
if not rows:
    die(f"{inputs} lists no inputs")
for repo, sha in declared.items():
    if pin.get(repo) != sha:
        die(f"{os.path.basename(inputs)} was generated for {repo} {sha[:12]}, "
            f"but MANIFEST.md pins {(pin.get(repo) or 'nothing')[:12]}; regenerate it with bin/make_inputs.sh")
for repo in {r[0] for r in rows}:
    if repo not in declared:
        die(f"{os.path.basename(inputs)} declares no pin for {repo}")
    if not mirror.get(repo):
        die(f"MANIFEST.md names no reviewer mirror for {repo}")

def masked(data):
    lines = data.split(b"\n")
    kept = b"".join(l + b"\n" for l in lines if MARKER not in l)
    return f"{len(lines)}:{hashlib.sha256(kept).hexdigest()}"

def verify(row, data):
    """Return None when the kept file matches its entry, else the reason."""
    _, _, size, sha, method, check = row
    if method == "masked":
        got = masked(data)
        if got == check:
            return None
        want_lines = int(check.split(":")[0])
        got_lines = int(got.split(":")[0])
        return "truncated" if got_lines < want_lines else "differs"
    if hashlib.sha256(data).hexdigest() == sha:
        return None
    if len(data) < size:
        return "truncated"
    return "redacted" if MARKER in data else "differs"

stats = {"requests": 0, "r429": 0, "bytes": 0, "fetched": 0}

def get(mid, path):
    """Return (status, body) of one file from the mirror or from --source."""
    if source:
        local = os.path.join(source, mid, path)
        if not os.path.isfile(local):
            return 404, b""
        with open(local, "rb") as f:
            return 200, f.read()
    url = f"{BASE}/{mid}/file/{urllib.parse.quote(path)}"
    errors = 0
    while True:
        stats["requests"] += 1
        req = urllib.request.Request(url, headers={"User-Agent": "rdb-artifact-fetch/1", "Accept": "*/*"})
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                body = r.read()
                remaining = r.headers.get("ratelimit-remaining")
                reset = r.headers.get("ratelimit-reset")
                if remaining is not None and reset is not None and int(remaining) <= 1:
                    wait = int(reset) + 2
                    print(f"     request budget spent; waiting {wait} s for the window to reset", flush=True)
                    time.sleep(wait)
                else:
                    time.sleep(1)
                return r.status, body
        except urllib.error.HTTPError as e:
            if e.code == 429:
                stats["r429"] += 1
                wait = int(e.headers.get("Retry-After") or 600) + 5
                print(f"     HTTP 429; waiting {wait} s (Retry-After)", flush=True)
                time.sleep(wait)
                continue
            return e.code, e.read()
        except (urllib.error.URLError, http.client.HTTPException, TimeoutError, ConnectionError) as e:
            errors += 1
            if errors > 5:
                return 0, str(e).encode()
            print(f"     network error ({e}); retrying in 30 s", flush=True)
            time.sleep(30)

def fetch(row):
    """Fetch one entry; return (data, reason)."""
    repo, path, size, sha, method, check = row
    mid = mirror[repo]
    if method == "gz":
        status, body = get(mid, path + ".gz")
        if status != 200:
            return None, "missing" if status == 404 else f"http-{status}"
        stats["bytes"] += len(body)
        try:
            data = gzip.decompress(body)
        except EOFError:
            return None, "truncated"
        except (OSError, zlib.error):
            return None, "differs"
        if hashlib.sha256(body).hexdigest() != check:
            return None, "differs"
        return data, None
    status, body = get(mid, path)
    if status != 200:
        return None, "missing" if status == 404 else f"http-{status}"
    stats["bytes"] += len(body)
    return body, None

counts = {"exact": 0, "gz": 0, "masked": 0}
failed = []
for row in rows:
    repo, path, size, sha, method, check = row
    target = os.path.join(dest, repo, path)
    reason = "missing"
    if os.path.isfile(target):
        with open(target, "rb") as f:
            reason = verify(row, f.read())
    if reason is not None and not check_only:
        data, reason = fetch(row)
        if data is not None:
            stats["fetched"] += 1
            reason = verify(row, data)
            os.makedirs(os.path.dirname(target), exist_ok=True)
            keep = target if reason is None else target + ".rejected"
            with open(keep + ".part", "wb") as f:
                f.write(data)
            os.replace(keep + ".part", keep)
    if reason is None:
        counts[method] += 1
    else:
        failed.append((repo, path, reason))
        print(f"FAIL  {repo}/{path}: {reason}", flush=True)

total = len(rows)
good = total - len(failed)
detail = ", ".join(f"{k} {v}" for k, v in counts.items())
if not check_only:
    where = f"from {source}" if source else "from the mirror service"
    print(f"FETCH {stats['fetched']} file(s) {where}, {stats['bytes']} bytes, "
          f"{stats['requests']} request(s), {stats['r429']} HTTP 429")
print(f"INPUTS {good} of {total} match INPUTS.tsv ({detail})")
sys.exit(1 if failed else 0)
PY
