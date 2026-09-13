# MANIFEST — the artifact package's pins

State: **2026-08-28**. Built as part of K9b
(`paper-arXiv/debs/done/plan-realizacji-K9b.md`). Every repository pin is a full,
forty-character SHA. A branch name is not a version identifier.

## 1. Repositories and the pinned default layout

The default reproduction and all **new** runs use a pinned snapshot of the
current HEAD. This is a separate axis from the historical campaign provenance of
§2.2: past measurements are not rewritten onto newer code.

| Repository | URL | Default snapshot SHA | Role | Reviewer mirror |
|---|---|---|---|---|
| `retractordb` | `https://github.com/michalwidera/retractordb.git` | `40c28dbefec8324df45365d863050fc577623768` | engine and fixed tooling | `retractordb-engine` |
| `rdb-experiment` | `https://github.com/michalwidera/rdb-experiment.git` | `f5475d004d0224f8ae2fce94fccadd3feb5e6d88` | campaigns and data | `retractordb-experiment` |
| `dokumentacja-rdb` | `https://github.com/michalwidera/dokumentacja-rdb.git` | `ba875ba5e648d46412c8d82ce669c43777ec1e8e` | PL documentation (canonical) | `dokumentacja-rdb` |
| `documentation-rdb` | `https://github.com/michalwidera/documentation-rdb.git` | `4b0b7ae70b42f2279afb080b22bee4d78f2643bc` | EN documentation (derived) | `documentation-rdb` |
| `paper-arXiv` | `https://github.com/michalwidera/paper-arXiv.git` | `b23aaf33ffef1cc15f77f83844da692fe9b1d96e` — tag `artifact/K9b` | paper and research plan — **optional, private until review** (D-6) | — not mirrored |

The `rdb-artifact` repository is the entry point, so it does not pin its own SHA
in the same commit. Its URL is
`https://github.com/michalwidera/rdb-artifact.git` and it has been **public
since 2026-08-23**. Its reviewer mirror `retractordb-artifact` has existed since
2026-08-26 and was re-pointed on 2026-09-02 to revision
`3c5e4357de0e2fec0377f465848fcb128a1dc86d`; the other four mirrors in the table
were re-pointed the same day to the pins then above. **Pending:** on 2026-09-13
the engine pin moved (§2.1) and so did both documentation pins, from `07c89ac`
and `5b57ebd`, to carry the documentation's own drift against the Lean proofs
(`doc_drift_scalar_functions` and `proof_drift` pass against them). The English
documentation pin then moved once more, to `4b0b7ae`, which only removes
`gen_anonymous_pdf.sh`: its patterns spelled the author's name inside regular
expressions, where word-boundary redaction cannot reach it, so the mirror showed
it. The script now lives in the private paper repository. The experiment pin
moved from `4ca09c5` to `4ba2880`, which only adds `results_20260912_K24f/` —
the campaign that §2.2, `MAP.md` and `REPRODUCE.md` already describe, and that
the old pin did not contain. It then moved once more, to `f5475d0`, which only
adds `.csv.gz` copies of the nineteen raw K24-series CSV files of 1.2 MB or
more: the mirror refuses to serve a text file of that size (HTTP 502) and cuts
the repository ZIP off before reaching them, while it serves compressed files
byte for byte (`REVIEW_MIRROR.md`). The `campaign/H10-K24f` row of §2.2 keeps
`4ba2880`, the revision the campaign was recorded at. All five mirrors were
re-pointed on 2026-09-13 to the pins as they stood before that last move;
`retractordb-experiment` and `retractordb-artifact` still have to follow it.
Automatic updates are disabled. Mirror identifiers are not randomized — the author chooses
them. The addresses, the pins and the result of the credential-free trial are
recorded in [`MIRROR_TRIAL.md`](MIRROR_TRIAL.md).

**The `paper-arXiv` pin points at the annotated tag `artifact/K9b`, not at a
branch head (decision of 2026-08-23).** The other four repositories pin by
snapshot SHA, because their `HEAD` moves rarely and for reasons that concern the
package. The paper repository behaves differently: in the fourteen days before
that tag it received **57 commits**, of which 28 touched `debs/`, 19 touched
`usecases/`, and the paper proper (`arxiv/`, `figures/`) — **two**. Pinning to
`HEAD` would therefore answer the question "what is the repository's latest
commit", whereas it must answer "which revision of the paper do these numbers
belong to".

