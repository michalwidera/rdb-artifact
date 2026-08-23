#!/usr/bin/env bash
# Clone the five repositories pinned by MANIFEST.md and check out exact commits.
# Default mode uses the current tooling snapshot. A campaign tag selects the
# historical engine and experiment pair while keeping docs and paper pinned.

set -euo pipefail

TARGET="${1:-./artifact-workspace}"
SELECTION="${2:-snapshot}"

ENGINE_URL="${RDB_ENGINE_URL:-https://github.com/michalwidera/retractordb.git}"
EXPERIMENT_URL="${RDB_EXPERIMENT_URL:-https://github.com/michalwidera/rdb-experiment.git}"
DOCS_PL_URL="${RDB_DOCS_PL_URL:-https://github.com/michalwidera/dokumentacja-rdb.git}"
DOCS_EN_URL="${RDB_DOCS_EN_URL:-https://github.com/michalwidera/documentation-rdb.git}"
PAPER_URL="${RDB_PAPER_URL:-https://github.com/michalwidera/paper-arXiv.git}"

ENGINE_SNAPSHOT="6dec187e6b0cc66d119d4d9a9dc384e93adf6839"
EXPERIMENT_SNAPSHOT="b713e1df47a5f94357f708706b85f5603f261534"
DOCS_PL_SNAPSHOT="ed00f6aa3f2d7b7bd1c91e2eb7248a1ee8de3bf1"
DOCS_EN_SNAPSHOT="8d543c8cbf95ab7cdb41049be3b30163e225bf5b"
PAPER_SNAPSHOT="a9947abe9a16acab0455965f2e1c675dfb8ba81d"

fail() { echo "ERROR: $*" >&2; exit 2; }

campaign_pair() {
  case "$1" in
    campaign/K6c-W2-W7)
      printf '%s\t%s\n' \
        e1e5181141f96965da4a092f7e7191f8cb0b2748 \
        f4483ef20c3bb3b6936f96709a593d1922943ada ;;
    campaign/K6c-W8-W9)
      printf '%s\t%s\n' \
        1bb2d2ce8bec35cd0ab46d168249b706ccbaf303 \
        f4483ef20c3bb3b6936f96709a593d1922943ada ;;
    campaign/K18)
      printf '%s\t%s\n' \
        bc37186ac87cb944d76cf74c7be92706a4a3a87f \
        e1e38ebe650d4c2752b98e78b463f93fe81b3d0e ;;
    campaign/K22v5)
      printf '%s\t%s\n' \
        dd733e3792fbcd5727db244b802610a6d710b8dc \
        0390a8910d72ecaa80772f3fd31a5f18a05369aa ;;
    campaign/H9-K26v3)
      printf '%s\t%s\n' \
        856ee54b0f4ab450a6b61e3c08e045f404a79488 \
        81bf4bea00efb922678862c90462fb3c0dfe5fda ;;
    campaign/H10-K24d)
      printf '%s\t%s\n' \
        34db1a291fff686d63402270722edf9c772bd4b6 \
        15ee150a779e5374248f8172d197b976d604416d ;;
    campaign/H10-K24e)
      # The reachable tag target has the same src tree as measured e2a61ff.
      printf '%s\t%s\n' \
        ef18105701158db9986d57fd74defdda72920871 \
        a9d5e18e75ef7cf5dd8a63619f469517e13aa4af ;;
    *) fail "unknown campaign selection: $1" ;;
  esac
}

if [[ "$SELECTION" == snapshot ]]; then
  ENGINE_REV="$ENGINE_SNAPSHOT"
  EXPERIMENT_REV="$EXPERIMENT_SNAPSHOT"
elif [[ "$SELECTION" == campaign/* ]]; then
  IFS=$'\t' read -r ENGINE_REV EXPERIMENT_REV < <(campaign_pair "$SELECTION")
else
  fail "selection must be 'snapshot' or campaign/*"
fi

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

clone_or_fetch() {
  local name="$1" url="$2" rev="$3"
  local repo="$TARGET/$name"
  if [[ -d "$repo/.git" ]]; then
    # The workspace is disposable: reproduce_analytic.sh runs each campaign's own
    # frozen analysis code, and some of it writes next to its inputs. That is
    # expected and reported there -- but it means a second checkout.sh over the
    # same directory finds a dirty tree. Say what to do about it, because
    # "refusing to switch revisions" alone reads like corruption.
    [[ -z "$(git -C "$repo" status --porcelain)" ]] \
      || fail "$name has local changes; refusing to switch revisions.
  If you have already run bin/reproduce_analytic.sh here, this is expected: the
  workspace is disposable and some frozen analysis code writes next to its
  inputs. Delete '$TARGET' and run this script again."
    echo "== fetch $name"
    git -C "$repo" fetch --tags --prune origin
  elif [[ -e "$repo" ]]; then
    fail "$repo exists but is not a git repository"
  else
    echo "== clone $name"
    git clone "$url" "$repo"
  fi
  git -C "$repo" cat-file -e "${rev}^{commit}" 2>/dev/null \
    || fail "$name does not contain commit $rev"
  git -C "$repo" checkout --detach "$rev"
  [[ "$(git -C "$repo" rev-parse HEAD)" == "$rev" ]] \
    || fail "$name checked out a different commit"
}

clone_or_fetch retractordb "$ENGINE_URL" "$ENGINE_REV"
clone_or_fetch rdb-experiment "$EXPERIMENT_URL" "$EXPERIMENT_REV"
clone_or_fetch dokumentacja-rdb "$DOCS_PL_URL" "$DOCS_PL_SNAPSHOT"
clone_or_fetch documentation-rdb "$DOCS_EN_URL" "$DOCS_EN_SNAPSHOT"

# The paper repository is OPTIONAL and its absence is not a failure (decision
# D-6, 2026-08-23). Neither reproduction mode reads it: reproduce_analytic.sh
# and reproduce_measure.sh have no reference to it at all. It is pinned here for
# provenance -- so that "which revision of the paper do these numbers belong to"
# has an answer -- and it stays private until submission.
#
# Making it mandatory had one concrete effect and no benefit: a stranger holding
# the artifact URL got four repositories, exit code 2 from the provenance gate,
# and no way to regenerate anything.
if clone_or_fetch paper-arXiv "$PAPER_URL" "$PAPER_SNAPSHOT" 2>/dev/null; then
  PAPER_STATE="$(git -C "$TARGET/paper-arXiv" rev-parse HEAD)"
else
  rm -rf "$TARGET/paper-arXiv"
  PAPER_STATE="not fetched (private until submission); pinned at $PAPER_SNAPSHOT"
  echo "== skip paper-arXiv: not reachable; continuing (see MANIFEST.md section 1)"
fi

echo
echo "== pinned workspace ($SELECTION)"
for name in retractordb rdb-experiment dokumentacja-rdb documentation-rdb; do
  printf '%-20s %s\n' "$name" "$(git -C "$TARGET/$name" rev-parse HEAD)"
done
printf '%-20s %s\n' paper-arXiv "$PAPER_STATE"
echo
echo "Next: RDB_WORKSPACE=$TARGET $PWD/bin/verify_pins.sh $SELECTION"
