#!/usr/bin/env bash
# Stop the W-1 chain remotely, with one command.
#
# Stopping the unit stops the current segment. It does NOT leave a HALT file, so
# the run can be resumed with 'systemctl start k9b-w1.service' -- an operator
# stop and an apparatus failure must not look the same.
set -euo pipefail

WORKER_SSH="${WORKER_SSH:-michal@192.168.88.13}"
SSH_CONFIG="${RDB_SSH_CONFIG:-/dev/null}"
UNIT_NAME="${UNIT_NAME:-k9b-w1.service}"
SSH_OPTIONS=(-F "$SSH_CONFIG" -o BatchMode=yes -o ConnectTimeout=8)

ssh "${SSH_OPTIONS[@]}" "$WORKER_SSH" "sudo -n systemctl stop '$UNIT_NAME'; systemctl is-active '$UNIT_NAME' || true"
echo "stopped: $UNIT_NAME on $WORKER_SSH"
echo "resume with: ssh $WORKER_SSH sudo -n systemctl start $UNIT_NAME"