The pin moves at a milestone, not at an editorial fix. Next move:
`artifact/submission` in K17. This is the same pattern as the `campaign/*` tags
in §2.2, and for the same reason.

**The first four repositories are public and required. The fifth is neither
(decision D-6, 2026-08-23).** `paper-arXiv` carries the paper before review and
stays private until publication; it is pinned here **as provenance only** — so
that the question "which revision of the paper do these numbers belong to" has
an answer. No reproduction mode reads it: `bin/reproduce_analytic.sh` and
`bin/reproduce_measure.sh` contain not a single reference to it.

`bin/checkout.sh` attempts to clone it and **carries on** if it cannot;
`bin/verify_pins.sh` then prints `SKIP` with the pinned SHA. Requiring it blocked
the whole package: an outsider with the public URL got four repositories and
exit code 2 from the provenance gate, with no way to regenerate anything.

## 2. Two pinning axes

### 2.1. Code for reproduction and new measurements

The engine code and the tooling come from the full SHA
`40c28dbefec8324df45365d863050fc577623768`. A result obtained on it is a **new
reproduction**, not a historical measurement from the paper's tables.

The pin was bumped on 2026-09-13 from
`8aa4ee2f18a003fcf55db8a4f810c720094e1b1a`, to bring the Lean 4 formalization
(`math_proofs/`) and its engine oracle (`ut_proofOracle`, `proof_drift`) into
the snapshot — see `REPRODUCE.md` §6. **This bump also moves the engine**:
eleven commits separate the two revisions, among them the multi-server bus
(issue 238), expression type inference (issue 240), a compiler fix for a loop in
the plan, and a fix in the file accessor group.

The full analytic run of 2026-09-13, from a fresh checkout at the new pin,
regenerated eight groups out of eight, and every product with a stored copy
matched it: seven byte for byte, the G3 report modulo its generation timestamp.
One pinned value changed, and not because of the engine. The `fig:qrs` peaks
moved from `x=128`/`x=371` to `x=122`/`x=365`. The engine computes the same
values — all three series of the frame are identical to the old ones shifted by
six records — but the old client lost the rows computed between its `get` and
its later `show` subscription, six of them here, so the old frame ended six
records late. That client fix was made because parallel integration tests
failed on starved CI containers; locally the loss was stable, which is why it
passed unnoticed. The new positions held in 13 runs out of 13, three of them
pinned to one loaded CPU core. The frame now really is records `[1271,1670]`.

The same run exposed a defect in `bin/reproduce_analytic.sh` and it was fixed
with the bump: groups were called inside an `if`, where bash ignores errexit,
so a failed step anywhere but on a group's last line was recorded as `OK`. The
`ecg` group printed `ERROR` for the stale peaks and still passed. Each group now
runs in a subshell with errexit in force; a deliberate failure in the middle of
a group, and the stale peak window, both turn the run red.

The previous bump, on 2026-09-02 from
`6dec187e6b0cc66d119d4d9a9dc384e93adf6839`, **did move the engine** too. The earlier bump of 2026-08-23 could be justified by an object
identity of the `src/` tree; this one cannot, and pretending otherwise would be
the more dangerous of the two options. Twenty-one commits separate the two
revisions, and they carry real functional work: a new stream grammar (issue
236), AGSE and array-propagation fixes, window aggregates in `SELECT`, an IPC
rework, and two changes made for the reviewer's sake — the withdrawal of the
`.meta` creation timestamp and the removal of Polish text from the engine's
runtime messages.

The consequence is stated rather than hidden: **the analytic products were
re-derived on the new pin, not carried over.** The full run of 2026-09-02
regenerated eight groups out of eight; seven of them were compared against the
copies stored in git and matched. The eighth, `ecg`, has no stored copy to
compare against — it renders a figure, and what is checked instead is the pinned
window: the frame still held 400 samples with QRS complexes at `x=128` and
`x=371` (positions superseded on 2026-09-13, see above). That run is recorded in [`MIRROR_TRIAL.md`](MIRROR_TRIAL.md), *Second
trial*. Where a product depends on the engine, it was recomputed; where it
depends only on frozen campaign data, the data did not move.

One thing the bump does change for a reader of §5 in `REPRODUCE.md`: from this
pin onward the `.meta` header is a reserved field written as zero, so a
reproduction on the pinned engine yields artifacts that are bit-for-bit
repeatable over their whole length. The campaigns of §2.2 were measured before
that change and their records keep the older behaviour.

### 2.2. The revisions on which the historical campaigns were run

