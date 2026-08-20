#!/usr/bin/env bash
# Measurement reproduction: preflight for repeating a campaign on your own
# hardware. Records the control-host environment, gates provenance, states the
# requirements the measurement machine must meet, and hands off to the
# campaign's own autonomous run scripts.
#
# This script never starts a measurement. Starting is a separate, deliberate act
# performed against the measurement machine, because a run lasts days and must
# not begin as a side effect of a preflight.
#
# Timing is NOT promised to reproduce. Different silicon, kernel and thermal
# envelope give different numbers; what reproduces is the verdict procedure
# applied to numbers measured under the recorded conditions.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="${RDB_WORKSPACE:-./artifact-workspace}"
OUT="$HERE/tables/measure"
CAMPAIGN=""
XRETRACTOR="${RDB_XRETRACTOR:-}"

usage() {
  cat <<'EOF'
Usage: ./bin/reproduce_measure.sh --campaign campaign/NAME [options]

Options:
  --campaign NAME    campaign to reproduce, e.g. campaign/H9-K26v3
  --workspace DIR    pinned checkout produced by bin/checkout.sh
                     (default: $RDB_WORKSPACE or ./artifact-workspace)
  --xretractor PATH  engine binary to gate against the campaign revision
                     (default: $RDB_XRETRACTOR; skipped when unset)
  --out DIR          where to write the environment record
                     (default: ./tables/measure)
  -h, --help         this text

Order is load-bearing: the environment is recorded and provenance is verified
BEFORE anything else. A mismatch stops the script with exit code 2.
EOF
}

fail() { echo "ERROR: $*" >&2; exit 2; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --campaign)   [ "$#" -ge 2 ] || fail "--campaign needs a value";   CAMPAIGN="$2";   shift 2 ;;
    --workspace)  [ "$#" -ge 2 ] || fail "--workspace needs a value";  WORKSPACE="$2";  shift 2 ;;
    --xretractor) [ "$#" -ge 2 ] || fail "--xretractor needs a value"; XRETRACTOR="$2"; shift 2 ;;
    --out)        [ "$#" -ge 2 ] || fail "--out needs a value";        OUT="$2";        shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

