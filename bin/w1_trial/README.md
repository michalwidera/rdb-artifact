# W-1 — run-autonomy conformance trial

This directory checks **empirically** requirement W-1 of
`paper-arXiv/debs/done/plan-realizacji-K9b.md`, Step 5: *a multi-day run must not
require the control host to stay powered on for that whole time*.

The W-1 criterion is empirical, not declarative. Writing down "the script does
not need the host" without a trial does not count as satisfying it — the same
principle as with the negative check of the SHA gate.

## What this is, and what it is not

This is an **apparatus** trial, not a measurement. The segment workload is a
deterministic hash chain pinned to an isolated CPU under `SCHED_FIFO`. It
reproduces the **shape** of a measurement segment — bounded work, artifacts on
disk, an explicit status, an archive closed with a checksum — and nothing more.
**No number from here appears in the paper.**

The pattern is not newly invented. It is carried over from the battle-tested
`rdb-experiment/results_20260814_K26v3/`:

| Here | K26v3 P8 counterpart |
|---|---|
| `w1_install_worker_service.sh` | `install_worker_service.sh` |
| `w1_run_chain.sh` | `run_matrix_chain.sh` |
| `w1_run_segment.sh` | `run_matrix_family.sh` |
| `w1_start.sh` | `start_matrix_p8.sh` |
| `w1_collect.sh` | `collect_p8_archives.sh` |

There is one difference, and it is deliberate: a segment takes minutes rather
than a day, so the whole chain of three segments with two reboots fits inside a
quarter of an hour. That lets properties 1–8 be checked in a single session
instead of over three days.

## The eight W-1 properties and where each one is visible

| # | Property | Mechanism | Evidence in files |
|---|---|---|---|
| 1 | the host starts and collects, nothing more | `w1_start.sh` returns and hands the machine over | `worker-logins.txt` — zero sessions from the host within the run window |
| 2 | the run is driven by `systemd` on the worker | a unit with `WantedBy=multi-user.target` | `chain.log` — entries after every boot |
| 3 | a chain of segments, not one process | `systemctl --no-block reboot` between segments | `worker-reboots.txt`, `timeline.tsv` |
| 4 | progress in files, not in process memory | `chain.log`, `RUN_COMPLETE`, `runner.rc`, `STOP`, `HALT` | those files |
| 5 | stateless and idempotent collection | `w1_collect.sh` writes nothing on the worker | repeated calls produce the same result |
| 6 | an unambiguous completion signal, three states | `W1_COMPLETE` / absent / `HALT` | `w1_collect.sh` prints `STATE:` |
| 7 | resumption belongs to the service, not to the start script | `w1_start.sh` refuses when artifacts already exist | exit code 2 with a message about `systemctl start` |
| 8 | remote stop with one command | `w1_stop.sh` | `systemctl is-active` after the stop |

Property 6 requires **three** states, so the third is checked by a separate
negative run: `W1_FAIL_SEGMENT=S2` makes the segment write `STOP` and fail. The
chain must then record `HALT` and **stop**, rather than loop — that is what
`Restart=no` in the unit is for.

## Cutting the control channel

Property 1 says the host may be switched off. Checking that by taking one's
hands off the keyboard proves only that nobody reached for it — not that
reaching for it was unnecessary. The channel is therefore **cut**, in one of two
ways:

* **on the host side** — a `DROP` rule on the worker's IP; this requires
  passwordless `sudo` on the host. `CUT_HOST_IP` is then left empty;
* **on the worker side** — `CUT_HOST_IP=<host ip>`; the chain installs the `DROP`
  after every boot, at the same place where it sets the governor.

The worker-side variant has two independent escape hatches, because locking
oneself out of the measurement machine is the one failure this rig cannot afford:
the rules **are not persistent**, so every reboot restores connectivity by
itself, and in addition a transient `systemd-run --on-active` timer removes them
even if the chain dies before its own cleanup. The `cutoff-deadline` file sets
the moment after which the chain stops reinstating the rule.

Physically switching the host off is of course stronger and needs neither
variant. The rig then does not need them — `CUT_HOST_IP` empty, `sudo`
untouched.

## The procedure

```bash
# 1. negative trial -- the third state of property 6
W1_FAIL_SEGMENT=S2 ./w1_start.sh
./w1_collect.sh                      # STATE: halted, code 4

# 2. cleanup after the negative trial (deliberate, not automatic)
ssh michal@192.168.88.13 'sudo -n systemctl disable k9b-w1.service; rm -rf ~/w1_out ~/w1_archives ~/w1_control'

# 3. the main run with the channel cut
CUT_HOST_IP=192.168.88.21 ./w1_start.sh
./w1_collect.sh                      # STATE: worker unreachable, code 3 -- this is the expected answer
# ... after completion ...
./w1_collect.sh                      # STATE: complete, code 0
```

The evidence lands in `rdb-artifact/tables/w1/`.

## `w1_collect.sh` exit codes

| Code | Meaning |
|---|---|
| 0 | `complete` — the chain finished, the archives were collected |
| 3 | `running`, or the worker is unreachable — the run is in progress |
| 4 | `halted` — stopped with an error, awaiting a human decision |
