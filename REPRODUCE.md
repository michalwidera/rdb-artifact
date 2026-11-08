# Reproduction guide

**This repository is the only entry point.** You do not need anything that is
not in this file; every place where you had to already "know" something is a
defect in these instructions, and we ask you to report it as an issue.

## 0. What you need

`git`, `bash`. The measurement mode additionally needs the engine toolchain
(Conan 2, CMake, Ninja, a C++23 compiler) — described in `retractordb/CLAUDE.md`.
Proof mode (§6) needs no toolchain of its own: its installer fetches Lean 4 and
Mathlib.

The analytic path from the reviewer mirror (§3, *Without git: from the reviewer mirror*) needs neither `git` nor `curl`: bash 4 or later, python3 3.8 or later, the usual POSIX tools and 100 MB of free space.

Remeasuring the deterministic quantities (§3, *Without a compiler: remeasuring the deterministic quantities*) needs no `git` and no toolchain either: the same tools, Linux on x86_64 or aarch64 with glibc 2.38 or later, 500 MB of free space and about 70 minutes.

## 1. Fetching the pinned set of repositories

```bash
git clone https://github.com/michalwidera/rdb-artifact.git
cd rdb-artifact
./bin/checkout.sh ./artifact-workspace
```

The script clones the five repositories **separately**, into an explicit layout,
and checks them out at the full SHAs of the manifest's default snapshot. There
are no submodules here. The snapshot uses the engine's current HEAD because it
carries critical tooling fixes.

Auditing a campaign's historical layout is a separate mode:

```bash
./bin/checkout.sh ./historical-workspace campaign/H10-K24e
```

Do not use that mode as the default environment for a new measurement. It
preserves the campaign's actual provenance, not the current tooling.

**K24f differs from every other campaign in this package and the difference is
not optional.** Its corpus is **not** the frozen H10 corpus: the record-window
stratum is opt-in, so the campaign must be invoked as

```bash
python3 run_campaign.py --seed 20260912 --count 10010 --with-window \
        --xretractor <engine> --out h10_20260912.csv
python3 decision_rule.py --raw h10_20260912.csv --out VERDICT.md \
        --seed 20260912 --engine 098e531
```

Without `--with-window` the run reproduces the nine-class K24e corpus and the
tenth class simply is not there — the result looks green and answers a different
question. The same flag applies to `run_mapping_gate.py`.

One further caveat, stated in `MANIFEST.md` §2.2 and repeated here because this
is the file a reproducer reads first: the mapping-gate level must be run with the
**repaired** apparatus, which is in the experiment repository under
`results_20260912_K24f/apparatus/`, not with the apparatus of the pinned engine
commit. The pinned commit carries the pre-repair run sizing and will reproduce
three content divergences whose cause is the apparatus, not the engine. The
campaign proper — both seeds and the decision procedure — is unaffected and
reproduces from the pinned commit as recorded.

## 2. Pin verification — run this before anything else

```bash
RDB_WORKSPACE=./artifact-workspace \
RDB_XRETRACTOR=./artifact-workspace/retractordb/build/Debug/src/retractor/xretractor \
./bin/verify_pins.sh snapshot
```

The script starts with section 0: **whether the three declarations of the same
pin agree** — `MANIFEST.md`, `verify_pins.sh` and `checkout.sh` each hold them
separately, so a bump that reached only some of them stops the gate instead of
travelling along with it. It then checks the actual `HEAD` of the four required
checkouts, the tags and their reachability, the K24e `src/` tree equivalence
proof, seventeen archives by SHA-256, the four parts of the `study_06_W8`
archive together with its index, and — when `RDB_XRETRACTOR` is given — the
revision embedded in the binary. The fifth checkout, `paper-arXiv`, is
**optional** (decision D-6): when it is absent the script prints `SKIP` with the
pinned SHA, because the paper repository stays private until review and no
reproduction mode reads it.
A non-zero exit code means a divergence — **do not continue**.

The binary check compares the seven-character SHA prefix that `xretractor --help`
currently publishes against the full SHA the manifest expects. That is the limit
of the existing binary's metadata; the script does not pretend to check all 40
characters.

