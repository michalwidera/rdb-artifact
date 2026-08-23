#!/usr/bin/env bash
# W-1 conformance chain on the measurement machine, started only by systemd.
#
# One invocation handles EXACTLY ONE segment: it picks the first segment without
# a closing marker, runs it, and then asks the machine to reboot. The unit is
# enabled on multi-user.target, so after the reboot systemd starts it again and
# the chain moves on. A power cut is therefore indistinguishable from a planned
# reboot between segments -- one code path, not two. The control host is needed
# for nothing in between.
#
# Restart=no in the unit is deliberate: a STOP marker or an apparatus failure
# must stop the chain, not spin it. A stop leaves a HALT file that blocks every
# later entry until a human decides.
#
# This is a HARNESS trial, not a measurement: the segment workload is a
# deterministic CPU-bound placeholder. Nothing here reproduces a number in the
# paper. What it tests is the eight autonomy properties of W-1.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEGMENTS=(S1 S2 S3)

CPU="${CPU:-3}"
TRIAL_DIR="${TRIAL_DIR:-$HERE}"
W1_OUT="${W1_OUT:-/home/michal/w1_out}"
ARCHIVES="${ARCHIVES:-/home/michal/w1_archives}"
CONTROL="${CONTROL:-/home/michal/w1_control}"
SEGMENT_SCRIPT="${SEGMENT_SCRIPT:-$HERE/w1_run_segment.sh}"
UNIT="${UNIT:-k9b-w1.service}"
SUDO="${SUDO:-sudo -n}"
ROUNDS="${ROUNDS:-9000}"
W1_FAIL_SEGMENT="${W1_FAIL_SEGMENT:-}"
# Control-channel cut-off. Empty means the host severs the channel itself (or a
# human unplugs it); non-empty means the worker does it, which is the only
# variant available when the control host has no passwordless sudo.
CUT_HOST_IP="${CUT_HOST_IP:-}"
CUTOFF_WATCHDOG_SECONDS="${CUTOFF_WATCHDOG_SECONDS:-1800}"
# After a boot the machine gets a moment to settle; it is also the only window
# in which a human can stop an unwanted start (systemctl stop).
SETTLE_SECONDS="${SETTLE_SECONDS:-20}"

log() { printf '%s %s\n' "$(date '+%F %T %Z')" "$*"; }

# --- control-channel cut-off -------------------------------------------------
# The rules are NOT persisted, so a reboot always restores reachability by
# itself; the chain re-applies them after every boot, in the same place where it
# re-applies the governor. On top of that a transient systemd timer removes them
# even if this script dies without reaching its own cleanup. Two independent
# ways out, because locking oneself out of the measurement machine is the one
# failure this rig must not have.
cut_remove() {
  local ip="${1:-$CUT_HOST_IP}"
  [[ -n "$ip" ]] || return 0
  while $SUDO iptables -C INPUT -s "$ip" -j DROP 2>/dev/null; do
    $SUDO iptables -D INPUT -s "$ip" -j DROP || break
  done
  while $SUDO iptables -C OUTPUT -d "$ip" -j DROP 2>/dev/null; do
    $SUDO iptables -D OUTPUT -d "$ip" -j DROP || break
  done
}

cut_install() {
  [[ -n "$CUT_HOST_IP" ]] || return 0
  local deadline_file="$CONTROL/cutoff-deadline"
  if [[ -s "$deadline_file" ]]; then
    local deadline; deadline="$(cat "$deadline_file")"
    if (( $(date +%s) >= deadline )); then
      log "cut-off deadline passed ($deadline); leaving the channel open"
      cut_remove
      return 0
    fi
  fi
  $SUDO iptables -C INPUT -s "$CUT_HOST_IP" -j DROP 2>/dev/null \
    || $SUDO iptables -I INPUT 1 -s "$CUT_HOST_IP" -j DROP
  $SUDO iptables -C OUTPUT -d "$CUT_HOST_IP" -j DROP 2>/dev/null \
    || $SUDO iptables -I OUTPUT 1 -d "$CUT_HOST_IP" -j DROP
  $SUDO systemd-run --collect --on-active="$CUTOFF_WATCHDOG_SECONDS" \
    --unit="w1-uncut-$(date +%s)" "$TRIAL_DIR/w1_run_chain.sh" --uncut >/dev/null 2>&1 \
    || log "WARNING: could not arm the cut-off watchdog"
  log "control channel to $CUT_HOST_IP cut (watchdog ${CUTOFF_WATCHDOG_SECONDS}s)"
}

# systemd-run invokes this directly; it must run before anything else.
if [[ "${1:-}" == "--uncut" ]]; then
  cut_remove "${2:-$CUT_HOST_IP}"
  exit 0
fi

segment=""

halt() {
  local reason="$1" rc="$2"
  printf 'reason\t%s\nsegment\t%s\nrc\t%s\nepoch\t%s\n' \
    "$reason" "$segment" "$rc" "$(date +%s)" >"$W1_OUT/HALT"
  log "HALT: $reason (segment=${segment:-none} rc=$rc); chain stopped until a human decides"
  # A halted chain must be reachable: this is where a human takes over.
  cut_remove
  exit "$rc"
}

