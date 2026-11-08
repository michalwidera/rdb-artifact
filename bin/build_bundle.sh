#!/usr/bin/env bash
# Build the prebuilt engine bundles that bin/review.sh --remeasure downloads:
# one .tar.gz per measurement profile and architecture, each with xretractor,
# xqry and xtrdb built in Release with RDB_BENCH_PROBE from the pinned engine.
#
#   bash bin/build_bundle.sh --arch x86_64|aarch64 [options]
#
# Options:
#   --arch ARCH       x86_64 or aarch64 (required)
#   --workspace DIR   pinned clones made by bin/checkout.sh (default:
#                     ./artifact-workspace); the engine is DIR/retractordb and the
#                     profiles DIR/rdb-experiment/<campaign>/profiles.tsv
#   --engine DIR      engine clone in place of DIR/retractordb
#   --profiles FILE   profile table in place of the workspace one
#   --out DIR         where the archives go (default: ./bundles/<engine SHA>)
#   --cache DIR       Conan cache kept between runs (default: ./bundle-cache/<arch>)
#   --logs DIR        build logs, kept out of --out (default: ./bundle-logs/<arch>)
#   --jobs N          parallel compile jobs in the container (default: 4)
#   --terms FILE      identifying terms, one extended regular expression per line
#                     (as for bin/make_inputs.sh): no binary may contain one on a
#                     word boundary, because the mirror serves binaries unredacted
#   -h, --help        this text
#
# Needs git, docker (able to run linux/arm64 containers for --arch aarch64, e.g.
# through qemu binfmt) and python3. Nothing is built with the host toolchain:
# the build runs in the image of packaging/portable/Dockerfile of the pinned
# engine, the image the release packages are built in, so the bundle depends on
# the glibc and libstdc++ of that image (Debian trixie), not of this host.
# Release packaging itself (scripts/release_package) is not used: it fixes the
# production switches and RDB_BENCH_PROBE=OFF.
#
# The RDB_OPT_* switches are compile definitions of the retractor target only,
# so xqry and xtrdb are built once, in the DEFAULT profile, and the same two
# files go into every bundle of the architecture.
#
# A bundle is accepted only when xretractor --build-info equals the profile row
# byte for byte and every binary is an ELF of the requested machine. The archive
# is packed deterministically (sorted names, mtime of the engine commit, owner 0,
# gzip without a name or time), so the same binaries give the same archive.
#
# Do not run it next to bin/reproduce_remeasure.sh: the docker command line
# names xretractor, and run_main_rdb.sh of the H9 apparatus refuses to start
# while any command line on the machine does.
#
# Exit status: 0 - every bundle built and checked, 1 - a check failed,
# 2 - usage or environment.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CAMPAIGN_DIR="results_20261103_R593_H9"
ARCH=""
WORKSPACE="./artifact-workspace"
ENGINE=""
PROFILES=""
OUT=""
CACHE=""
LOGDIR=""
JOBS=4
TERMS=""

usage() { sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
fail() { echo "ERROR: $*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --arch)      [ "$#" -ge 2 ] || fail "--arch needs a value";      ARCH="$2";      shift 2 ;;
    --workspace) [ "$#" -ge 2 ] || fail "--workspace needs a value"; WORKSPACE="$2"; shift 2 ;;
    --engine)    [ "$#" -ge 2 ] || fail "--engine needs a value";    ENGINE="$2";    shift 2 ;;
    --profiles)  [ "$#" -ge 2 ] || fail "--profiles needs a value";  PROFILES="$2";  shift 2 ;;
    --out)       [ "$#" -ge 2 ] || fail "--out needs a value";       OUT="$2";       shift 2 ;;
    --cache)     [ "$#" -ge 2 ] || fail "--cache needs a value";     CACHE="$2";     shift 2 ;;
    --logs)      [ "$#" -ge 2 ] || fail "--logs needs a value";      LOGDIR="$2";    shift 2 ;;
    --jobs)      [ "$#" -ge 2 ] || fail "--jobs needs a value";      JOBS="$2";      shift 2 ;;
    --terms)     [ "$#" -ge 2 ] || fail "--terms needs a value";     TERMS="$2";     shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

case "$ARCH" in
  x86_64)  PLATFORM=linux/amd64 ELF_MACHINE=62 ;;
  aarch64) PLATFORM=linux/arm64 ELF_MACHINE=183 ;;
  *) fail "--arch must be x86_64 or aarch64" ;;
