#!/usr/bin/env bash
# One segment of the W-1 conformance chain.
#
# The workload is a deterministic CPU-bound hash chain pinned to the isolated
# CPU under SCHED_FIFO. It stands in for a real measurement segment and
# reproduces its SHAPE -- bounded work, artifacts on disk, an explicit status,
# an archive closed by its checksum -- without pretending to be one. No number
# produced here appears anywhere in the paper.
#
# Marker order is load bearing and matches K26v3: artifacts, then RUN_COMPLETE,
# then the archive, then its checksum. The checksum file is what closes a
# segment, because it can only exist after tar has been closed.
set -euo pipefail

SEGMENT="${1:?segment name}"
CPU="${2:?isolated cpu}"
OUTDIR="${3:?output directory}"
ARCHIVES="${4:?archive directory}"
CONTROLDIR="${5:?control directory}"

ROUNDS="${ROUNDS:-9000}"
W1_FAIL_SEGMENT="${W1_FAIL_SEGMENT:-}"

mkdir -p "$OUTDIR" "$ARCHIVES" "$CONTROLDIR"
log() { printf '%s [%s] %s\n' "$(date '+%F %T %Z')" "$SEGMENT" "$*"; }

status() { printf '%s\n' "$1" >"$CONTROLDIR/runner.rc"; }

# Environment of the measurement machine, recorded per segment: after a chain of
# reboots this is the only proof that every segment ran under the same
# conditions, and it is written before the work rather than after.
{
  printf 'segment\t%s\n' "$SEGMENT"
  printf 'started_utc\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'hostname\t%s\n' "$(hostname)"
  printf 'boot_time\t%s\n' "$(uptime -s)"
  printf 'kernel_release\t%s\n' "$(uname -r)"
  printf 'preempt_rt\t%s\n' "$(uname -v | grep -qi PREEMPT_RT && echo yes || echo no)"
  printf 'cpu_isolated\t%s\n' "$CPU"
  printf 'governors\t%s\n' "$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | sort -u | paste -sd, -)"
  printf 'kernel_cmdline\t%s\n' "$(cat /proc/cmdline)"
  printf 'rounds\t%s\n' "$ROUNDS"
} >"$OUTDIR/environment.tsv"

log "start, $ROUNDS rounds on isolated CPU $CPU"

# The deliberate failure path of the negative trial. It writes STOP before
# failing, so the chain can tell "stopped on purpose" from "the apparatus
# broke" -- the third of the three states W-1 property 6 asks for.
if [[ "$W1_FAIL_SEGMENT" == "$SEGMENT" ]]; then
  printf 'requested\tW1_FAIL_SEGMENT=%s\nepoch\t%s\n' "$SEGMENT" "$(date +%s)" >"$OUTDIR/STOP"
  status 8
  log "STOP requested for this segment; failing on purpose with rc=8"
  exit 8
fi

# SCHED_FIFO is used when the machine allows it and recorded when it does not.
# An unprivileged process needs RLIMIT_RTPRIO above zero (the unit sets
# LimitRTPRIO); on a machine that refuses, the segment still runs and says so,
# rather than dying on a scheduling policy that this rig does not actually test.
SCHED="none"
if chrt -f 80 true 2>/dev/null; then
  SCHED="fifo:80"
  RUNNER=(chrt -f 80 taskset -c "$CPU")
else
  RUNNER=(taskset -c "$CPU")
  log "SCHED_FIFO not permitted; running at the default policy on CPU $CPU"
fi
printf 'scheduling\t%s\n' "$SCHED" >>"$OUTDIR/environment.tsv"

rc=0
"${RUNNER[@]}" python3 - "$SEGMENT" "$ROUNDS" "$OUTDIR" <<'PY' || rc=$?
import hashlib, sys, time

segment, rounds, outdir = sys.argv[1], int(sys.argv[2]), sys.argv[3]
buf = bytes(1 << 20)
digest = hashlib.sha256(segment.encode()).digest()
started = time.monotonic()
with open(f"{outdir}/rounds.tsv", "w", encoding="utf-8") as fh:
    fh.write("round\telapsed_ns\n")
    for i in range(rounds):
        t0 = time.monotonic_ns()
        digest = hashlib.sha256(digest + buf).digest()
        # One line per round would make a 9000-line file per segment; every
        # hundredth round is enough to show the shape and keeps the archive small.
        if i % 100 == 0:
            fh.write(f"{i}\t{time.monotonic_ns() - t0}\n")
with open(f"{outdir}/result.tsv", "w", encoding="utf-8") as fh:
    fh.write("segment\trounds\tdigest\twall_seconds\n")
    fh.write(f"{segment}\t{rounds}\t{digest.hex()}\t{time.monotonic() - started:.3f}\n")
PY

if (( rc != 0 )); then
  status "$rc"
  log "workload failed rc=$rc"
  exit "$rc"
fi

status 0
printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$OUTDIR/RUN_COMPLETE"
log "RUN_COMPLETE"

tar -czf "$ARCHIVES/W1-$SEGMENT.tar.gz" -C "$(dirname "$OUTDIR")" "$(basename "$OUTDIR")"
sha256sum "$ARCHIVES/W1-$SEGMENT.tar.gz" | awk '{print $1}' >"$ARCHIVES/W1-$SEGMENT.sha256"
sync
log "archive closed: $(cat "$ARCHIVES/W1-$SEGMENT.sha256")"
