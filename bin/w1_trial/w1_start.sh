#!/usr/bin/env bash
# One-shot start of the W-1 conformance chain: gate the worker, ship the rig,
# install the systemd unit and start the first segment.
#
# After this script returns, the control host has NO role in the run and may be
# switched off. The chain of segments is driven by the worker under systemd; it
# reboots itself between segments and comes back up after a power cut. Archives
# are collected later by w1_collect.sh -- whenever, including only after the
# whole run.
#
# Starting is always from zero. Resuming an interrupted run belongs to the unit
# (systemctl start), not to this script, or it could not tell a fresh trial from
# overwriting somebody else's state.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKER_SSH="${WORKER_SSH:-michal@192.168.88.13}"
SSH_CONFIG="${RDB_SSH_CONFIG:-/dev/null}"
TRIAL_DIR="${TRIAL_DIR:-/home/michal/w1_trial}"
W1_OUT="${W1_OUT:-/home/michal/w1_out}"
ARCHIVES="${ARCHIVES:-/home/michal/w1_archives}"
CONTROL="${CONTROL:-/home/michal/w1_control}"
UNIT_NAME="${UNIT_NAME:-k9b-w1.service}"
CPU="${CPU:-3}"
SETTLE_SECONDS="${SETTLE_SECONDS:-20}"
ROUNDS="${ROUNDS:-9000}"
# Empty: the control channel is severed on the host side, or by hand. Non-empty:
# the worker severs it, which is the only option when the control host has no
# passwordless sudo.
CUT_HOST_IP="${CUT_HOST_IP:-}"
CUTOFF_WATCHDOG_SECONDS="${CUTOFF_WATCHDOG_SECONDS:-1800}"
W1_FAIL_SEGMENT="${W1_FAIL_SEGMENT:-}"

SSH_OPTIONS=(-F "$SSH_CONFIG" -o BatchMode=yes -o ConnectTimeout=8 \
  -o ServerAliveInterval=15 -o ServerAliveCountMax=3)

fail() { echo "W-1 START FAILED: $*" >&2; exit 2; }
ssh_run() { ssh "${SSH_OPTIONS[@]}" "$WORKER_SSH" "$@"; }

# The same configuration must reach the unit generator on BOTH sides, or
# comparing the checksums would compare two different files.
unit_env=(
  "TRIAL_DIR=$TRIAL_DIR"
  "W1_OUT=$W1_OUT"
  "ARCHIVES=$ARCHIVES"
  "CONTROL=$CONTROL"
  "UNIT_NAME=$UNIT_NAME"
  "CPU=$CPU"
  "SETTLE_SECONDS=$SETTLE_SECONDS"
  "ROUNDS=$ROUNDS"
  "CUT_HOST_IP=$CUT_HOST_IP"
  "CUTOFF_WATCHDOG_SECONDS=$CUTOFF_WATCHDOG_SECONDS"
  "W1_FAIL_SEGMENT=$W1_FAIL_SEGMENT"
)
remote_env=""
for entry in "${unit_env[@]}"; do
  remote_env+=" $(printf '%q' "$entry")"
done

ssh_run true || fail "worker unreachable at $WORKER_SSH"

ssh_run "for path in '$W1_OUT' '$ARCHIVES' '$CONTROL'; do
  if [ -e \"\$path\" ]; then echo \"artifact already exists: \$path\" >&2; exit 2; fi
done" || fail "worker holds stale W-1 artifacts; resuming goes through systemctl start, not this script"

ssh_run "mkdir -p '$TRIAL_DIR'" || fail "cannot create $TRIAL_DIR on the worker"
scp "${SSH_OPTIONS[@]}" -q \
  "$HERE/w1_run_chain.sh" "$HERE/w1_run_segment.sh" "$HERE/w1_install_worker_service.sh" "$HERE/README.md" \
  "$WORKER_SSH:$TRIAL_DIR/" || fail "could not ship the rig to $TRIAL_DIR"
ssh_run "chmod +x '$TRIAL_DIR'/w1_*.sh" || fail "cannot make the rig executable"

ssh_run "env$remote_env $(printf '%q' "$TRIAL_DIR/w1_install_worker_service.sh")" \
  || fail "installing $UNIT_NAME on the worker failed"

# Consumer-side gate: what counts is the file the worker's systemd will actually
# execute, not the host's copy of it.
worker_sum="$(ssh_run "sha256sum '/etc/systemd/system/$UNIT_NAME'" | awk '{print $1}')" \
  || fail "cannot read the unit on the worker"
host_sum="$(env "${unit_env[@]}" "$HERE/w1_install_worker_service.sh" --print | sha256sum | awk '{print $1}')"
[[ "$worker_sum" == "$host_sum" ]] \
  || fail "the unit on the worker differs from the one generated on the host ($worker_sum != $host_sum)"

enabled="$(ssh_run "systemctl is-enabled '$UNIT_NAME'" || true)"
[[ "$enabled" == enabled ]] || fail "$UNIT_NAME is not enabled at boot (it is: $enabled)"

if [[ -n "$CUT_HOST_IP" ]]; then
  deadline=$(( $(date +%s) + CUTOFF_WATCHDOG_SECONDS ))
  ssh_run "printf '%s\n' '$deadline' >'$CONTROL/cutoff-deadline'" \
    || fail "cannot write the cut-off deadline"
  echo "cut-off deadline: $(date -d "@$deadline" '+%F %T %Z') -- past it the worker stops re-applying the rule"
fi

ssh_run "sudo -n systemctl start --no-block '$UNIT_NAME'" || fail "starting $UNIT_NAME was refused"
sleep 3
active="$(ssh_run "systemctl is-active '$UNIT_NAME'" || true)"
[[ "$active" == active ]] || fail "$UNIT_NAME is not active after start (it is: $active)"

echo "OK: the W-1 chain is running on the worker as $UNIT_NAME"
echo "unit sha256: $host_sum (host and worker agree)"
echo "chain log:   $WORKER_SSH:$CONTROL/chain.log"
echo "state and archives: $HERE/w1_collect.sh (safe to run at any time, any number of times)"
echo "the control host is no longer needed for the run and may be switched off"