esac
[[ "$JOBS" =~ ^[1-9][0-9]*$ ]] || fail "--jobs must be a positive integer"
for t in git docker python3 tar gzip sha256sum; do
  command -v "$t" >/dev/null || fail "$t not found on PATH"
done
[ -z "$TERMS" ] || [ -r "$TERMS" ] || fail "cannot read --terms $TERMS"

ENGINE="${ENGINE:-$WORKSPACE/retractordb}"
PROFILES="${PROFILES:-$WORKSPACE/rdb-experiment/$CAMPAIGN_DIR/profiles.tsv}"
[ -d "$ENGINE/.git" ] || fail "not a git clone: $ENGINE (run bin/checkout.sh or pass --engine)"
[ -r "$PROFILES" ] || fail "cannot read the profile table $PROFILES"
ENGINE="$(cd "$ENGINE" && pwd)"

# The engine must be the pin of MANIFEST.md section 1, with nothing changed.
PIN="$(sed -nE 's/^\| `retractordb` \| [^|]* \| `([0-9a-f]{40})` \|.*/\1/p' "$HERE/MANIFEST.md" | head -n 1)"
[ -n "$PIN" ] || fail "no retractordb pin in MANIFEST.md section 1"
HEAD_SHA="$(git -C "$ENGINE" rev-parse HEAD)"
[ "$HEAD_SHA" = "$PIN" ] || fail "engine at $HEAD_SHA, MANIFEST.md pins $PIN"
[ -z "$(git -C "$ENGINE" status --porcelain --untracked-files=no)" ] \
  || fail "engine clone has changes to tracked files"
COMMIT_EPOCH="$(git -C "$ENGINE" log -1 --format=%ct HEAD)"
SHORT="${PIN:0:12}"

# Profile rows: profile, slug, dedup, share, commutative, factor (header first).
mapfile -t ROWS < <(awk -F'\t' 'NR > 1 && NF == 6' "$PROFILES")
[ "${#ROWS[@]}" -ge 1 ] || fail "no profile rows in $PROFILES"
printf '%s\n' "${ROWS[@]}" | cut -f2 | grep -qx DEFAULT || fail "no DEFAULT profile in $PROFILES"
printf '%s\n' "${ROWS[@]}" | awk -F'\t' '
  $2 !~ /^[A-Z0-9_]+$/ { bad = 1 }
  { for (i = 3; i <= 6; i++) if ($i != "ON" && $i != "OFF") bad = 1 }
  END { exit bad }' || fail "malformed profile row in $PROFILES"

OUT="${OUT:-./bundles/$PIN}"
CACHE="${CACHE:-./bundle-cache/$ARCH}"
mkdir -p "$OUT" "$CACHE"
OUT="$(cd "$OUT" && pwd)"
CACHE="$(cd "$CACHE" && pwd)"
STAGE="$(mktemp -d "$OUT/.stage-$ARCH.XXXXXX")"
trap 'rm -rf -- "$STAGE"' EXIT
LOGDIR="${LOGDIR:-./bundle-logs/$ARCH}"
mkdir -p "$LOGDIR"
LOGDIR="$(cd "$LOGDIR" && pwd)"

echo "=== image ($PLATFORM) ==="
IMAGE="rdb-bundle-$ARCH:$SHORT"
docker build --platform "$PLATFORM" -t "$IMAGE" \
  -f "$ENGINE/packaging/portable/Dockerfile" "$ENGINE/packaging/portable" >"$LOGDIR/docker-build.log" 2>&1 \
  || { tail -n 20 "$LOGDIR/docker-build.log" >&2; fail "docker build failed"; }
IMAGE_ID="$(docker image inspect --format '{{.Id}}' "$IMAGE")"
BASE_DIGEST="$(docker image inspect --format '{{join .RepoDigests " "}}' debian:trixie-slim 2>/dev/null || true)"
echo "OK    $IMAGE $IMAGE_ID"

