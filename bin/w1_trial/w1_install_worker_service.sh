#!/usr/bin/env bash
# Install the systemd unit that drives the W-1 conformance chain on the
# measurement machine.
#
# This script is the ONLY source of the unit text: --print emits exactly what
# the installation writes to /etc/systemd/system. The control host can therefore
# compare its own copy against the worker's the same way the K26v3 ANEKS-1 gate
# does -- check the file on the side that consumes it, not on your own.
#
# Structure mirrors rdb-experiment/results_20260814_K26v3/install_worker_service.sh
# deliberately. W-1 requires repeating that pattern, not inventing another one.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

UNIT_NAME="${UNIT_NAME:-k9b-w1.service}"
UNIT_PATH="${UNIT_PATH:-/etc/systemd/system/$UNIT_NAME}"
RUN_USER="${RUN_USER:-michal}"
TRIAL_DIR="${TRIAL_DIR:-$HERE}"
CPU="${CPU:-3}"
W1_OUT="${W1_OUT:-/home/michal/w1_out}"
ARCHIVES="${ARCHIVES:-/home/michal/w1_archives}"
CONTROL="${CONTROL:-/home/michal/w1_control}"
SETTLE_SECONDS="${SETTLE_SECONDS:-20}"
ROUNDS="${ROUNDS:-9000}"
CUT_HOST_IP="${CUT_HOST_IP:-}"
CUTOFF_WATCHDOG_SECONDS="${CUTOFF_WATCHDOG_SECONDS:-1800}"
W1_FAIL_SEGMENT="${W1_FAIL_SEGMENT:-}"
SUDO="${SUDO:-sudo -n}"

unit_text() {
  cat <<UNIT
[Unit]
Description=K9b W-1: autonomy conformance chain (one segment per start)
Documentation=file://$TRIAL_DIR/README.md
After=local-fs.target

[Service]
Type=simple
User=$RUN_USER
WorkingDirectory=$TRIAL_DIR
Environment=CPU=$CPU
Environment=TRIAL_DIR=$TRIAL_DIR
Environment=W1_OUT=$W1_OUT
Environment=ARCHIVES=$ARCHIVES
Environment=CONTROL=$CONTROL
Environment=UNIT=$UNIT_NAME
Environment=SETTLE_SECONDS=$SETTLE_SECONDS
Environment=ROUNDS=$ROUNDS
Environment=CUT_HOST_IP=$CUT_HOST_IP
Environment=CUTOFF_WATCHDOG_SECONDS=$CUTOFF_WATCHDOG_SECONDS
Environment=W1_FAIL_SEGMENT=$W1_FAIL_SEGMENT
# Unprivileged SCHED_FIFO needs a non-zero RLIMIT_RTPRIO; without it chrt fails
# with EPERM and the segment dies before doing any work. Raising the limit is
# what lets the workload run at real-time priority as the run user rather than
# as root.
LimitRTPRIO=99
ExecStart=$TRIAL_DIR/w1_run_chain.sh
Restart=no
TimeoutStopSec=120
StandardOutput=append:$CONTROL/chain.log
StandardError=append:$CONTROL/chain.log

[Install]
WantedBy=multi-user.target
UNIT
}

if [[ "${1:-}" == "--print" ]]; then
  unit_text
  exit 0
fi
if (( $# > 1 )) || [[ -n "${1:-}" && "${1:-}" != "--force" ]]; then
  echo "usage: $(basename "$0") [--print|--force]" >&2
  exit 2
fi

[[ -x "$TRIAL_DIR/w1_run_chain.sh" ]] \
  || { echo "ERROR: no executable $TRIAL_DIR/w1_run_chain.sh" >&2; exit 2; }
mkdir -p "$CONTROL"

# Refuse a silent overwrite: reinstalling is safe only when the unit already on
# disk is byte for byte the same file.
if [[ -e "$UNIT_PATH" && "${1:-}" != "--force" ]]; then
  if ! diff -q <(unit_text) "$UNIT_PATH" >/dev/null; then
    echo "ERROR: $UNIT_PATH exists and differs from the generated text; use --force" >&2
    diff -u "$UNIT_PATH" <(unit_text) >&2 || true
    exit 2
  fi
fi

unit_text | $SUDO tee "$UNIT_PATH" >/dev/null
$SUDO systemctl daemon-reload
$SUDO systemctl enable "$UNIT_NAME" >/dev/null

state="$(systemctl is-enabled "$UNIT_NAME" 2>&1 || true)"
[[ "$state" == enabled ]] || { echo "ERROR: $UNIT_NAME is not enabled (it is: $state)" >&2; exit 2; }

printf 'OK: %s installed and enabled at boot\n' "$UNIT_PATH"
printf 'sha256\t%s\n' "$(sha256sum "$UNIT_PATH" | awk '{print $1}')"
