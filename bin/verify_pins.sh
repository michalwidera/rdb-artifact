#!/usr/bin/env bash
# Verify the exact five-repository checkout, campaign tags, raw archives and,
# when RDB_XRETRACTOR is set, the source identity embedded in the binary.
# RDB_MIRROR=1 runs the subset that holds on an anonymized snapshot without
# .git -- pin declarations and archive checksums -- and reports the rest as
# SKIP. See REVIEW_MIRROR.md, step 4 of the acceptance trial.

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

ENGINE_SNAPSHOT="8aa4ee2f18a003fcf55db8a4f810c720094e1b1a"
EXPERIMENT_SNAPSHOT="4ca09c56713757b480eb6fda4d6718506a9153fd"
DOCS_PL_SNAPSHOT="07c89acd493500be248836fbadbabbdf4cc0eadd"
DOCS_EN_SNAPSHOT="5b57ebd82093ecfd71954aa3896faab791f42886"
PAPER_SNAPSHOT="b23aaf33ffef1cc15f77f83844da692fe9b1d96e"
# Milestone tag, not a branch head -- see MANIFEST.md section 1.
PAPER_TAG="artifact/K9b"
SRC_TREE_K24E="5ddad0fc7d56fb9b468d31905a6689e9896ddb39"

# An anonymized reviewer mirror is served as a snapshot without .git, so every
# check that asks git what revision this is becomes impossible there. Before
# 2026-08-26 the script simply exited 2 on the first such directory, which made
# the unauthenticated acceptance trial in REVIEW_MIRROR.md unrunnable: it asked
# for exactly this script over exactly those extracted archives. Mirror mode is
# opt-in and never inferred from a missing .git -- a genuinely broken workspace
# must keep failing loudly instead of quietly downgrading to SKIP.
MIRROR="${RDB_MIRROR:-0}"
if [[ "$MIRROR" == 1 && "$SELECTION" != snapshot ]]; then
  echo "ERROR mirror mode verifies the snapshot only; a campaign selection needs .git"
  exit 2
fi

ERRORS=0
SKIPPED=0
bad() { echo "ERROR $*"; ERRORS=$((ERRORS + 1)); }
ok() { echo "OK    $*"; }
# Skipped is not passed. Every skip is counted and restated before RESULT.
skipped() { echo "SKIP  $*"; SKIPPED=$((SKIPPED + 1)); }

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
  if [[ "$MIRROR" == 1 ]]; then
    [[ -d "$repo" ]] || { echo "ERROR missing directory: $repo"; exit 2; }
  else
    [[ -d "$repo/.git" ]] \
      || { echo "ERROR missing repository: $repo (anonymized snapshot without .git? set RDB_MIRROR=1)"; exit 2; }
  fi
done
# The paper repository is optional (decision D-6). Neither reproduction mode
# reads it; it is pinned for provenance and private until submission. Absent, it
# is reported with its pinned SHA and skipped -- never a silent pass, never a
# blocked reproduction.
PAPER_PRESENT=no
[[ "$MIRROR" == 1 ]] || { [[ -d "$PAPER/.git" ]] && PAPER_PRESENT=yes; }

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

# --- 0. The three declarations of every pin must agree ----------------------
# Each pin is written down three times: in MANIFEST.md, in this script and in
# checkout.sh. On 2026-08-23 a bump reached only the manifest and the two
# scripts kept the old paper-arXiv SHA for two commits. Nothing caught it --
# there was nothing to catch it with, because every checker used its own copy
# as the truth.
#
# What makes that drift dangerous is not the mismatch itself but where it can
# hide: paper-arXiv is optional, so a stranger's run ends in SKIP and a wrong
# provenance pin is unverifiable from outside. This section compares the three
# declarations against each other, so a half-finished bump stops the gate rather
# than travelling with it.

MANIFEST_FILE="$HERE/../MANIFEST.md"
CHECKOUT_FILE="$HERE/checkout.sh"

# Third column of a section 1 table row, which is the only 40-hex field there.
# The pattern deliberately does NOT look at the URL column. On an anonymized
# mirror that column reads `XXXX`: link redaction replaces the whole address,
# not just the account name in it. Requiring `https there made section 0 report
# all five pins as undeclared when the checker ran from the mirror -- which is
# exactly how a reviewer runs it. Anchoring on the repository name alone is also
# what manifest_campaign() below already did.
manifest_snapshot() {
  grep -E "^\| \`$1\` \|" "$MANIFEST_FILE" 2>/dev/null \
    | head -n 1 | grep -oE '[0-9a-f]{40}' | head -n 1
}
# Section 2.2 row: engine SHA first, experiment SHA second.
manifest_campaign() {
  grep -E "^\| \`$1\` \|" "$MANIFEST_FILE" 2>/dev/null \
    | head -n 1 | grep -oE '[0-9a-f]{40}' | head -n 2 | paste -sd' ' -
}
checkout_snapshot() {
  grep -E "^$1=\"[0-9a-f]{40}\"" "$CHECKOUT_FILE" 2>/dev/null \
    | head -n 1 | grep -oE '[0-9a-f]{40}'
}
# checkout.sh spells its campaign pairs across three lines, so take the first
# two 40-hex tokens after the case label.
checkout_campaign() {
  awk -v tag="$1)" '
    index($0, tag) { found = 1; next }
    found {
      line = $0
      while (match(line, /[0-9a-f]{40}/)) {
        printf "%s%s", (n++ ? " " : ""), substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
        if (n == 2) { printf "\n"; exit }
      }
    }
  ' "$CHECKOUT_FILE" 2>/dev/null
}