The raw-archive inventory is an invariant of the **snapshot** and is checked only
in `snapshot` mode. In campaign mode the checkout sits on an older revision on
which the later archives do not yet exist, so checking them there would report
absence as corruption — the script prints `SKIP` with a pointer to `snapshot`
mode (finding K9b-F5).

## 3. Analytic mode — regenerating the tables and figures

```bash
./bin/reproduce_analytic.sh --workspace ./artifact-workspace
```

One command, eight groups, no engine and no measurement hardware. The script
first calls `verify_pins.sh` and **refuses to regenerate anything** if the
workspace does not match the manifest. Then, group by group, it runs each
campaign's own frozen analysis code over the data sitting in the pinned
checkout, writes the products under `tables/<group>/` and prints **counts**
rather than the word "OK" — a check that cannot say how much it compared is not
a check. Every product is additionally compared against the version stored in
git.

| Group | Artifact | Counts reported by the script |
|---|---|---|
| `k6c` | `tab:k6-primary` | 780 runs, 13 cells, classes A/B/C = 0/12/1 |
| `k22v5` | `tab:k22-constructs` | 45 constructs, 1764 reviewed hits, 36 modification rows |
| `k24e` | `tab:tail-exactness` | 10,010 plans, 35,835 / 35,703 observations, 9/9 exact classes for tail and origin |
| `k26v3` | `tab:h9-primary` | 3/3 supporting families, 22 gate rows |
| `g3` | 75,548 / 143,065,922 | 0 mismatches, 10 mutations, 13 engine identity checks |
| `k19` | 468,220 / 2,239,488 | 4 mutations, verdict OK |
| `k18` | deterministic artifacts | 67 files compared, 16 `.meta` after skipping the header field, 51 byte-identical, 6 round-trip checks |
| `ecg` | `fig:qrs` | 400 samples in the frame, 2 QRS complexes, peaks at x=122 and x=365 |

The 2026-09-13 run on the pinned snapshot, from a fresh checkout: **eight groups
out of eight**, all comparisons against the stored files in agreement — byte for
byte, with the single exception of the G3 report, which differs only in its
`- generated:` line. A group counts as failed when any of its steps fails, not
only its last one (fixed on the same day; `MANIFEST.md` §2.1).

Seven groups need no engine. The eighth, `ecg`, does: pass it `--xretractor` and
`--xqry`; without them it reports `SKIP` and prints the recipe. The binary is
gated there exactly as in measurement mode — the figure is meant to come from
the pinned engine, not from whatever happens to sit on `PATH`.

K18 is the one group whose products are frozen measurement output from engine
`bc37186` rather than something this script recomputes, so they are copied
verbatim and their markers are in Polish. The originals are kept as the
evidence — a measurement record is not rewritten in order to translate it — and
an English rendering is written beside each one as `*.en.txt` / `*.en.md`. The
counts are parsed from the original, never from the rendering.

The workspace is **single-use** and some of the frozen scripts write next to
their inputs; the script reports how many files each group touched in it, and
never writes outside the workspace.

### Without git: from the reviewer mirror

The mirrors are snapshots without `.git`, so the commands above cannot run on them: `verify_pins.sh` asks git which commit a directory is, and the stored products are read with `git show`. The path for a snapshot is one command, run from the extracted ZIP of the `retractordb-artifact` mirror (or from a clone of this repository):

```bash
bash bin/review.sh                          # inputs from the experiment mirror
bash bin/review.sh --workspace ./artifact-workspace   # the same check on pinned clones
```

Options: `--dest DIR` holds the fetched inputs and the regenerated products (default `./review-workspace`); `--report FILE` names the report (default `./review-report.md`); `--workspace DIR` uses clones made by `bin/checkout.sh` instead of the mirror and must give the same verdict. `--source DIR` replaces the mirror service with a local directory and serves only the author's checks. `bash bin/review.sh --help` prints the full text.

What the run does:

* **Prerequisites.** bash 4 or later, python3 3.8 or later, the POSIX tools it names, 100 MB of free space; a missing one ends the run with exit status 2 before anything is fetched.
* **Inputs.** `bin/fetch_mirror.sh` asks the experiment mirror for each file listed in [`INPUTS.tsv`](INPUTS.tsv) singly, without listing directories, and keeps it only if it passes its check: `exact` (the SHA-256 of the blob at the pin), `gz` (a text of 1.2 MB or more, which the mirror refuses; its `.gz` copy is fetched and must decompress to the blob) or `masked` (a file the mirror rewrites because it carries identifying terms or links: the same number of lines and the declared SHA-256 of the lines without `XXXX`). A file that fails is kept beside its target as `<name>.rejected` and named with its reason: `missing`, `truncated`, `redacted`, `differs` or `http-<code>`. At the current pin the list has 83 inputs, about 8 MB.
* **Pacing.** The service allows about 175 requests per 15 minutes from one address and reports its budget in `ratelimit-*` headers; the script paces itself by them and waits out HTTP 429. An interrupted run resumes: inputs already in `--dest` that verify are not fetched again.
* **Regeneration.** `bin/reproduce_analytic.sh --snapshot` runs the groups of the table above over the fetched inputs. The stored products are copied before the groups run and the regenerated ones are compared with that copy byte for byte (the G3 report modulo its `- generated:` line), touched files are counted by checksum, and the engine revision is read from `MANIFEST.md`. The `ecg` group is always `SKIP` on this path: `fig:qrs` needs the engine's example data and a built engine, which means a clone (see *The `fig:qrs` window* below).
* **Verdict.** PASS requires every input verified, seven groups regenerated with their stored products identical, and every `COUNT` line equal to the `# expect` line of `INPUTS.tsv`. Exit status 0 is PASS, 1 is FAIL; `review-report.md` lists the pins, each group with its counts, and what failed.

The steps can also be run one by one: `bash bin/fetch_mirror.sh --dest DIR` fetches and verifies, `bash bin/fetch_mirror.sh --check --dest DIR` verifies an existing directory without the network, and `bash bin/reproduce_analytic.sh --snapshot --workspace DIR` regenerates from it.

`INPUTS.tsv` is generated, not written: `bin/make_inputs.sh` derives it from a traced run of this script on clean pinned clones, and `bin/move_pin.sh --apply` renews it whenever a pin moves (`REVIEW_MIRROR.md`, *Moving a pin*). Do not edit it by hand.

### Without a compiler: remeasuring the deterministic quantities

The analytic path regenerates the tables from stored measurements and measures nothing. `--remeasure` measures again, on your machine, the quantities of the paper that follow from the plan and the input and not from the platform, and compares each with the stored result exactly. The engine comes from prebuilt bundles (`MANIFEST.md` §7), so the run needs neither git nor a compiler:

```bash
bash bin/review.sh --remeasure                         # inputs and bundles from the mirrors
bash bin/review.sh --remeasure --workspace DIR         # the same on pinned clones
```

With `--workspace`, DIR holds the clones of `bin/checkout.sh` and, next to them, a clone of `rdb-binaries` at its `MANIFEST.md` pin (`bin/checkout.sh` does not make it). The options are those of the analytic path; the report defaults to `./remeasure-report.md`.

What is measured, group by group (`bin/reproduce_remeasure.sh`):

| Group | Quantity | Compared with |
|---|---|---|
| `bundles` | the four bundles of this architecture | SHA-256 of `MANIFEST.md` §7, engine pin in every binary, `--build-info` equal to the profile row |
| `plans` | 84 plan dumps of the H9 corpus and 4 rejected controls (`validate_corpus.py`) | `corpus_validation/` of R593 H9, byte for byte; the logs without their `COMPILE_NS` line and temporary directory |
| `p6` | 4 profiles x 21 plans on the main data (`run_main_rdb.sh`, unchanged): LOGICAL write bytes per public record, the WORK counter, the public artifacts | the stored tree `artifacts/R593/r593_gates_rdb.tar.gz` (pi400), 4604 files byte for byte |
| `gates` | `corpus_validity`, `oracle_mutants`, `public_identity`, `near_miss_controls`, `no_materialization`, three families; reduction at Q=8 | clean; reduction within the predeclared tolerance (1/2, 1/2, 7/12 +- 0.005) |
| `mechanism` | substrates, R1/R2 and counters of the Q grid, 72 RDB rows | RDB rows of `results_20260814_K26v3/matrix/mechanism.tsv`; its Flink rows are taken from that record and not measured again |
| `k24` | tail accounting on 10 010 plans, K24e and K24f, two seeds each | the stored raw CSV and `VERDICT*.md`, byte for byte |
| `ecg` | records and bytes of `ecg_raw` and `qrs_ship` at 100/200/300/500 s, tail deficit 59 (`examples/ecg/rec205_h10`) | the values pinned in `bin/reproduce_remeasure.sh`, measured for the paper |