disable_unit() {
  # Once complete, the unit must not come up on every later boot.
  $SUDO systemctl disable "$UNIT" >/dev/null 2>&1 \
    || log "WARNING: could not disable $UNIT"
}

complete_chain() {
  printf '%s/%s segments\n' "${#SEGMENTS[@]}" "${#SEGMENTS[@]}" >"$W1_OUT/W1_COMPLETE"
  log "W1_COMPLETE: ${#SEGMENTS[@]}/${#SEGMENTS[@]} segments; archives wait in $ARCHIVES"
  disable_unit
  cut_remove
  exit 0
}

# A segment counts as done only with ITS ARCHIVE AND CHECKSUM, not with
# RUN_COMPLETE alone. The runner writes RUN_COMPLETE, then packs the archive,
# and only then its checksum -- a hard power cut between those steps would leave
# a segment counted and without an archive nobody would ever make.
segment_done() {
  local candidate="$1"
  [[ -e "$W1_OUT/$candidate/RUN_COMPLETE" && -s "$ARCHIVES/W1-$candidate.sha256" ]]
}

incomplete_segments() {
  local candidate count=0
  for candidate in "${SEGMENTS[@]}"; do
    segment_done "$candidate" || count=$((count + 1))
  done
  printf '%s\n' "$count"
}

[[ -x "$SEGMENT_SCRIPT" ]] || { log "ERROR: no executable $SEGMENT_SCRIPT"; exit 2; }
mkdir -p "$W1_OUT" "$CONTROL" "$ARCHIVES"

if [[ -e "$W1_OUT/HALT" ]]; then
  log "HALT found in $W1_OUT/HALT -- the chain does not start without a human decision"
  cat "$W1_OUT/HALT"
  cut_remove
  exit 2
fi
if [[ -e "$W1_OUT/W1_COMPLETE" ]]; then
  log "W1 already complete; nothing to do"
  disable_unit
  cut_remove
  exit 0
fi

log "chain start (boot $(cut -d. -f1 /proc/uptime)s ago); settling for $SETTLE_SECONDS s"
printf '%s\tboot\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(uptime -s)" >>"$CONTROL/timeline.tsv"
# The cut comes AFTER the settle window, never before. That window has two
# consumers: a human who wants to stop an unwanted start, and the start script
# on the control host, which still has to confirm the unit came up. Cutting the
# channel first closes both -- the start script cannot reach the worker to check
# its own start, and reports a failure for a run that is in fact under way.
sleep "$SETTLE_SECONDS"
cut_install

# The governor comes back as 'ondemand' after every reboot, so it is set here
# rather than once at start.
$SUDO sh -c 'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance >"$f"; done' \
  || { log "ERROR: could not set the performance governor"; exit 2; }

for candidate in "${SEGMENTS[@]}"; do
  if ! segment_done "$candidate"; then
    segment="$candidate"
    break
  fi
done
[[ -n "$segment" ]] || complete_chain

# An archive cut off mid-packing would block the runner ("archive already
# exists"), and the previous attempt's status would block the segment wrapper.
# The segment is REOPENED here, so the package goes and the status moves into
# history: the rule "one status per closed segment" is not broken, only its
# closing point moves.
if [[ -e "$W1_OUT/$segment/RUN_COMPLETE" ]]; then
  log "segment $segment computed but its archive is not closed; repacking only"
  rm -f "$ARCHIVES/W1-$segment.tar.gz" "$ARCHIVES/W1-$segment.sha256"
  if [[ -e "$CONTROL/$segment/runner.rc" ]]; then
    mv "$CONTROL/$segment/runner.rc" "$CONTROL/$segment/runner.rc.$(date +%s)"
  fi
fi

log "START: segment $segment ($(incomplete_segments) of ${#SEGMENTS[@]} left)"
mkdir -p "$CONTROL/$segment"
rc=0
ROUNDS="$ROUNDS" W1_FAIL_SEGMENT="$W1_FAIL_SEGMENT" \
  "$SEGMENT_SCRIPT" "$segment" "$CPU" "$W1_OUT/$segment" "$ARCHIVES" "$CONTROL/$segment" || rc=$?

if (( rc != 0 )); then
  if [[ -e "$W1_OUT/$segment/STOP" ]]; then halt stop "$rc"; fi
  halt apparatus "$rc"
fi
[[ -e "$W1_OUT/$segment/RUN_COMPLETE" ]] || halt apparatus_without_run_complete 2
log "END: segment $segment rc=0, RUN_COMPLETE"

if (( $(incomplete_segments) == 0 )); then
  complete_chain
fi

log "rebooting the worker before the next segment; the unit comes up from boot by itself"
printf '%s\treboot_requested\tafter\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$segment" >>"$CONTROL/timeline.tsv"
sync
$SUDO systemctl --no-block reboot || { log "ERROR: worker reboot refused"; exit 2; }
exit 0
