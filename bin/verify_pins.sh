#!/usr/bin/env bash
# Verify the exact five-repository checkout, campaign tags, raw archives and,
# when RDB_XRETRACTOR is set, the source identity embedded in the binary.

set -uo pipefail

SELECTION="${1:-snapshot}"
WORKSPACE="${RDB_WORKSPACE:-.}"
ENGINE="${RDB_ENGINE:-$WORKSPACE/retractordb}"
EXPERIMENT="${RDB_EXPERIMENT:-$WORKSPACE/rdb-experiment}"
DOCS_PL="${RDB_DOCS_PL:-$WORKSPACE/dokumentacja-rdb}"
DOCS_EN="${RDB_DOCS_EN:-$WORKSPACE/documentation-rdb}"
PAPER="${RDB_PAPER:-$WORKSPACE/paper-arXiv}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENGINE_SNAPSHOT="661635072872b2a3dbd432f3d4a2654f0fc1b32e"
EXPERIMENT_SNAPSHOT="a9d5e18e75ef7cf5dd8a63619f469517e13aa4af"
DOCS_PL_SNAPSHOT="f094ac9699dc9dcd2a704619d0d27570afaa1e11"
DOCS_EN_SNAPSHOT="7ed35ee86005496cfcf22d596ced36919fa943d4"
PAPER_SNAPSHOT="0c2e562b28f015d663610add667ab392366f6cf2"
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

for repo in "$ENGINE" "$EXPERIMENT" "$DOCS_PL" "$DOCS_EN" "$PAPER"; do
  [[ -d "$repo/.git" ]] || { echo "ERROR missing repository: $repo"; exit 2; }
done

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
check_head paper-arXiv "$PAPER" "$PAPER_SNAPSHOT"

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

MISSING=$(cat <<'MISSING_EOF'
results_20260730_K6c/ablation/study_06_W8/results_20260730_K6c_study_06_W8_raw.tar.gz
results_20260730_K6c/ablation/study_07_W9/results_20260730_K6c_study_07_W9_raw.tar.gz
results_20260731_hygiene220/results/raw.tar.gz
MISSING_EOF
)
while read -r path; do
  [[ ! -e "$EXPERIMENT/$path" ]] && ok "$path explicitly absent" \
    || bad "$path now exists; MANIFEST.md must be updated"
done <<<"$MISSING"
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