How it differs from the analytic path:

* **Bundles before anything else.** A bundle whose SHA-256, revision or switches differ from the declaration stops the run before the first measurement, and the report names which of the three it was. The SHA-256 proves which bundle ran, not that it was built from the pinned sources; that proof stays the build from source of §4.
* **One provenance query replaced.** The H9 gate `corpus_validity` asks git for the engine revision. Here the driver gives it the engine pin after the bundles group has established it, and changes nothing else in the apparatus. Every apparatus file runs from a working copy, so the fetched inputs stay as fetched.
* **Time.** `p6` and `ecg` are paced in real time and take about 45 and 20 minutes on any machine; `k24` takes minutes. Timing is not measured and not compared. No other `xretractor` may run during the run, because `run_main_rdb.sh` refuses to start next to one.
* **Requirements.** Linux on x86_64 or aarch64 with glibc 2.38 or later and the libstdc++ of GCC 14 or later (Debian 13, Ubuntu 24.04), bash 4, python3 3.8, the POSIX tools the script names, and 500 MB of free space. The inputs are `REMEASURE.tsv`: the apparatus and stored results from the experiment mirror, the example data from the engine mirror, and the bundles of both architectures from the binaries mirror (the run uses the four of its own): 266 inputs at the current pin, about 48 MB in at least 266 requests, so the pacing of the analytic path waits out the 15-minute window at least once.
* **Flink.** The Flink side of H9 is not run: it needs a JDK and a Flink image of several hundred MB. Its plan counts come from the stored record, as the `mechanism` row says.

`REMEASURE.tsv` is generated like `INPUTS.tsv`: `bin/make_inputs.sh --remeasure` traces this run on pinned clones, and accepts the new list only after `bin/review.sh --remeasure` has passed on a simulated mirror with a `PATH` that has no git, no compiler and no cmake.

### The `fig:qrs` window

The recipe `xqry -s qrs_out -p 400,400` fixes the window's **size** (400 samples)
but not its **position**: the plot scrolls and shows whatever happened to be
passing when you stopped looking. The 2026-07-14 figure was produced at an
unrecorded moment and therefore could not be reproduced — that was finding
K9b-F2.

The position is fixed by the element limit. The rule adopted on 2026-08-20:

```bash
cd retractordb/examples/ecg/rec205
xretractor rec205-qrs.rql -r -k -x -m 1671
xqry -w -s qrs_out -p 400,400 -m 1671 | gnuplot
```

The final frame is always samples `[1271,1670]` of the `qrs_out` stream, with
QRS complexes at `x=122` and `x=365`. Until 2026-09-13 this said `x=128` and
`x=371`: the client then lost the rows computed before it subscribed, so its
frame ended six records late. The engine's values did not change — see
`MANIFEST.md` §2.1. The `x` axis runs backwards in time:
`x=0` is the most recent sample. The script checks this property numerically —
400 samples in the frame, two complexes, peaks at the pinned positions within a
tolerance of 3 samples — so swapping the data or the engine stops the group
instead of quietly drawing something else.

**Comparison with the July figure:** the morphology is unchanged. The same
signal shape, the same envelope, the same detection pulses in the same places,
the same amplitude scale. Only the window position differed. This is therefore
not a finding that changes any number in the paper under the scope-freeze rule.

## 4. Measurement mode — repeating the measurements

```bash
./bin/reproduce_measure.sh --campaign campaign/H9-K26v3 \
  --workspace ./artifact-workspace --xretractor /path/to/xretractor
```

