# Mirror acceptance trial -- record

This is the step 6 record that `REVIEW_MIRROR.md` asks for: mirror IDs, pinned
revisions, UTC time, what was run, what it established, and which checks were
skipped and where they are verified instead.

Run on **2026-08-26**, finishing `2026-08-26T13:03:54Z`. Performed from a shell
with no GitHub session and no Anonymous GitHub session, using `curl` against the
public endpoints only.

## Mirrors

| Role | Source | Pinned revision | Mirror ID |
|---|---|---|---|
| Engine snapshot | `retractordb` | `6dec187e6b0cc66d119d4d9a9dc384e93adf6839` | `retractordb-engine` |
| Experiments and data | `rdb-experiment` | `b713e1df47a5f94357f708706b85f5603f261534` | `retractordb-experiment` |
| Canonical documentation | `dokumentacja-rdb` | `ed00f6aa3f2d7b7bd1c91e2eb7248a1ee8de3bf1` | `dokumentacja-rdb` |
| Derived documentation | `documentation-rdb` | `8d543c8cbf95ab7cdb41049be3b30163e225bf5b` | `documentation-rdb` |
| Artifact entry point | `rdb-artifact` | `TBA_AFTER_REVIEW` | `retractordb-artifact` -- **not built** |

Addresses are `https://anonymous.4open.science/r/<mirror ID>`. All four existing
mirrors were created 2026-08-26 and expire 2027-08-25. Automatic branch updates
are off, so each mirror stays on the revision above.

## What the trial established

| Step | Verdict |
|---|---|
| 1. Open every URL as printed in the paper | **not applicable yet** -- the addresses entered `references.bib` on 2026-08-26, and the entry-point mirror does not exist |
| 2. Download all archives, no `401` | **pass** for four of five: HTTP 200 unauthenticated from `/api/repo/<id>/zip` |
| 3. Search paths and text for every configured term | **pass**: zero hits across all four extracted trees |
| 4. `verify_pins.sh` in mirror mode | **pass**, exit status 0 |
| 5. Analytic reproduction | **out of scope for a mirror** -- runs on a clone, see `REVIEW_MIRROR.md` |
| 6. Record the run | this file |

Step 4 was run as:

```bash
RDB_MIRROR=1 \
RDB_ENGINE=<ws>/retractordb RDB_EXPERIMENT=<ws>/rdb-experiment \
RDB_DOCS_PL=<ws>/dokumentacja-rdb RDB_DOCS_EN=<ws>/documentation-rdb \
./bin/verify_pins.sh snapshot
```

Section 0 reported all fourteen pin declarations agreeing across `MANIFEST.md`,
`checkout.sh` and `verify_pins.sh`. Section 4 reported sixteen raw index files,
seventeen `raw.tar.gz` archives matching their manifest SHA-256, all four W8
parts matching theirs, and the parts index present. The assembled whole W8
archive is skipped by design: it lives outside git and is rebuilt with
`lib/raw_parts.sh join`.

## Skipped checks and where they are verified instead

Six checks were skipped, all of them the same kind: they ask git which commit a
directory is, and a mirror is a snapshot without history. A redacted copy cannot
answer that even in principle, because the redaction rewrites file contents and
no tree hash of it can equal the pinned one.

| Skipped | Verified instead by |
|---|---|
| `retractordb` HEAD, campaign tags, reachability | cloning at `6dec187e…` and running `verify_pins.sh` without `RDB_MIRROR` |
| `rdb-experiment` HEAD, campaign tags, reachability | as above, at `b713e1df…` |
| `dokumentacja-rdb` HEAD | as above, at `ed00f6aa…` |
| `documentation-rdb` HEAD | as above, at `8d543c8c…` |
| `paper-arXiv` HEAD and tag `artifact/K9b` | not mirrored; optional and private until submission (D-6) |
| `campaign/H10-K24e` src tree | clone; the equivalence chain is stated in `MANIFEST.md` section 2.4 |

## Findings