agree() {
  local what="$1" mine="$2" manifest="$3" checkout="$4"
  if [[ -z "$manifest" || -z "$checkout" ]]; then
    bad "$what not declared in MANIFEST.md and/or checkout.sh (manifest='${manifest:-missing}' checkout='${checkout:-missing}')"
  elif [[ "$mine" == "$manifest" && "$mine" == "$checkout" ]]; then
    ok "$what declared identically in all three files"
  else
    bad "$what disagrees: verify_pins='$mine' MANIFEST.md='$manifest' checkout.sh='$checkout'"
  fi
}

echo "=== 0. Pin declarations agree across MANIFEST.md, verify_pins.sh, checkout.sh ==="
if [[ ! -r "$MANIFEST_FILE" || ! -r "$CHECKOUT_FILE" ]]; then
  echo "SKIP  MANIFEST.md or checkout.sh not readable next to this script"
else
  agree retractordb       "$ENGINE_SNAPSHOT"     "$(manifest_snapshot retractordb)"       "$(checkout_snapshot ENGINE_SNAPSHOT)"
  agree rdb-experiment    "$EXPERIMENT_SNAPSHOT" "$(manifest_snapshot rdb-experiment)"    "$(checkout_snapshot EXPERIMENT_SNAPSHOT)"
  agree dokumentacja-rdb  "$DOCS_PL_SNAPSHOT"    "$(manifest_snapshot dokumentacja-rdb)"  "$(checkout_snapshot DOCS_PL_SNAPSHOT)"
  agree documentation-rdb "$DOCS_EN_SNAPSHOT"    "$(manifest_snapshot documentation-rdb)" "$(checkout_snapshot DOCS_EN_SNAPSHOT)"
  agree paper-arXiv       "$PAPER_SNAPSHOT"      "$(manifest_snapshot paper-arXiv)"       "$(checkout_snapshot PAPER_SNAPSHOT)"
  # The tag name is a pin too: pointing three files at the same SHA under two
  # different tag names would be the same drift wearing a disguise.
  agree "paper-arXiv tag" "$PAPER_TAG" \
    "$(grep -oE 'artifact/[A-Za-z0-9._-]+' "$MANIFEST_FILE" 2>/dev/null | head -n 1)" \
    "$(grep -oE '^PAPER_TAG="[^\"]+"' "$CHECKOUT_FILE" 2>/dev/null | head -n 1 | cut -d'"' -f2)"
  # campaign/H10-K24e is the one row where MANIFEST.md's engine column is NOT the
  # tag target. It records the revision the campaign was actually measured on,
  # e2a61ff, which a squash-merge left outside master; the tag points at ef18105,
  # whose src/ tree is object-identical (MANIFEST.md section 2.4 carries the
  # proof). Comparing the two columns literally would report that documented
  # exception as drift. So for this one tag the guard checks what has to hold
  # instead: the manifest names the measured revision in the table AND names the
  # tag target next to the equivalence chain.
  K24E_MEASURED="e2a61ffff77f0ec393aded2c220379db1564af44"
  K24E_REACHABLE="ef18105701158db9986d57fd74defdda72920871"

  for tag in campaign/K6c-W2-W7 campaign/K6c-W8-W9 campaign/K18 campaign/K22v5 \
             campaign/H9-K26v3 campaign/H10-K24d campaign/H10-K24e; do
    mine="$(campaign_pair "$tag" | tr '\t' ' ')"
    expect_manifest="$mine"
    if [[ "$tag" == campaign/H10-K24e ]]; then
      expect_manifest="${mine/$K24E_REACHABLE/$K24E_MEASURED}"
    fi
    checkout_value="$(checkout_campaign "$tag")"
    if [[ "$tag" == campaign/H10-K24e && -n "$checkout_value" ]]; then
      checkout_value="${checkout_value/$K24E_REACHABLE/$K24E_MEASURED}"
    fi
    agree "$tag" "$expect_manifest" "$(manifest_campaign "$tag")" "$checkout_value"
    if [[ "$tag" == campaign/H10-K24e ]]; then
      # The exception is only legitimate while the equivalence it rests on is
      # written down. If section 2.4 loses either SHA or the tree hash, the
      # manifest is claiming provenance it no longer proves.
      missing=""
      for needed in "$K24E_MEASURED" "$K24E_REACHABLE" "$SRC_TREE_K24E"; do
        grep -q "$needed" "$MANIFEST_FILE" || missing="$missing $needed"
      done
      [[ -z "$missing" ]] \
        && ok "campaign/H10-K24e equivalence (measured, reachable, src tree) stated in MANIFEST.md" \
        || bad "campaign/H10-K24e equivalence incomplete in MANIFEST.md; missing:$missing"
    fi
  done
fi
echo

if [[ "$MIRROR" == 1 ]]; then
echo "=== 1-3. Revision identity, campaign tags, reachability ==="
# What these three sections prove is that a directory IS a given commit. A
# redacted snapshot cannot answer that even in principle: the redaction rewrites
# file contents, so no tree hash of it can equal the pinned one. The pins are
# restated here so the transcript of a mirror run still carries them, and the
# note before RESULT says where they can be verified instead.
skipped "retractordb HEAD, campaign tags and reachability; pinned at $EXPECTED_ENGINE"
skipped "rdb-experiment HEAD, campaign tags and reachability; pinned at $EXPECTED_EXPERIMENT"
skipped "dokumentacja-rdb HEAD; pinned at $DOCS_PL_SNAPSHOT"
skipped "documentation-rdb HEAD; pinned at $DOCS_EN_SNAPSHOT"
skipped "paper-arXiv HEAD and tag $PAPER_TAG; pinned at $PAPER_SNAPSHOT (not mirrored)"
skipped "campaign/H10-K24e src tree; pinned at $SRC_TREE_K24E"
else
echo "=== 1. Exact workspace checkout ($SELECTION) ==="
check_head retractordb "$ENGINE" "$EXPECTED_ENGINE"
check_head rdb-experiment "$EXPERIMENT" "$EXPECTED_EXPERIMENT"
check_head dokumentacja-rdb "$DOCS_PL" "$DOCS_PL_SNAPSHOT"
check_head documentation-rdb "$DOCS_EN" "$DOCS_EN_SNAPSHOT"
if [[ "$PAPER_PRESENT" == yes ]]; then
  check_head paper-arXiv "$PAPER" "$PAPER_SNAPSHOT"
  # The pin names a tag, so the tag has to be what it says it is. Without this,
  # re-tagging artifact/K9b onto a later commit would leave the manifest quietly
  # describing a revision nobody can reach by that name any more -- and because
  # this repository is private, no stranger's run would ever notice.
  paper_tag_target="$(git -C "$PAPER" rev-parse -q --verify "${PAPER_TAG}^{commit}" 2>/dev/null)"
  if [[ -z "$paper_tag_target" ]]; then
    bad "paper-arXiv tag $PAPER_TAG not found; the pin names a tag that does not exist"
  elif [[ "$paper_tag_target" == "$PAPER_SNAPSHOT" ]]; then
    ok "paper-arXiv tag $PAPER_TAG resolves to the pinned commit"
  else
    bad "paper-arXiv tag $PAPER_TAG resolves to $paper_tag_target, expected $PAPER_SNAPSHOT"
  fi
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

# PINS repeats what campaign_pair() already knows -- a fourth copy, and the one
# closest at hand to edit without noticing the other three.
while read -r engine_tag engine_sha _ experiment_sha; do
  [[ "$(campaign_pair "$engine_tag" | tr '\t' ' ')" == "$engine_sha $experiment_sha" ]] \
    || bad "$engine_tag: PINS table and campaign_pair() disagree inside verify_pins.sh"
done <<<"$PINS"

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
fi

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
# A mirror has no index of tracked files, but it also has no untracked ones,
# so walking the tree counts the same sixteen entries.
if [[ "$MIRROR" == 1 ]]; then
index_count="$(find "$EXPERIMENT" -type f -iname '*raw.index.tsv' | wc -l)"
else
index_count="$(git -C "$EXPERIMENT" ls-files | grep -Ei 'raw\.index\.tsv$' | wc -l)"
fi
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
if [[ "$MIRROR" == 1 ]]; then
  echo "NOTE: mirror mode -- $SKIPPED check(s) not run. Revision identity is not"
  echo "      established by this run. It is established by cloning each source"
  echo "      from its origin at the SHA printed above and running this script"
  echo "      without RDB_MIRROR. What a mirror run does establish: the three pin"
  echo "      declarations agree, and the raw archives are byte-identical to the"
  echo "      manifest."
fi
if [[ "$ERRORS" -ne 0 ]]; then
  echo "RESULT: $ERRORS mismatch(es)"
elif [[ "$MIRROR" == 1 ]]; then
  echo "RESULT: declarations and archives match; revision identity NOT verified"
else
  echo "RESULT: all declared pins and artifacts match"
fi
exit "$ERRORS"