[ -n "$CAMPAIGN" ] || { usage >&2; fail "--campaign is required"; }
[[ "$CAMPAIGN" == campaign/* ]] || fail "campaign must look like campaign/NAME"
[ -d "$WORKSPACE" ] || fail "workspace not found: $WORKSPACE (run bin/checkout.sh '$CAMPAIGN' first)"
WORKSPACE="$(cd "$WORKSPACE" && pwd)"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ENVFILE="$OUT/environment-$STAMP.tsv"

# --- 1. Environment of the control host -------------------------------------
# Recorded first and unconditionally: a refused run still tells you what the
# machine looked like when it was refused.

emit() { printf '%s\t%s\n' "$1" "${2:-unavailable}" >>"$ENVFILE"; }
probe() { "$@" 2>/dev/null | head -n 1 || true; }
# Version probing folds stderr in, because ssh prints its banner there; general
# probing must not, or errors would land in the record. ssh also spells the flag
# -V, so a rejected --version falls back to it rather than recording the refusal.
version_of() {
  command -v "$1" >/dev/null 2>&1 || return 0
  local line; line="$("$1" --version 2>&1 | head -n 1 || true)"
  case "$line" in
    *"unknown option"*|*"invalid option"*|*"illegal option"*|"")
      line="$("$1" -V 2>&1 | head -n 1 || true)" ;;
  esac
  printf '%s' "$line"
}

echo "=== 1. Control-host environment ==="
: >"$ENVFILE"
emit recorded_utc "$STAMP"
emit campaign "$CAMPAIGN"
emit workspace "$WORKSPACE"
emit hostname "$(probe hostname)"
emit kernel_release "$(probe uname -r)"
emit kernel_version "$(probe uname -v)"
emit architecture "$(probe uname -m)"
emit os_release "$(. /etc/os-release 2>/dev/null && printf '%s' "${PRETTY_NAME:-}")"
emit cpu_model "$(sed -nE 's/^model name[[:space:]]*: //p' /proc/cpuinfo 2>/dev/null | head -n 1)"
emit cpu_count "$(probe nproc)"
emit kernel_cmdline "$(cat /proc/cmdline 2>/dev/null)"
emit cpu_governors "$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | sort -u | paste -sd, -)"
emit smt_control "$(cat /sys/devices/system/cpu/smt/control 2>/dev/null)"
emit dev_shm_fstype "$(findmnt -n -o FSTYPE /dev/shm 2>/dev/null)"
emit preempt_rt "$(uname -v 2>/dev/null | grep -qi 'PREEMPT_RT' && echo yes || echo no)"
for tool in python3 git gcc g++ cmake ninja conan ssh java; do
  emit "tool_$tool" "$(version_of "$tool")"
done
emit engine_binary "${XRETRACTOR:-not provided}"
[ -n "$XRETRACTOR" ] && [ -r "$XRETRACTOR" ] \
  && emit engine_binary_sha256 "$(sha256sum "$XRETRACTOR" | awk '{print $1}')"
column -t -s $'\t' "$ENVFILE" 2>/dev/null || cat "$ENVFILE"
echo
echo "Recorded: $ENVFILE"
echo

# --- 2. Provenance gate ------------------------------------------------------

echo "=== 2. Provenance gate ==="
RDB_WORKSPACE="$WORKSPACE" "$HERE/bin/verify_pins.sh" "$CAMPAIGN" >"$OUT/verify_pins-$STAMP.log" 2>&1 \
  || { cat "$OUT/verify_pins-$STAMP.log" >&2; fail "workspace does not match $CAMPAIGN; refusing to prepare a run"; }
echo "OK    workspace matches MANIFEST.md for $CAMPAIGN"

ENGINE_REV="$(git -C "$WORKSPACE/retractordb" rev-parse HEAD)"
emit campaign_engine_revision "$ENGINE_REV"
if [ -n "$XRETRACTOR" ]; then
  "$HERE/bin/verify_binary.sh" "$ENGINE_REV" "$XRETRACTOR" \
    || fail "engine binary does not come from $ENGINE_REV; refusing to prepare a run"
else
  echo "SKIP  engine binary not gated: pass --xretractor once the engine is built"
  echo "      (build it from $WORKSPACE/retractordb, which is pinned to $ENGINE_REV)"
fi
echo

# --- 3. Platform requirements ------------------------------------------------

echo "=== 3. Platform requirements ==="
echo "Control host (this machine) -- it only starts the run and collects results:"
for tool in git python3 ssh; do
  command -v "$tool" >/dev/null 2>&1 && echo "  OK    $tool present" || fail "control host needs $tool"
done
echo
echo "Measurement machine -- NOT checked from here, and deliberately so: it is a"
echo "separate machine and its state is gated on the machine itself by the"
echo "campaign's own scripts. It must provide:"
cat <<'EOF'
  - PREEMPT_RT kernel
  - cpufreq governor 'performance' (it reverts to 'ondemand' across reboots,
    so the chain re-applies it after every boot)
  - one isolated CPU for the measured process, background work on the others
  - SCHED_FIFO capability on the engine binary
  - /dev/shm as tmpfs, holding all working data (nothing is written to the
    code repository during a run)
  - passwordless sudo for systemctl, so the chain can reboot itself unattended
EOF
echo

# --- 4. Handoff to the campaign's autonomous run scripts ---------------------

echo "=== 4. Starting the run (W-1: the control host may be switched off) ==="
CAMPAIGN_DIR=""
case "$CAMPAIGN" in
  campaign/H9-K26v3) CAMPAIGN_DIR="results_20260814_K26v3" ;;
  campaign/H10-K24e) CAMPAIGN_DIR="results_20260818_K24e" ;;
  campaign/H10-K24d) CAMPAIGN_DIR="results_20260807_K24d" ;;
  campaign/K22v5)    CAMPAIGN_DIR="results_20260801_K22v5" ;;
  campaign/K18)      CAMPAIGN_DIR="results_20260728_K18" ;;
  campaign/K6c-*)    CAMPAIGN_DIR="results_20260730_K6c" ;;
esac
[ -n "$CAMPAIGN_DIR" ] || fail "no campaign directory mapped for $CAMPAIGN"
RUNDIR="$WORKSPACE/rdb-experiment/$CAMPAIGN_DIR"
[ -d "$RUNDIR" ] || fail "campaign directory missing in the checkout: $RUNDIR"
echo "Campaign scripts: $RUNDIR"
echo

if [ "$CAMPAIGN" = "campaign/H9-K26v3" ]; then
  cat <<EOF
This campaign carries the reference autonomous harness. Multi-day runs must not
require the control host to stay powered on, so the run is a chain of segments
driven by a systemd unit on the measurement machine:

  1. start once, from here:
       WORKER_SSH=user@measurement-host $RUNDIR/start_matrix_p8.sh
     It gates the host, installs the unit and starts the first family. After it
     returns, this machine has no role and may be switched off.

  2. the unit survives reboots (WantedBy=multi-user.target) and the chain
     reboots the measurement machine between families by itself.

  3. progress is visible in files, not in process memory: an appended run log,
     RUN_COMPLETE per segment, runner.rc for segment status, STOP-* markers.
     Three distinct states -- still running, finished, stopped with an error.

  4. collect whenever you like, any number of times, including only after the
     whole measurement; collection is not a precondition for progress:
       WORKER_SSH=user@measurement-host $RUNDIR/collect_p8_archives.sh

  5. to stop remotely:
       ssh user@measurement-host sudo systemctl stop k26v3-p8.service

Resumption belongs to the unit, not to the start script: starting always starts
from zero and refuses to overwrite existing state.
EOF
else
  cat <<EOF
This campaign predates the autonomous harness and its runner expects an
attended session. Before repeating it unattended, port it onto the K26v3
pattern in results_20260814_K26v3 (start_matrix_p8.sh, install_worker_service.sh,
run_matrix_chain.sh, collect_p8_archives.sh) rather than inventing a new one.

Read $RUNDIR/README.md for the campaign's own run procedure.
EOF
fi

echo
echo "RESULT: preflight passed; nothing was started."
echo "Environment record: $ENVFILE"
