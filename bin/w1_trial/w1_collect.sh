#!/usr/bin/env bash
# Read the state of the W-1 chain and fetch whatever is already closed.
#
# Stateless and idempotent: safe to run at any time, any number of times,
# including only after the whole run. Collection is NOT a precondition for
# progress -- the worker keeps going with the control host switched off, and
# nothing here writes to the worker.
#
# Three states are reported, not two: still running, complete, stopped with an
# error. An unreachable worker is a fourth report, not an error, because during
# a cut-off trial it is the expected answer.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKER_SSH="${WORKER_SSH:-michal@192.168.88.13}"
SSH_CONFIG="${RDB_SSH_CONFIG:-/dev/null}"
W1_OUT="${W1_OUT:-/home/michal/w1_out}"
ARCHIVES="${ARCHIVES:-/home/michal/w1_archives}"
CONTROL="${CONTROL:-/home/michal/w1_control}"
DEST="${DEST:-$HERE/../../tables/w1}"

SSH_OPTIONS=(-F "$SSH_CONFIG" -o BatchMode=yes -o ConnectTimeout=8)
ssh_run() { ssh "${SSH_OPTIONS[@]}" "$WORKER_SSH" "$@"; }

mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

if ! ssh_run true 2>/dev/null; then
  echo "STATE: worker unreachable at $WORKER_SSH"
  echo "       During a cut-off trial this is the expected answer and not a failure:"
  echo "       the run does not need this machine. Try again later."
  exit 3
fi

state="$(ssh_run "
  if [ -e '$W1_OUT/W1_COMPLETE' ]; then echo complete
  elif [ -e '$W1_OUT/HALT' ]; then echo halted
  else echo running; fi" 2>/dev/null || echo unknown)"

echo "STATE: $state"
echo

echo "=== segments ==="
ssh_run "for s in S1 S2 S3; do
  rc=\$(cat '$CONTROL'/\$s/runner.rc 2>/dev/null || echo -)
  done=\$( [ -e '$W1_OUT'/\$s/RUN_COMPLETE ] && echo yes || echo no )
  sum=\$(cat '$ARCHIVES'/W1-\$s.sha256 2>/dev/null || echo -)
  printf '%s\trun_complete=%s\trunner.rc=%s\tarchive=%s\n' \$s \$done \$rc \$sum
done" || true
echo

if [[ "$state" == halted ]]; then
  echo "=== HALT ==="
  ssh_run "cat '$W1_OUT/HALT'" || true
  echo
fi

echo "=== fetching closed archives and control files into $DEST ==="
# Only archives whose checksum file exists are fetched: the checksum is what
# closes a segment, so anything without it is still being written.
closed="$(ssh_run "cd '$ARCHIVES' 2>/dev/null && ls *.sha256 2>/dev/null | sed 's/\.sha256$//'" || true)"
for seg in $closed; do
  scp "${SSH_OPTIONS[@]}" -q "$WORKER_SSH:$ARCHIVES/$seg.tar.gz" "$WORKER_SSH:$ARCHIVES/$seg.sha256" "$DEST/" \
    || { echo "WARN could not fetch $seg"; continue; }
  expected="$(cat "$DEST/$seg.sha256")"
  actual="$(sha256sum "$DEST/$seg.tar.gz" | awk '{print $1}')"
  if [[ "$expected" == "$actual" ]]; then echo "OK    $seg.tar.gz $actual"
  else echo "ERROR $seg.tar.gz sha256 $actual, expected $expected"; fi
done

for f in chain.log timeline.tsv; do
  scp "${SSH_OPTIONS[@]}" -q "$WORKER_SSH:$CONTROL/$f" "$DEST/$f" 2>/dev/null \
    && echo "OK    $f" || echo "SKIP  $f not present yet"
done

# Reboot history is the file-level proof of property 3: the chain really did
# restart the machine between segments rather than merely claiming it would.
ssh_run "last -n 20 reboot 2>/dev/null" >"$DEST/worker-reboots.txt" 2>/dev/null \
  && echo "OK    worker-reboots.txt" || true
# Session history is the proof of the cut-off: no accepted login from the
# control host inside the run window.
ssh_run "last -n 40 2>/dev/null" >"$DEST/worker-logins.txt" 2>/dev/null \
  && echo "OK    worker-logins.txt" || true

echo
echo "RESULT: state=$state, collected into $DEST"
[[ "$state" == complete ]] && exit 0
[[ "$state" == halted ]] && exit 4
exit 3