| Engine tag | Engine measured | Experiment tag | Experiment | Artifact in the paper |
|---|---|---|---|---|
| `campaign/K6c-W2-W7` | `e1e5181141f96965da4a092f7e7191f8cb0b2748` | `campaign/K6c` | `f4483ef20c3bb3b6936f96709a593d1922943ada` | `tab:k6-primary`, W2–W7 |
| `campaign/K6c-W8-W9` | `1bb2d2ce8bec35cd0ab46d168249b706ccbaf303` | `campaign/K6c` | `f4483ef20c3bb3b6936f96709a593d1922943ada` | `tab:k6-primary`, W8–W9 |
| `campaign/K18` | `bc37186ac87cb944d76cf74c7be92706a4a3a87f` | `campaign/K18` | `e1e38ebe650d4c2752b98e78b463f93fe81b3d0e` | throughput, latency, replay stability |
| `campaign/K22v5` | `dd733e3792fbcd5727db244b802610a6d710b8dc` | `campaign/K22v5` | `0390a8910d72ecaa80772f3fd31a5f18a05369aa` | `tab:k22-constructs` |
| `campaign/H9-K26v3` | `856ee54b0f4ab450a6b61e3c08e045f404a79488` | `campaign/H9-K26v3` | `81bf4bea00efb922678862c90462fb3c0dfe5fda` | `tab:h9-primary` |
| `campaign/H10-K24d` | `34db1a291fff686d63402270722edf9c772bd4b6` | `campaign/H10-K24d` | `15ee150a779e5374248f8172d197b976d604416d` | superseded by K24e |
| `campaign/H10-K24e` | `e2a61ffff77f0ec393aded2c220379db1564af44` | `campaign/H10-K24e` | `a9d5e18e75ef7cf5dd8a63619f469517e13aa4af` | `tab:tail-exactness` |
| `campaign/H10-K24f` | `098e531e83d1f0b706561c1cb63672697a05ad34` | `campaign/H10-K24f` | `4ba28803c872370f2246f756f70e20d3f65179f3` | complements `tab:tail-exactness` — record-window class |

K24f needs no §2.4-style exception: it was measured on a commit reachable on
`master`, because the branch was merged first and the campaign run afterwards.
The "Engine measured" field and the reachable commit are the same SHA.

One caveat applies to reproducing K24f and to nothing else in this table. The
campaign proper — both seeds, the decision procedure run once per seed — was
measured on `098e531e…` exactly as recorded. The **mapping-gate level** was run
twice: its first run hit a defect in the apparatus's own run sizing (the horizon
ignored the accumulated logical origin, and the slot budget was confused with
ticks of the fastest stream), which surfaced as three content divergences on
plans with chained `>N`. The sizing was repaired and the level re-run, with the
human's explicit decision recorded in the campaign's `STOP.md`. A reproducer who
checks out `098e531e…` therefore gets the **pre-repair** mapping gate and will
reproduce those three divergences; the repaired apparatus is in the experiment
repository at `results_20260912_K24f/apparatus/` and in `retractordb` at
`2e9ab7d91c5528d706ac703ebd891f03a8dfd59f`. Nothing else in K24f is affected: the
corpus, the event model, the replica, the mutant set and both verdicts come from
the pinned apparatus and were not re-run.

The K24e engine tag points at the reachable commit
`ef18105701158db9986d57fd74defdda72920871`, whose `src/` tree is object-identical
to the measured `e2a61ffff77f0ec393aded2c220379db1564af44` — see §2.4. In the
table the "Engine measured" field preserves the actual provenance.

### 2.3. The three roles of the K22v5 revisions

The K22 revisions are not competing candidates for one field:

| Role | `rdb-experiment` SHA | Evidence |
|---|---|---|
| apparatus and corpus freeze | `3366f1379803f1d46db25c515b9964621372d52f` | `results_20260801_K22v5/manifest.md` |
| campaign verdict | `a9af1320c5679faf7f3746c82c3b500d65eb1541` | the commit adding the report, the results and the evidence package |
| the complete set with post-hoc analysis, and the campaign tag | `0390a8910d72ecaa80772f3fd31a5f18a05369aa` | `campaign/K22v5` |

Checking out the historical campaign uses the last revision, because it contains
the freeze, the verdict and the post-hoc analysis. The manifest preserves all
three roles.

### 2.4. The K24e exception — reachable tag versus actual measurement revision

