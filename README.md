# rdb-artifact — the RetractorDB artifact package

This repository is the **entry point to the results**. It contains neither the
engine nor the research data — it contains the pins to them, a map of the
campaigns and the reproduction guide. If you arrived here from the paper and do
not know where to start, read in this order:

1. [`MAP.md`](MAP.md) — **what these results are**: which campaign answers which
   question, which verdict holds and which has been superseded. Without it the
   forty `results_*` directories in the experiment repository are unreadable.
2. [`MANIFEST.md`](MANIFEST.md) — **what they were measured on**: the full SHAs
   of the repositories and measurement revisions, one per campaign, plus archive
   checksums.
3. [`REPRODUCE.md`](REPRODUCE.md) — **how to repeat them**: analytic mode
   (regenerating the tables and figures from stored data) and measurement mode.
4. [`REVIEW_MIRROR.md`](REVIEW_MIRROR.md) — **how to prepare the
   double-anonymous version**: five sources with full revisions, a shared
   redaction configuration and an acceptance trial without credentials.
5. [`MIRROR_TRIAL.md`](MIRROR_TRIAL.md) — **the record of the acceptance
   trial**: what passed, what was skipped and where it was verified instead.

## What RetractorDB is

A continuous-query engine over streams with a declared rate, with the RQL
language and a plan compiler. Engine repository: `retractordb`. Experiment
repository: `rdb-experiment`. Both are pinned in [`MANIFEST.md`](MANIFEST.md).

## The pinning principle

**The package has no single historical engine SHA.** The default reproduction
and new measurements use a pinned snapshot of the current HEAD with tooling
fixes. The manifest separately preserves the actual revisions on which the
campaigns were run. Historical mode serves provenance auditing and never
presents a past measurement as a result obtained on HEAD.

## From zero, in three commands

```bash
git clone https://github.com/michalwidera/rdb-artifact.git
cd rdb-artifact
./bin/checkout.sh                 # clones and pins the repositories by SHA
./bin/reproduce_analytic.sh       # regenerates the paper's tables and numbers
```

You need no account, no credentials and nothing beyond this address.

## State

The repository was created as step **K9b** of the research plan
(`paper-arXiv/debs/done/plan-realizacji-K9b.md`). State as of 2026-08-28:

* the manifest, the campaign map, pin verification and binary verification —
  **done**;
* analytic mode (`bin/reproduce_analytic.sh`) — **done**: eight groups out of
  eight regenerate from the stored data and agree with the stored products;
* measurement mode (`bin/reproduce_measure.sh`) — the platform and provenance
  preflight is **done**, including its refusal to start on a divergence;
* autonomy of the measurement run (W-1) — **verified empirically** on the
  measurement machine with the control host cut off; evidence in
  [`tables/w1/`](tables/w1/);
* raw archives — **18 of 18 in the experiment repository**, one of them in parts;
* five frozen reviewer mirrors — **done**: created on 2026-08-26, checked
  without credentials and valid until 2027-08-25; the full verdict, the
  omissions and the checksums are recorded in
  [`MIRROR_TRIAL.md`](MIRROR_TRIAL.md);
* open: the DOI (decision D-2), before the paper is submitted.

The paper repository `paper-arXiv` is pinned but **private until review** and is
**not needed for reproduction** (decision D-6) — see
[`MANIFEST.md`](MANIFEST.md) §1.

The package's limits are listed in [`MANIFEST.md`](MANIFEST.md) §5 — read them
before treating an absence as a fault.

## License and citation

See [`CITATION.cff`](CITATION.cff). A DOI will be assigned before the paper is
submitted (decision D-2 of the K9b plan).
