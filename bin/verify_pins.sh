#!/usr/bin/env bash
# Verify the exact five-repository checkout, campaign tags, raw archives and,
# when RDB_XRETRACTOR is set, the source identity embedded in the binary.

set -uo pipefail

SELECTION="${1:-snapshot}"
# Default matched to checkout.sh and both reproduce_*.sh. It used to be ".",
# so running this from the repository root -- the obvious thing to try -- said
# "missing repository: ./retractordb" instead of checking the workspace that
# checkout.sh had just built next door.
WORKSPACE="${RDB_WORKSPACE:-./artifact-workspace}"
ENGINE="${RDB_ENGINE:-$WORKSPACE/retractordb}"
EXPERIMENT="${RDB_EXPERIMENT:-$WORKSPACE/rdb-experiment}"
DOCS_PL="${RDB_DOCS_PL:-$WORKSPACE/dokumentacja-rdb}"
DOCS_EN="${RDB_DOCS_EN:-$WORKSPACE/documentation-rdb}"
PAPER="${RDB_PAPER:-$WORKSPACE/paper-arXiv}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENGINE_SNAPSHOT="6dec187e6b0cc66d119d4d9a9dc384e93adf6839"
EXPERIMENT_SNAPSHOT="b713e1df47a5f94357f708706b85f5603f261534"
DOCS_PL_SNAPSHOT="ed00f6aa3f2d7b7bd1c91e2eb7248a1ee8de3bf1"
DOCS_EN_SNAPSHOT="8d543c8cbf95ab7cdb41049be3b30163e225bf5b"
PAPER_SNAPSHOT="a9947abe9a16acab0455965f2e1c675dfb8ba81d"
SRC_TREE_K24E="5ddad0fc7d56fb9b468d31905a6689e9896ddb39"

ERRORS=0
bad() { echo "ERROR $*"; ERRORS=$((ERRORS + 1)); }
ok() { echo "OK    $*"; }

campaign_pair() {
  case "$1" in
    campaign/K6c-W2-W7)
      printf '%s\t%s\n' e1e5181141f96965da4a092f7e7191f8cb0b2748 f4483ef20c3bb3b6936f96709a593d1922943ada ;;
    campaign/K6c-W8-W9)
      printf '%s\t%s\n' 1bb2d2ce8bec35cd0ab46d168249b706ccbaf303 f4483ef20c3bb3b6936f96709a593d1922943ada ;;
    campaign/K18)
      printf '%s\t%s\n' bc37186ac87cb944d76cf74c7be92706a4a3a87f e1e38ebe650d4c2752b98e78b463f93fe81b3d0e ;;
    campaign/K22v5)
      printf '%s\t%s\n' dd733e3792fbcd5727db244b802610a6d710b8dc 0390a8910d72ecaa80772f3fd31a5f18a05369aa ;;
    campaign/H9-K26v3)
      printf '%s\t%s\n' 856ee54b0f4ab450a6b61e3c08e045f404a79488 81bf4bea00efb922678862c90462fb3c0dfe5fda ;;
    campaign/H10-K24d)
      printf '%s\t%s\n' 34db1a291fff686d63402270722edf9c772bd4b6 15ee150a779e5374248f8172d197b976d604416d ;;
    campaign/H10-K24e)
      printf '%s\t%s\n' ef18105701158db9986d57fd74defdda72920871 a9d5e18e75ef7cf5dd8a63619f469517e13aa4af ;;
    *) return 1 ;;
  esac
}

for repo in "$ENGINE" "$EXPERIMENT" "$DOCS_PL" "$DOCS_EN"; do
  [[ -d "$repo/.git" ]] || { echo "ERROR missing repository: $repo"; exit 2; }
done
# The paper repository is optional (decision D-6). Neither reproduction mode
# reads it; it is pinned for provenance and private until submission. Absent, it
# is reported with its pinned SHA and skipped -- never a silent pass, never a
# blocked reproduction.
PAPER_PRESENT=no
[[ -d "$PAPER/.git" ]] && PAPER_PRESENT=yes

if [[ "$SELECTION" == snapshot ]]; then
  EXPECTED_ENGINE="$ENGINE_SNAPSHOT"
  EXPECTED_EXPERIMENT="$EXPERIMENT_SNAPSHOT"