The K24e campaign was run on `e2a61ffff77f0ec393aded2c220379db1564af44`. After a
squash merge the reachable tag was moved to
`ef18105701158db9986d57fd74defdda72920871`. The engine code tree is
object-identical:

```text
e2a61ffff77f0ec393aded2c220379db1564af44:src
  == ef18105701158db9986d57fd74defdda72920871:src
  == 5ddad0fc7d56fb9b468d31905a6689e9896ddb39
```

The metadata of the deleted revision is preserved in
`paper-arXiv/debs/k9b/e2a61ff-provenance.txt`. The differences against the squash
concern tests, not the `src/` tree.

## 3. Provenance of the paper's tables and figures

| Artifact | Campaign | Directory in `rdb-experiment` | Measurement revision |
|---|---|---|---|
| `tab:operators` | definitional | — | not applicable |
| `tab:repr` | structural | `results_20260725/` | historical oracle, no timing measurement |
| `tab:gap` | K8 survey | `paper-arXiv/debs/related_work_k8.md` | not applicable |
| `tab:tail-exactness` | K24e | `results_20260818_K24e/` | `e2a61ffff77f0ec393aded2c220379db1564af44` |
| `tab:k22-constructs` | K22v5 | `results_20260801_K22v5/` | `campaign/K22v5` and the roles in §2.3 |
| `tab:k6-primary` | K6c | `results_20260730_K6c/` | `campaign/K6c-W2-W7`, `campaign/K6c-W8-W9` |
| `tab:h9-primary` | K26v3 | `results_20260814_K26v3/` | `campaign/H9-K26v3` |
| `fig:arch` | diagram | — | not applicable |
| `fig:qrs` | ECG pipeline | `retractordb/examples/ecg/rec205` | regenerated 2026-09-02 on the pinned `8aa4ee2f…`; window pinned by `-m 1671` |

Numbers carried into the text outside the tables: 75,548 cases / 143,065,922
positions (K2/G3, `results_20260726_G3/`, `results/equivalence.json`, key
`totals`), 468,220 difference phases + 2,239,488 AGSE phases (K19,
`results_20260728_K19/`), **13 engine identity checks** (K2/G3, the oracle-to-
engine bridge, `results/engine.json`, key `cases`), and the plan and observation
counts from K24e (10,010 plans, 35,835 node observations in sample, 35,703 out
of sample).

Until 2026-08-20 those 13 checks were attributed, in the plan and in this
manifest, to K18. The attribution was wrong: what K18 contributes to that
sentence of the paper is **deterministic artifacts** (67 files compared across
two replay runs, plus six round-trip checks,
`results_20260728_K18/exactness/`), not identity checks. The number 13 itself is
correct and does not change — what changes is its source (finding K9b-F4).

## 4. Raw archives

There are 16 index files. They describe 18 archives, because the K26v3 P8 index
covers three separate families. **A clone carries all 18** — seventeen as files,
the eighteenth (`study_06_W8`) in four parts.

The "content bytes" column is the sum of the index entries' sizes, "archive
bytes" is the actual size of the compressed file, and "in git" says whether
`git clone` brings that item — because that is the only question an outsider
cares about.

