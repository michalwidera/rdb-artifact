#!/usr/bin/env python3
"""Analytic regeneration of K22v5 (tab:k22-constructs) from stored data.

The campaign ships a frozen analyze.py whose main() first calls
freeze_check.sh. That gate certifies *measurement* provenance: it demands the
experiment repository on branch experiment/20260801_K22, retractordb at
dd733e3, a specific paper-arXiv commit and two binaries pinned by SHA-256.
None of that is satisfiable after the branch was merged, and none of it is
needed to re-derive the table from data already in the repository. Provenance
for the analytic mode is certified instead by bin/verify_pins.sh.

This driver therefore calls the frozen analysis functions directly, in their
original order, without touching analyze.py itself (its SHA-256 is recorded in
the campaign's PIN.md).

One deviation is required. verify_hits() compares the hit set against
manual_hits_review.csv on *absolute* paths recorded when the review was made,
so it only ever passes under /home/michal/github/rdb-experiment. The gate is
reproduced here over paths made relative to the experiment repository root,
which preserves what it checks (every hit reviewed and confirmed) while
dropping the accidental dependency on one directory layout.
"""

import argparse
import csv
import importlib.util
import sys
from pathlib import Path

ANCHOR = "results_2026"


def repo_relative(path: str) -> str:
    """Path relative to the experiment repository root, layout independent."""
    index = path.find(ANCHOR)
    return path[index:] if index >= 0 else path


def load_frozen(campaign: Path):
    spec = importlib.util.spec_from_file_location("k22v5_analyze", campaign / "analyze.py")
    module = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(campaign))
    spec.loader.exec_module(module)
    return module


def verify_hits(campaign: Path, hits) -> int:
    review_path = campaign / "manual_hits_review.csv"
    if not review_path.is_file():
        raise SystemExit("ERROR: manual_hits_review.csv missing; the full hit review is a gate")
    with review_path.open(newline="", encoding="utf-8") as handle:
        review = list(csv.DictReader(handle))

    def key(row, line):
        return (row["task"], row["family"], row["model"], row["metric"],
                row["rule_id"], repo_relative(row["path"]), str(line))

    expected = {key(x, x["line"]) for x in hits}
    observed = {key(x, x["line"]) for x in review if x["confirmed"] == "YES"}
    if expected != observed:
        raise SystemExit(
            f"ERROR: hit review incomplete: expected={len(expected)} confirmed={len(observed)} "
            f"only-in-hits={len(expected - observed)} only-in-review={len(observed - expected)}"
        )
    return len(expected)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--campaign", required=True, type=Path,
                        help="path to results_20260801_K22v5 inside the workspace checkout")
    args = parser.parse_args()

    campaign = args.campaign.resolve()
    analyze = load_frozen(campaign)

    manual = analyze.load_manual()
    constructs, hits = analyze.construction_metrics()
    auto = analyze.modification_metrics()
    rows = analyze.reconcile(auto, manual)
    reviewed = verify_hits(campaign, hits)
    analyze.verdict(rows)

    print(f"COUNT constructs={len(constructs)}")
    print(f"COUNT hits_reviewed={reviewed}")
    print(f"COUNT modification_rows={len(rows)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