Repeating a campaign on your own hardware. The order is binding: the script
first records the control host's environment into
`tables/measure/environment-*.tsv` (kernel, PREEMPT_RT, CPU model and count,
governors, SMT, `cmdline`, `/dev/shm` type, toolchain versions, SHA-256 of the
binary), then checks provenance — `verify_pins.sh` for the selected campaign and
`verify_binary.sh` for the binary — and only then prints the start recipe.
**A mismatch stops the script with exit code 2 and nothing is started.** The
environment is recorded even then, because a refusal is also information about
the machine.

The deterministic quantities of the paper (write bytes, counters, substrate counts, gates, tail accounting, the ECG traffic ratio) need none of this: §3, *Without a compiler: remeasuring the deterministic quantities*, measures them again with prebuilt binaries. This mode is for the timings.

The script **starts nothing**. A run takes days and must not begin as a side
effect of a preflight check; starting it is a separate command issued to the
measurement machine. Timings are **not promised**: what is reproduced is the
verdict procedure applied to numbers measured under recorded conditions, not the
numbers themselves.

### Run autonomy — a requirement, not a convenience

This project's campaigns take **days** (K26v3 P8: three). Reproduction must not
require the control host to stay powered on for that whole time — this is a
feasibility condition, not a comfort. Measurement mode implements the pattern
proven in K26v3 P8 (`rdb-experiment/results_20260814_K26v3/`):

* the control host **starts and collects**; between those two it may be switched
  off and the run does not suffer;
* the run is driven by a **`systemd` service on the measurement machine** that
  comes up after boot, so it survives a restart and a power loss;
* a long run is a **chain of segments**, not a single process; between segments
  the measurement machine reboots itself;
* **progress is visible in files**, not in process memory: an appended log, a
  segment-completion marker, a segment status, a stop marker;
* the **collection script is stateless and idempotent** — it may be run at any
  time and any number of times, including only after the whole measurement;
* completion has an **unambiguous signal**, distinguishable from "still
  computing" and from "aborted with an error";
* the run can be **stopped remotely with one command**.

In practice this means supervision comes down to reading the state periodically
by hand — every few hours or once a day, whichever suits.

**Verified empirically on 2026-08-23, not merely written down.** `bin/w1_trial/`
carries this pattern over to a shortened run and executes it on the `pi400`
measurement machine with the control channel **actually cut**: three segments,
two unattended worker reboots, `W1_COMPLETE` after 5 min 57 s, zero sessions from
the control host within the run window. A negative run (`W1_FAIL_SEGMENT`)
confirmed the third state — `HALT` and a stop instead of a loop. Evidence:
`tables/w1/`; the description and the map of the eight properties:
[`bin/w1_trial/README.md`](bin/w1_trial/README.md).

## 5. What is deliberately non-deterministic

**On the pinned engine: nothing.** The `.meta` header — the range **offset 0–7**
of every main `*.meta` file — is a reserved `int64_t` written as zero by
the file-local `writeHeader()` in `src/rdb/lib/metaIndexStore.cc`, reached
through `MetaIndexStore::saveHeader()` and `MetaIndexStore::rewrite()`. Every
persistent artifact a reproduction produces is therefore bit-for-bit repeatable
over its whole length.

The comparison still excludes exactly those eight bytes (`tail -c +9`). That is
now a legacy step rather than a necessity, and it is kept for one reason: it is
the boundary the recorded campaigns used, so keeping it lets artifacts from
before and after the change be compared by one procedure. Everything else — the
gap flag, `recordCount`, the bit count and the packed `NULL` pattern — must be
identical. The `*.meta.shadow` file **has no such header** and is compared in
full. The data, `.desc`, `.shadow` and the remaining artifacts are compared in
full as well.

> **How this looked during the campaigns.** Until 2026-09-02 those eight bytes
> held the number of nanoseconds since the system clock's epoch at file
> creation, in the platform's native byte order — the one deliberately
> non-deterministic field of the persistent artifacts, and the reason the
> comparison boundary exists at all. The field was withdrawn because no
> execution path read it. The campaigns of `MANIFEST.md` §2.2 were measured
> before the withdrawal, so their stored artifacts still carry a timestamp
> there; the header size (8 bytes) and the entry offsets never changed, which is
> what keeps the two comparable.