| Archive | Entries | Content bytes | Archive bytes | in git | Archive SHA-256 |
|---|---:|---:|---:|:---:|---|
| `results_20260728_K4/results/raw.tar.gz` | 820 | 405526 | 65666 | yes | `407cb32400c57fdc7c9f969821de134062120bce57399ac051c6162618d79968` |
| `results_20260729_K5/results/raw.tar.gz` | 2701 | 1233361 | 85273 | yes | `975af64bc94cef2949fdfbc442866c8486deadc9acfee7bde840e35ecea99460` |
| `results_20260729_K5_rerun/results/raw.tar.gz` | 4213 | 3555141 | 194945 | yes | `cd20f8d38984ac4164a9b45a4aee601441271215ff223785b0790d2df59503dd` |
| `results_20260729_hygiene/results/raw.tar.gz` | 813 | 518514 | 139161 | yes | `340872b0f338bd92bb2ae204456eefd308b85b3047002353fc48f96ba9aeec9b` |
| `results_20260730_K6b/ablation/study_01_W2/raw.tar.gz` | 1440 | 17596571 | 8062371 | yes | `8bc8b52bda07c3e29b5e341b163587069002139fa3751c3dd81dc30d60e6e0e7` |
| `results_20260730_K6c/ablation/study_01_W2/raw.tar.gz` | 1440 | 20778051 | 9537281 | yes | `3380390d2af43c768387f0da7e8d0f0f5dfceaaa7563201c382339b04baf92ee` |
| `results_20260730_K6c/ablation/study_02_W3/raw.tar.gz` | 960 | 16516075 | 7593722 | yes | `105c211b951f06a429591a95273c2e85f08c2dc305bedf49459bc5392cd63618` |
| `results_20260730_K6c/ablation/study_03_W4/raw.tar.gz` | 960 | 11321161 | 5066701 | yes | `841a882a3dec0a83dde685ae19dd3d7996e81673b08de5cd16de012766c2d401` |
| `results_20260730_K6c/ablation/study_04_W5/raw.tar.gz` | 480 | 7323997 | 3259508 | yes | `ce46589c8c850d9eb0a538e63c93bd6bf1f27ed7453b1c6d2394b95ce99023ed` |
| `results_20260730_K6c/ablation/study_05_W7/raw.tar.gz` | 480 | 5977472 | 2712636 | yes | `3d6bf640c7a0ddbe4bb32f87dcb084cabebbf5efa119352473ba5621d684dec4` |
| `results_20260730_K6c/ablation/study_06_W8/results_20260730_K6c_study_06_W8_raw.tar.gz` | 1080 | 642032935 | 162167985 | in parts | `03f503fee2504ef46d8d5f367807442be28593f8081a487911475726609d4e51` |
| `results_20260730_K6c/ablation/study_07_W9/results_20260730_K6c_study_07_W9_raw.tar.gz` | 960 | 154719433 | 8945852 | yes | `0f0b504a0dd3f50f12ae4ef5bd60e90c2e2702215388fd84d6dc54ee06055280` |
| `results_20260730_hygiene/results/raw.tar.gz` | 813 | 533667 | 140821 | yes | `b582f33356f73bf0a4e2f200733d5cc0c8a5bd2cac2c5367f61c61db290695b5` |
| `results_20260731_hygiene/results/raw.tar.gz` | 1370 | 607518 | 163996 | yes | `42bc80319943ad697dede45e1cab78b4b9fb9ff94c0671ed66217872ca54b50f` |
| `results_20260731_hygiene220/results/raw.tar.gz` | 1371 | 623740 | 167437 | yes | `6993a2877741d65e480167a7068370b06416dee278c00f4f156c4232a205963c` |
| `artifacts/K26v3/k26v3_archives/K26v3-P8-F9-R1.tar.gz` | 27432 | — | 37667672 | yes | `8c4ac248eb8e5f91f35ca90ce61f1f3ff10eef7db58042ab62238cd349b256a3` |
| `artifacts/K26v3/k26v3_archives/K26v3-P8-F9-R2.tar.gz` | 26788 | — | 20536480 | yes | `62b065a89e82126c08f2a973195e10688bd1adfcbdb2840d5f57ea22248c0db7` |
| `artifacts/K26v3/k26v3_archives/K26v3-P8-F9-X.tar.gz` | 34298 | — | 38023659 | yes | `3deb300733f3662dd042ca0109eb73aa696c4eb5da7d8b3b62745735c94c2e04` |

The external deposit's URL/DOI remains `TBA` under decision D-2 — but it is no
longer a condition of access to the data, because the data are in the repository.

### 4.1. What changed on 2026-08-23

**Three archives previously considered absent were found** on the desktop
machine, as conjectured in the note of 2026-08-19: `study_06_W8`, `study_07_W9`
and `hygiene220`. Their mere presence was not taken as proof. For each one,
**every entry** of the `raw.index.tsv` index — path, size and SHA-256 — was
compared against the stream read out of the archive:

| Archive | Index entries | Files in archive | Mismatched | Not in index |
|---|---:|---:|---:|---:|
| `study_06_W8` | 1080 | 1080 | 0 | 0 |
| `study_07_W9` | 960 | 960 | 0 | 0 |
| `hygiene220` | 1371 | 1371 | 0 | 0 |

### 4.2. Why they went into the repository rather than into a footnote

The recovery revealed that the state found was **mixed, not consistent**. The
policy of 2026-07-31 directed every `*raw.tar.gz` outside git, but `.gitignore`
does not stop tracking what was already tracked — fifteen archives predating
that date never left the repository. A clone therefore carried 15 of the 18
items, and about the other three said only that they existed somewhere on one
machine.

The version of the manifest before this correction recorded them as "present",
which passed on the author's disk and **failed on every fresh clone** — exactly
the class of error of K9b-F5: a gate nobody ran from someone else's directory.