echo "=== build in the container ==="
cp "$PROFILES" "$STAGE/profiles.tsv"
mkdir -p "$STAGE/out"
set +e
docker run --rm --platform "$PLATFORM" \
  --user "$(id -u):$(id -g)" \
  -e HOME=/conan-cache \
  -e RDB_USE_MOLD=OFF \
  -e RDB_USE_CCACHE=OFF \
  -e RDB_MACHINE="$ARCH" \
  -e RDB_ELF_MACHINE="$ELF_MACHINE" \
  -e RDB_JOBS="$JOBS" \
  -v "$ENGINE:/src:ro" \
  -v "$CACHE:/conan-cache" \
  -v "$STAGE/profiles.tsv:/profiles.tsv:ro" \
  -v "$STAGE/out:/out" \
  "$IMAGE" bash -euo pipefail -c '
    test "$(uname -m)" = "$RDB_MACHINE"
    mkdir -p "$HOME"
    work=/tmp/rdb-bundle-work
    mkdir -p "$work"
    tar -C /src --exclude=./build -cf - . | tar -C "$work" -xf -
    cd "$work"
    {
      echo "gcc: $(gcc --version | head -n 1)"
      echo "cmake: $(cmake --version | head -n 1)"
      echo "conan: $(conan --version | head -n 1)"
      echo "glibc: $(ldd --version | head -n 1)"
      echo "debian: $(cat /etc/debian_version)"
    } >/out/toolchain.txt
    conan profile detect -f
    sed -i "s/compiler.cppstd=gnu17/compiler.cppstd=gnu23/" "$HOME/.conan2/profiles/default"
    cmake_version=$(cmake --version | head -n1 | awk "{print \$3}")
    grep -q "^\[platform_tool_requires\]" "$HOME/.conan2/profiles/default" \
      || printf "\n[platform_tool_requires]\ncmake/%s\n" "$cmake_version" >> "$HOME/.conan2/profiles/default"
    conan install . -s build_type=Release --build missing >/out/conan-install.log 2>&1
    toolchain=build/Release/generators/conan_toolchain.cmake
    while IFS=$(printf "\t") read -r profile slug dedup share commutative factor; do
      [ "$profile" = profile ] && continue
      [ -n "$profile" ] || continue
      dir="build/bundle-$slug"
      cmake -S . -B "$dir" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$toolchain" \
        -DRDB_OPT_DEDUP_SUBSTRATES="$dedup" \
        -DRDB_OPT_SHARE_EQUIVALENT_SELECTS="$share" \
        -DRDB_OPT_COMMUTATIVE_ADD="$commutative" \
        -DRDB_OPT_FACTOR_MATCHED_HASH_TIMEMOVES="$factor" \
        -DRDB_OPT_SIMPLIFY_EXPRESSIONS=ON \
        -DRDB_BENCH_PROBE=ON >"/out/cmake-$slug.log" 2>&1
      targets=xretractor
      [ "$slug" = DEFAULT ] && targets="xretractor xqry xtrdb"
      cmake --build "$dir" --target $targets --parallel "$RDB_JOBS" >"/out/build-$slug.log" 2>&1
      expected=$(printf "%s\n" \
        "RDB_OPT_DEDUP_SUBSTRATES=$dedup" \
        "RDB_OPT_SHARE_EQUIVALENT_SELECTS=$share" \
        "RDB_OPT_COMMUTATIVE_ADD=$commutative" \
        "RDB_OPT_FACTOR_MATCHED_HASH_TIMEMOVES=$factor" \
        "RDB_BENCH_PROBE=ON" \
        "RDB_OPT_SIMPLIFY_EXPRESSIONS=ON")
      actual=$("$dir/src/retractor/xretractor" --build-info)
      if [ "$actual" != "$expected" ]; then
        printf "profile %s: unexpected --build-info:\n%s\n" "$profile" "$actual" >&2
        exit 1
      fi
      mkdir -p "/out/$slug"
      cp "$dir/src/retractor/xretractor" "/out/$slug/"
      if [ "$slug" = DEFAULT ]; then
        cp "$dir/src/qry/xqry" "$dir/src/rdb/xtrdb" /out/
      fi
    done </profiles.tsv
    python3 - "$RDB_ELF_MACHINE" /out/xqry /out/xtrdb /out/*/xretractor <<"PY"
import struct, sys
for name in sys.argv[2:]:
    with open(name, "rb") as f:
        header = f.read(20)
    if header[:4] != b"\x7fELF" or struct.unpack_from("<H", header, 18)[0] != int(sys.argv[1]):
        sys.exit(f"{name} is not an ELF for machine {sys.argv[1]}")
PY
    for d in /out/*/; do
      slug=$(basename "$d")
      {
        echo "\$ xretractor --build-info"
        "$d/xretractor" --build-info
        for b in "$d/xretractor" /out/xqry /out/xtrdb; do
          echo "\$ $(basename "$b") --help | grep ^Branch:"
          "$b" --help 2>&1 | grep "^Branch:"
        done
      } >"$d/build-info.txt"
    done
  ' >"$LOGDIR/container.log" 2>&1