elif [[ "$SELECTION" == campaign/* ]]; then
  if ! IFS=$'\t' read -r EXPECTED_ENGINE EXPECTED_EXPERIMENT \
      < <(campaign_pair "$SELECTION"); then
    echo "ERROR unknown campaign selection: $SELECTION"
    exit 2
  fi
else
  echo "ERROR selection must be 'snapshot' or campaign/*"
  exit 2
fi

check_head() {
  local name="$1" repo="$2" expected="$3" actual
  actual="$(git -C "$repo" rev-parse HEAD 2>/dev/null)"
  if [[ "$actual" == "$expected" ]]; then ok "$name HEAD = $expected"
  else bad "$name HEAD = $actual, expected $expected"; fi
}

echo "=== 1. Exact workspace checkout ($SELECTION) ==="
check_head retractordb "$ENGINE" "$EXPECTED_ENGINE"
check_head rdb-experiment "$EXPERIMENT" "$EXPECTED_EXPERIMENT"
check_head dokumentacja-rdb "$DOCS_PL" "$DOCS_PL_SNAPSHOT"
check_head documentation-rdb "$DOCS_EN" "$DOCS_EN_SNAPSHOT"
if [[ "$PAPER_PRESENT" == yes ]]; then
  check_head paper-arXiv "$PAPER" "$PAPER_SNAPSHOT"
else
  echo "SKIP  paper-arXiv absent; optional, pinned at $PAPER_SNAPSHOT (private until submission)"
fi

echo
echo "=== 2. Campaign tags ==="
PINS=$(cat <<'PINS_EOF'
campaign/K6c-W2-W7 e1e5181141f96965da4a092f7e7191f8cb0b2748 campaign/K6c f4483ef20c3bb3b6936f96709a593d1922943ada
campaign/K6c-W8-W9 1bb2d2ce8bec35cd0ab46d168249b706ccbaf303 campaign/K6c f4483ef20c3bb3b6936f96709a593d1922943ada
campaign/K18 bc37186ac87cb944d76cf74c7be92706a4a3a87f campaign/K18 e1e38ebe650d4c2752b98e78b463f93fe81b3d0e
campaign/K22v5 dd733e3792fbcd5727db244b802610a6d710b8dc campaign/K22v5 0390a8910d72ecaa80772f3fd31a5f18a05369aa
campaign/H9-K26v3 856ee54b0f4ab450a6b61e3c08e045f404a79488 campaign/H9-K26v3 81bf4bea00efb922678862c90462fb3c0dfe5fda
campaign/H10-K24d 34db1a291fff686d63402270722edf9c772bd4b6 campaign/H10-K24d 15ee150a779e5374248f8172d197b976d604416d
campaign/H10-K24e ef18105701158db9986d57fd74defdda72920871 campaign/H10-K24e a9d5e18e75ef7cf5dd8a63619f469517e13aa4af
PINS_EOF
)

while read -r engine_tag engine_sha experiment_tag experiment_sha; do
  actual="$(git -C "$ENGINE" rev-parse -q --verify "${engine_tag}^{commit}" 2>/dev/null)"
  [[ "$actual" == "$engine_sha" ]] && ok "$engine_tag engine" \
    || bad "$engine_tag engine = ${actual:-missing}, expected $engine_sha"
  actual="$(git -C "$EXPERIMENT" rev-parse -q --verify "${experiment_tag}^{commit}" 2>/dev/null)"
  [[ "$actual" == "$experiment_sha" ]] && ok "$engine_tag experiment via $experiment_tag" \
    || bad "$experiment_tag experiment = ${actual:-missing}, expected $experiment_sha"
done <<<"$PINS"

echo
echo "=== 3. Campaign reachability and K24e equivalence ==="
ENGINE_MAIN=master
git -C "$ENGINE" show-ref --verify --quiet refs/remotes/origin/master && ENGINE_MAIN=origin/master
EXPERIMENT_MAIN=main
git -C "$EXPERIMENT" show-ref --verify --quiet refs/remotes/origin/main && EXPERIMENT_MAIN=origin/main
while read -r engine_tag _ experiment_tag _; do
  git -C "$ENGINE" merge-base --is-ancestor "${engine_tag}^{commit}" "$ENGINE_MAIN" \
    && ok "$engine_tag reachable from engine mainline" \
    || bad "$engine_tag is outside engine mainline"
  git -C "$EXPERIMENT" merge-base --is-ancestor "${experiment_tag}^{commit}" "$EXPERIMENT_MAIN" \
    && ok "$experiment_tag reachable from experiment mainline" \
    || bad "$experiment_tag is outside experiment mainline"
done <<<"$PINS"

actual="$(git -C "$ENGINE" rev-parse -q --verify 'campaign/H10-K24e^{}:src' 2>/dev/null)"
[[ "$actual" == "$SRC_TREE_K24E" ]] && ok "K24e src tree = $actual" \
  || bad "K24e src tree = ${actual:-missing}, expected $SRC_TREE_K24E"

echo
echo "=== 4. Raw archive inventory ==="
# The archive table in MANIFEST.md describes the experiment repository at the
# SNAPSHOT revision. A campaign checkout sits at an older revision, where later
# archives and indexes legitimately do not exist yet, so checking the current
# table against it would report absence as corruption. The inventory is a
# snapshot-level invariant and is verified there.
if [[ "$SELECTION" != snapshot ]]; then
  echo "SKIP  snapshot-level invariant; run 'verify_pins.sh snapshot' to check it"
else
index_count="$(git -C "$EXPERIMENT" ls-files | grep -Ei 'raw\.index\.tsv$' | wc -l)"
[[ "$index_count" -eq 16 ]] && ok "index files = 16" \
  || bad "index files = $index_count, expected 16"

PRESENT=$(cat <<'RAW_EOF'
results_20260728_K4/results/raw.tar.gz 407cb32400c57fdc7c9f969821de134062120bce57399ac051c6162618d79968
results_20260729_K5/results/raw.tar.gz 975af64bc94cef2949fdfbc442866c8486deadc9acfee7bde840e35ecea99460
results_20260729_K5_rerun/results/raw.tar.gz cd20f8d38984ac4164a9b45a4aee601441271215ff223785b0790d2df59503dd
results_20260729_hygiene/results/raw.tar.gz 340872b0f338bd92bb2ae204456eefd308b85b3047002353fc48f96ba9aeec9b
results_20260730_K6b/ablation/study_01_W2/raw.tar.gz 8bc8b52bda07c3e29b5e341b163587069002139fa3751c3dd81dc30d60e6e0e7
results_20260730_K6c/ablation/study_01_W2/raw.tar.gz 3380390d2af43c768387f0da7e8d0f0f5dfceaaa7563201c382339b04baf92ee
results_20260730_K6c/ablation/study_02_W3/raw.tar.gz 105c211b951f06a429591a95273c2e85f08c2dc305bedf49459bc5392cd63618
results_20260730_K6c/ablation/study_03_W4/raw.tar.gz 841a882a3dec0a83dde685ae19dd3d7996e81673b08de5cd16de012766c2d401
results_20260730_K6c/ablation/study_04_W5/raw.tar.gz ce46589c8c850d9eb0a538e63c93bd6bf1f27ed7453b1c6d2394b95ce99023ed
results_20260730_K6c/ablation/study_05_W7/raw.tar.gz 3d6bf640c7a0ddbe4bb32f87dcb084cabebbf5efa119352473ba5621d684dec4
results_20260730_hygiene/results/raw.tar.gz b582f33356f73bf0a4e2f200733d5cc0c8a5bd2cac2c5367f61c61db290695b5
results_20260731_hygiene/results/raw.tar.gz 42bc80319943ad697dede45e1cab78b4b9fb9ff94c0671ed66217872ca54b50f
results_20260730_K6c/ablation/study_07_W9/results_20260730_K6c_study_07_W9_raw.tar.gz 0f0b504a0dd3f50f12ae4ef5bd60e90c2e2702215388fd84d6dc54ee06055280
results_20260731_hygiene220/results/raw.tar.gz 6993a2877741d65e480167a7068370b06416dee278c00f4f156c4232a205963c
artifacts/K26v3/k26v3_archives/K26v3-P8-F9-R1.tar.gz 8c4ac248eb8e5f91f35ca90ce61f1f3ff10eef7db58042ab62238cd349b256a3
artifacts/K26v3/k26v3_archives/K26v3-P8-F9-R2.tar.gz 62b065a89e82126c08f2a973195e10688bd1adfcbdb2840d5f57ea22248c0db7
artifacts/K26v3/k26v3_archives/K26v3-P8-F9-X.tar.gz 3deb300733f3662dd042ca0109eb73aa696c4eb5da7d8b3b62745735c94c2e04
RAW_EOF
)
while read -r path expected; do
  if [[ ! -f "$EXPERIMENT/$path" ]]; then
    bad "missing archive declared present: $path"
    continue
  fi
  actual="$(sha256sum "$EXPERIMENT/$path" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] && ok "$path" \
    || bad "$path SHA-256 = $actual, expected $expected"
done <<<"$PRESENT"

# The one archive too large for a single file on GitHub (154.6 MiB against a
# 100 MB hard limit). Since 2026-08-23 the repository carries it in four parts
# plus an index; the parts ARE tracked, so a fresh clone can rebuild it with
# rdb-experiment/lib/raw_parts.sh join. What is checked here is what a clone
# actually has -- the parts and their checksums -- and, when the whole file also
# happens to be on this machine, that too. Checking only the whole file would
# pass on the author's disk and fail on every clone.
W8="results_20260730_K6c/ablation/study_06_W8/results_20260730_K6c_study_06_W8_raw.tar.gz"
W8_WHOLE_SHA="03f503fee2504ef46d8d5f367807442be28593f8081a487911475726609d4e51"
PARTS=$(cat <<'PARTS_EOF'
part-00 47185920 afec4ccbf170b9c249b46c0d45f3522a0320379c0e1db2020edb3b04ad2b0ebd
part-01 47185920 a16250bedca656037d277021d3e08376d98ef035b9a45a5dba14cc6327774775
part-02 47185920 5621333ffc9b565bfae41e8cc28fda16e002cdcf5a48636780c4cc66148e502f
part-03 20610225 3891943a91ce7f86d9e70319aaa64aa4d33853884996349b3cbad6bf4ee71d26
PARTS_EOF
)
while read -r part bytes expected; do
  f="$EXPERIMENT/$W8.$part"
  if [[ ! -f "$f" ]]; then bad "missing W8 part: $W8.$part"; continue; fi
  actual="$(sha256sum "$f" | awk '{print $1}')"
  if [[ "$actual" == "$expected" && "$(stat -c %s "$f")" == "$bytes" ]]; then ok "W8 $part"
  else bad "W8 $part SHA-256 = $actual, expected $expected"; fi
done <<<"$PARTS"

if [[ -f "$EXPERIMENT/$W8.parts.tsv" ]]; then
  ok "W8 parts index present"
else
  bad "missing W8 parts index: $W8.parts.tsv"
fi

if [[ -f "$EXPERIMENT/$W8" ]]; then
  actual="$(sha256sum "$EXPERIMENT/$W8" | awk '{print $1}')"
  [[ "$actual" == "$W8_WHOLE_SHA" ]] && ok "W8 whole archive (assembled, outside git)" \
    || bad "W8 whole archive SHA-256 = $actual, expected $W8_WHOLE_SHA"
else
  echo "SKIP  W8 whole archive not assembled here; rebuild with lib/raw_parts.sh join"
fi

# Archives believed lost. Empty since 2026-08-23: the last three turned up on
# the desktop host and were committed the same day. This list stays as the place
# where a real loss gets declared -- silence is not availability.
MISSING=""
if [[ -n "$MISSING" ]]; then
  while read -r path; do
    [[ ! -e "$EXPERIMENT/$path" ]] && ok "$path explicitly absent" \
      || bad "$path now exists; MANIFEST.md must be updated"
  done <<<"$MISSING"
else
  ok "no archive is declared lost (17 of 18 in git; W8 in four tracked parts)"
fi
fi

if [[ -n "${RDB_XRETRACTOR:-}" ]]; then
  echo
  echo "=== 5. Binary provenance ==="
  "$HERE/verify_binary.sh" "$EXPECTED_ENGINE" "$RDB_XRETRACTOR" \
    || ERRORS=$((ERRORS + 1))
fi

echo
if [[ "$ERRORS" -eq 0 ]]; then
  echo "RESULT: all declared pins and artifacts match"
else
  echo "RESULT: $ERRORS mismatch(es)"
fi
exit "$ERRORS"