The check cannot pass on an empty set: it prints the number of files compared,
and requires an identical set of names and a non-zero count for the named
streams. The engine regression `it_replay_stability-run` requires at least 36
files and non-empty data for nine named streams; K18 compared 67 files.

## 6. Proof mode — checking the Lean formalization

The engine snapshot carries a Lean 4 formalization of the stream-rate operators
in `retractordb/math_proofs/`: interleaving as a sequential covering,
deinterleaving and its exact inversion over the rationals, the event-order
counterexample, sum commutativity, rate-matched shift and the exact interleave
tail. `math_proofs/README.md` lists which statement lives in which file.

```bash
cd artifact-workspace/retractordb/math_proofs
./install-lean.sh --no-upgrade-check   # elan, the pinned Lean, Mathlib cache, pandoc, TeX Live
./render.sh                            # expect the last line: DOWODY: OK
```

`--no-upgrade-check` keeps the versions pinned in `lean-toolchain`, `lakefile.lean`
and `lake-manifest.json`; without it the installer offers a newer Lean/Mathlib,
which is not the checked configuration. `render.sh` builds with `--wfail`, so a
`sorry` (which Lean reports only as a warning) fails the run just like an error,
and prints `DOWODY: BLAD`. The products — HTML, plain text and a PDF — are
written under `math_proofs/build/verso/`.

What this costs: about 7 GB for Mathlib and its downloaded build cache, and a
Debian/Ubuntu host for the TeX Live packages the installer adds with `apt-get`.
Checking the proofs needs no engine build; the engine comparison below does.

**What the proofs establish, and what they do not.** The theorems are about a
mathematical model of the operators, not about the C++ code. The link to the
engine is differential: `math_proofs/gen-oracle.sh` evaluates the model's
definitions into `test/UnitTest/proofOracle.hpp`, and `ut_proofOracle` compares
the functions in `SOperations.hpp` against those tables on a **bounded grid**
(for interleaving, `a, b` in 1..11 and `n` below 48) and checks theorem
statements as properties there. Logical origins, intervals, shift tails and the
sample index of stream sum are computed by the compiler and by `dataModel`, so
for those theorems the test compiles a small plan from RQL, runs it and compares
the result with the model on bounded horizons. That is testing against a
checked model, not a verification of the implementation.

```bash
ctest --test-dir artifact-workspace/retractordb/build/Debug -R 'proof_drift|ut_proofOracle'
```

`proof_drift` needs no Lean, which is why it also runs in CI. It fails when a
theorem has no row in `test/proof_manifest.tsv`, and when the oracle tables are
older than any file they depend on — the proofs, the generator and the three
version pins. A green CI run therefore says the tables match the proofs as
committed; only `render.sh` says the proofs compile. The per-theorem coverage is
in [`MAP.md`](MAP.md), *Formal proofs*.

## 7. Limits

See [`MANIFEST.md`](MANIFEST.md) section 5. In short: `fig:qrs` requires you to
supply a built engine, and measurement mode does not reproduce timings. The
remeasurement from prebuilt bundles (§3) repeats the deterministic quantities
exactly, but the bundles' provenance is declared by their SHA-256, not proved;
the proof is a build from the pinned sources. All 18
raw archives are present, verified and in the repository (2026-08-23);
`study_06_W8` arrives in parts and needs one assembling command.

If you work from the anonymized mirror of the experiment repository rather than
a clone: the raw K24-series campaign CSV files of 1.2 MB or more (for example
`results_20260818_K24e/raw/campaign_seed20260818.csv`) cannot be opened there,
and the whole-repository ZIP stops before reaching them. Take the `.csv.gz`
copy beside each one; `gunzip` restores the original byte for byte. A clone
carries both and needs neither step. Details in `REVIEW_MIRROR.md`, step 2.

`bin/review.sh` takes those `.gz` copies by itself and checks both the archive and its decompressed content (§3, *Without git: from the reviewer mirror*).
