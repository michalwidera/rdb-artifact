# Reproduction guide

**This repository is the only entry point.** You do not need anything that is
not in this file; every place where you had to already "know" something is a
defect in these instructions, and we ask you to report it as an issue.

## 0. What you need

`git`, `bash`. The measurement mode additionally needs the engine toolchain
(Conan 2, CMake, Ninja, a C++23 compiler) — described in `retractordb/CLAUDE.md`.

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
| `ecg` | `fig:qrs` | 400 samples in the frame, 2 QRS complexes, peaks at x=128 and x=371 |

The 2026-08-20 run on the pinned snapshot: **eight groups out of eight**, all
comparisons against the stored files in agreement — byte for byte, with the
single exception of the G3 report, which differs only in its `- generated:`
line.

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
QRS complexes at `x=128` and `x=371`. The `x` axis runs backwards in time:
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

The only deliberately non-deterministic field of the persistent artifacts is the
range **offset 0–7** of every main `*.meta` file: an `int64_t` holding the number
of nanoseconds since the system clock's epoch at creation time, written in the
platform's native byte order. `MetaIndexStore::writeHeader()` implements it.

The comparison excludes exactly those eight bytes (`tail -c +9`). All the rest of
the `.meta` file — the gap flag, `recordCount`, the bit count and the packed
`NULL` pattern — must be identical. The `*.meta.shadow` file **has no such
header** and is compared in full. The data, `.desc`, `.shadow` and the remaining
artifacts are compared in full as well.

> **Note on a format change (post-campaign).** The description above applies to
> the engine on which the campaign was run and remains a record of its
> conditions. In the engine after 2026-09-02 the field at offset 0–7 is
> **reserved and written as zero**: the timestamp was withdrawn because no
> execution path read it. Reproducing with the current engine therefore yields
> `.meta` files that are bit-for-bit repeatable over their whole length, and
> `tail -c +9` remains a legacy step — still correct, but no longer necessary.
> The header size (8 bytes) and the entry offsets did not change, so artifacts
> from both engines stay comparable by the same procedure.

The check cannot pass on an empty set: it prints the number of files compared,
and requires an identical set of names and a non-zero count for the named
streams. The engine regression `it_replay_stability-run` requires at least 36
files and non-empty data for nine named streams; K18 compared 67 files.

## 6. Limits

See [`MANIFEST.md`](MANIFEST.md) section 5. In short: `fig:qrs` requires you to
supply a built engine, and measurement mode does not reproduce timings. All 18
raw archives are present, verified and in the repository (2026-08-23);
`study_06_W8` arrives in parts and needs one assembling command.
