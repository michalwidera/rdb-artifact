# W-1 — evidence from the autonomy trial, 2026-08-23

Products of the trial described in
[`../../bin/w1_trial/README.md`](../../bin/w1_trial/README.md).
Requirement: `paper-arXiv/debs/done/plan-realizacji-K9b.md`, Step 5 §W-1.

**Measurement machine:** `pi400`, kernel `6.8.0-2049-raspi-realtime`
(PREEMPT_RT), `isolcpus=3 nohz_full=3 rcu_nocbs=3`, `/dev/shm` tmpfs 1.8 G.
**Control host:** desktop machine, `192.168.88.21`.
**Segment workload:** 9000 rounds of a SHA-256 chain over a 1 MiB buffer,
`SCHED_FIFO` priority 80 on CPU 3. The workload is a stand-in — **no number from
here appears in the paper.**

## The main run — `cutoff/`

The control channel was cut by the worker with an `iptables DROP` rule on the
host's IP, reinstated after every boot and lifted only at `W1_COMPLETE`.

| | |
|---|---|
| start | 2026-08-23 20:40:32 CEST |
| end | 2026-08-23 20:46:29 CEST (`W1_COMPLETE`, 3/3 segments) |
| duration | 5 min 57 s |
| unattended worker reboots | **2** (after S1 and after S2) |
| sessions from the control host within the window | **0** |
| TCP probes from the host within the window | 16 × `unreachable`; `REACHABLE` only 2 s after completion |

Segment archive checksums:

| Segment | `runner.rc` | Archive SHA-256 |
|---|---:|---|
| S1 | 0 | `71d160a37c43718edb15cfaf797d7bb29746ec97e2bde4200905b7effc2d0e6b` |
| S2 | 0 | `7416bd91efda9e3ef09a56a158f21ab8cbab31f996f163e8c557c105916927c9` |
| S3 | 0 | `87562aa4ffaf700decdc9c0891388d070b61be9a5ecd0f1b67944eecaa4b6be4` |

## The negative run — `negative/`

`W1_FAIL_SEGMENT=S2`. S1 was computed and closed with an archive, the worker
rebooted itself, S2 wrote `STOP` and failed with code 8, the chain recorded
`HALT reason=stop segment=S2 rc=8` and **stopped**. `Restart=no` in the unit did
its job: no loop, no false success.

## The eight properties — where each one is visible

| # | Property | Evidence | State |
|---|---|---|---|
| 1 | the host starts and collects, nothing more | `cutoff/worker-logins.txt` — the last session from `192.168.88.21` at 20:10, before the run; `host-probe.log` | [x] |
| 2 | the `systemd` service comes up after boot | `cutoff/chain.log` — "chain start" entries at 20:42:19 and 20:44:20, with no involvement from the host | [x] |
| 3 | a chain of segments, not one process | `cutoff/timeline.tsv`, `cutoff/worker-reboots.txt` — two boots within the window | [x] |
| 4 | progress in files | `chain.log`, `RUN_COMPLETE`, `runner.rc`, `STOP`, `HALT` | [x] |
| 5 | stateless and idempotent collection | `w1_collect.sh` run twice, identical output and exit code | [x] |
| 6 | three states, not two | `complete` (cutoff, code 0), `halted` (negative, code 4), `running`/unreachable (code 3) | [x] |
| 7 | resumption belongs to the service | `w1_start.sh` on existing artifacts → code 2; `systemctl start` after a stop → the chain picked up S1 | [x] |
| 8 | remote stop with one command | `w1_stop.sh` → `is-active: inactive`, **with no `HALT`** — an operator stop does not pose as a failure | [x] |

## What this trial says, and what it does not

What was checked is the **autonomy apparatus**: that the chain survives its own
reboots, that it does not need the control host, and that it distinguishes three
terminal states. A segment lasts ~76 s, not a day, so the trial does **not** say
that a particular campaign will fit inside the machine's thermal window, or that
its timings will reproduce. That limit is recorded in `MANIFEST.md` §5, item 4.

## Two faults the trial itself exposed

1. **`chrt` without `RLIMIT_RTPRIO`.** The first run failed immediately:
   `chrt: failed to set pid 0's policy: Operation not permitted`. The service
   runs as an ordinary user, and the RT priority limit defaults to 0. Fixed by
   `LimitRTPRIO=99` in the unit plus graceful degradation on the segment side —
   a machine that refuses `SCHED_FIFO` is to keep computing and **record that**
   in `environment.tsv`, rather than die on a scheduling policy this rig does not
   study anyway. The failure was unplanned and valuable for that reason: it
   showed the `HALT` path on a real apparatus error before I checked it
   deliberately.
2. **Cutting the channel before the `settle` window.** The chain cut the host off
   before the start script had a chance to confirm `is-active`, so the start
   reported a failure for a run that was in fact getting under way. The `settle`
   window has two consumers — a human who wants to abort an unwanted start, and
   the start script — and cutting before it shut out both. Moved to after
   `settle`.