The decision of 2026-08-23 levels the state the other way: the three items enter
the repository (`rdb-experiment` commit `b713e1d`). `study_07_W9` (8.5 MiB) and
`hygiene220` (0.1 MiB) fit within GitHub's limits and enter directly.
`study_06_W8` (154.6 MiB) exceeds the hard 100 MB per-file limit, so it enters in
**four 45 MiB parts** alongside a `.parts.tsv` index carrying the SHA-256 of the
whole and of each part.

```bash
# reassemble the whole from the tracked parts, with verification
rdb-experiment/lib/raw_parts.sh join \
  results_20260730_K6c/ablation/study_06_W8/results_20260730_K6c_study_06_W8_raw.tar.gz
```

The assembled W8 whole deliberately stays outside git: assemblable, not stored
twice. The cost of that decision is permanent and accepted — `.git` grows by
~171 MB that gzip does not delta-compress, and every clone pulls it.

Silence is still not treated as availability. `bin/verify_pins.sh snapshot`
checks seventeen archives by checksum, the four W8 parts by checksum and size,
the presence of the parts index, and the assembled whole only if it is on disk —
without it the script prints `SKIP` with the recipe, never an error.

## 5. Known limits of this package

1. `fig:qrs` is the only item in §3 that requires a working engine, so
   `bin/reproduce_analytic.sh` reproduces it only when given `--xretractor` and
   `--xqry`; without them it reports `SKIP` together with the recipe. The window
   is pinned by the limit `-m 1671` (samples `[1271,1670]`, peaks at `x=122` and
   `x=365`) — see `REPRODUCE.md` §3.
2. All 18 raw archives are present, verified entry by entry and **in the
   repository** (2026-08-23) — see §4. A clone carries seventeen as files and the
   eighteenth in four parts; `lib/raw_parts.sh join` restores it byte for byte.
   The external deposit (D-2) has ceased to be a condition of access to the data.
3. Measurement mode does not promise identical timings. It checks the platform
   and the provenance before starting and **runs nothing**: starting a multi-day
   run is a separate, deliberate command issued to the measurement machine.
4. Run autonomy (W-1) is **verified empirically, 2026-08-23**, on the `pi400`
   measurement machine (`6.8.0-2049-raspi-realtime`), with the control channel
   actually cut — see `bin/w1_trial/README.md` and the evidence in `tables/w1/`.
   The limit that remains: what was checked is the **autonomy apparatus**, not a
   three-day K26v3 run. A trial segment lasts ~76 s, so the trial says that the
   chain survives reboots and an absent host, not that a particular campaign will
   fit inside the thermal window.
5. The DOI is not yet assigned — decision D-2: after the decision to submit the
   paper.
6. `paper-arXiv` is pinned but **unreachable for an outsider** and will stay so
   until review (D-6). There is one practical consequence: you cannot check
   whether the pinned revision of the paper corresponds to the one you are
   reading. Everything that serves the reproduction of results is public.
7. Two campaigns carry apparatus tied to the place and moment of measurement,
   which `bin/reproduce_analytic.sh` works around explicitly rather than
   silently:
   * K22v5 — `analyze.py` calls `freeze_check.sh`, a **measurement provenance**
     gate (branch `experiment/20260801_K22`, `retractordb` at `dd733e3`, two
     binaries by SHA-256). After the branch was merged the gate can no longer
     pass, and it is not needed to re-derive the table from the data. The
     provenance of analytic mode is attested by `bin/verify_pins.sh`.
   * K22v5 — `manual_hits_review.csv` stores **absolute paths** from the moment
     of the review, so `verify_hits()` passes only under
     `/home/michal/github/rdb-experiment`. `bin/analytic_k22v5.py` repeats that
     gate on paths relative to the repository root: it checks the same thing
     (every hit reviewed and confirmed) without depending on one directory
     layout (finding K9b-F3).
8. The Lean proofs are **not built by CI**. What CI checks, through
   `proof_drift`, is that the engine oracle tables are not older than the files
   they were computed from: the proofs, the generator `OracleMain.lean` and the
   three version pins. Whether the proofs compile at the pinned revision is
   answered only by proof mode (`REPRODUCE.md` §6), which needs about 7 GB for
   Mathlib. And the engine is compared with the proved model on a bounded
   parameter grid: a green `ut_proofOracle` says the implementation agrees with
   the model there, not that the implementation is proved.