rc=$?
set -e
cp "$STAGE"/out/*.log "$STAGE/out/toolchain.txt" "$LOGDIR/" 2>/dev/null || true
[ "$rc" -eq 0 ] || { tail -n 30 "$LOGDIR/container.log" >&2; echo "FAIL  container build (exit $rc), logs in $LOGDIR" >&2; exit 1; }
echo "OK    $(sed -n 's/^gcc: //p' "$STAGE/out/toolchain.txt")"

if [ -n "$TERMS" ]; then
  echo "=== identifying terms in the binaries ==="
  python3 -I - "$TERMS" "$STAGE/out/xqry" "$STAGE/out/xtrdb" "$STAGE"/out/*/xretractor <<'PY' || exit 1
import re, sys
terms = [l.rstrip("\n") for l in open(sys.argv[1], encoding="utf-8") if l.strip() and not l.startswith("#")]
if not terms:
    sys.exit("the terms file is empty")
# One extended regular expression per line, matched as the anonymizer matches:
# on word boundaries, ignoring case (as bin/make_inputs.sh does).
term_re = re.compile(rb"\b(?:" + b"|".join(t.encode() for t in terms) + rb")\b", re.I)
bad = 0
for name in sys.argv[2:]:
    data = open(name, "rb").read()
    hits = sorted({m.group(0).decode(errors="replace") for m in term_re.finditer(data)})
    if hits:
        bad += 1
        print(f"FAIL  {name}: {len(hits)} distinct term(s) present")
print(f"TERMS {len(sys.argv) - 2} binaries checked against {len(terms)} terms, {bad} with hits")
sys.exit(1 if bad else 0)
PY
fi

echo "=== bundles ==="
TOOLCHAIN="$(cat "$STAGE/out/toolchain.txt")"
for row in "${ROWS[@]}"; do
  IFS=$'\t' read -r profile slug dedup share commutative factor <<<"$row"
  name="rdb-$SHORT-h9-$slug-linux-$ARCH"
  dir="$STAGE/pack/$name"
  mkdir -p "$dir/bin"
  cp "$STAGE/out/$slug/xretractor" "$STAGE/out/xqry" "$STAGE/out/xtrdb" "$dir/bin/"
  chmod 0755 "$dir"/bin/*
  cp "$STAGE/out/$slug/build-info.txt" "$dir/build-info.txt"
  cat >"$dir/BUILD.txt" <<EOF
engine revision: $PIN
profile: $profile (RDB_OPT_DEDUP_SUBSTRATES=$dedup RDB_OPT_SHARE_EQUIVALENT_SELECTS=$share RDB_OPT_COMMUTATIVE_ADD=$commutative RDB_OPT_FACTOR_MATCHED_HASH_TIMEMOVES=$factor RDB_OPT_SIMPLIFY_EXPRESSIONS=ON RDB_BENCH_PROBE=ON)
profile table: rdb-experiment/$CAMPAIGN_DIR/profiles.tsv
build type: Release
architecture: $ARCH
image: $IMAGE_ID (packaging/portable/Dockerfile of the engine revision)
base image: ${BASE_DIGEST:-unknown}
$TOOLCHAIN
xqry and xtrdb: built once per architecture in the DEFAULT profile (RDB_OPT_* are definitions of the retractor target only)
EOF
  chmod 0644 "$dir/build-info.txt" "$dir/BUILD.txt"
  tar --sort=name --mtime="@$COMMIT_EPOCH" --owner=0 --group=0 --numeric-owner --format=gnu \
    -C "$STAGE/pack" -cf - "$name" | gzip -n -9 >"$OUT/$name.tar.gz"
  cp "$dir/build-info.txt" "$OUT/$name.build-info.txt"
  echo "OK    $name.tar.gz $(sha256sum "$OUT/$name.tar.gz" | cut -d' ' -f1)"
done
(cd "$OUT" && sha256sum -- *.tar.gz >SHA256SUMS)
echo "RESULT ${#ROWS[@]} bundles for $ARCH in $OUT (SHA256SUMS rewritten for every archive there)"