**Binary archives survive byte for byte.** All twenty-one checked files -- the
seventeen `raw.tar.gz` and the four W8 parts, three of which are 45 MiB --
matched their manifest SHA-256 after passing through the mirror. Redaction does
not touch `.tar.gz`.

**Image files are removed from the archive, not merely hidden.** Turning off
image display drops them from the download as well as from the rendered view:

| Mirror | Files in archive | Files in git | Missing |
|---|---:|---:|---:|
| `retractordb` | 913 | 915 | 2 |
| `rdb-experiment` | 4314 | 4314 | 0 |
| `dokumentacja-rdb` | 89 | 157 | 68 |
| `documentation-rdb` | 85 | 153 | 68 |

Every missing file is an image. Both documentation mirrors therefore carry no
figures. This is accepted rather than fixed: three of those files
(`assets/adhoc-example.svg`, `agse-example.svg`, `alarm-example.svg`) are
terminal recordings stored as SVG whose shell prompt is split across markup
elements, so term redaction cannot be trusted to catch it whole.

**Redaction matches on word boundaries.** `wideRational` in
`src/retractor/lib/compiler.cpp` is untouched by the `widera` term -- four
occurrences in the mirror against four in the source. Substring matching would
have rewritten identifiers and broken the build.

**One leak was found and closed during the run.** After the first pass,
`CITATION.cff` still read `title: "RetractorDB: A Deterministic Edge Signal
Processing Engine Based on XXXX-16"`. The original term covered the tail of the
preprint title but not its prefix, which resolves to the preprint just as well.
The term was extended to the whole title and the file now reads
`title: "RetractorDB: XXXX-16"`.

**Running the checker from the mirror found a second defect.** The artifact
mirror was built on 2026-08-26 at `e3a7819af89143e046062913e37202f6557388de`;
its `bin/verify_pins.sh` is byte-identical to the source, but running it against
the four mirrored sources reported `RESULT: 5 mismatch(es)`. Section 0 located
each pin by a pattern that included the URL column, and link redaction had
replaced that whole column with `XXXX` -- the address, not merely the account
name in it. All five pins therefore read as undeclared. The pattern now anchors
on the repository name alone, matching what the campaign lookup beside it always
did, and the fixed script returns exit 0 against the redacted manifest. The
artifact mirror has to be rebuilt at the commit carrying the fix; the four source
mirrors are unaffected, because the defect was in the checker, not in them.

`bin/checkout.sh` in the mirror differs from its source, as it must: it carries
clone URLs and they are redacted. Reviewers work from the mirrors, not from
clones made by that script.

## Downloaded archives

| Archive | Bytes | SHA-256 |
|---|---:|---|
| `documentation-rdb.zip` | 315475 | `7f6d3cdea964cd738c81a29e0d9b66d060289fd7e1495f9ebdf43ec165f8b5e2` |
| `dokumentacja-rdb.zip` | 359638 | `ae3862e2b5b15812b5e0d293a39d47c47b76f4341404f2c90f7822a918ba413d` |
| `retractordb-engine.zip` | 3850388 | `7d5abd7fe270bc17b918977699ddc4a5da609ab3262bb91b6c4575811c227a38` |
| `retractordb-experiment.zip` | 505021168 | `5fa2dd35e680a414c3f9f7bf9d2a8fb41c4175006a635f20f77509e41bbcfb85` |

These identify this download, not the mirror. The service builds each archive on
request and stamps fresh timestamps into it, so a later download of an unchanged
mirror will carry a different checksum. What is stable, and what section 4
actually checks, is the checksum of each file inside.

## Open items

* `retractordb-artifact` does not exist. It is the entry point the paper cites,
  so until it is built that citation resolves to nothing. It waits on this
  repository's own pin closing.
* Steps 1 and 5 remain, and step 2 has to be repeated once the fifth mirror
  exists.
* The paper may not claim availability until all six steps pass. As of this
  record it does not: `paper-debs2027.tex` states what the trial established and
  nothing beyond it.
