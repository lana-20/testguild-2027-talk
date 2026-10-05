#!/bin/sh
# The demo test, through the CLI: tests/motion.test.json's steps as mobium
# commands, in the same order with the same arguments, on one device.
#
#   demo/motion-cli.sh <device> [driver]        # driver: wda for iOS
#   ROUNDS=3 demo/motion-cli.sh emulator-5554
#
# Each round runs both cases — animations on, then off — from a fresh launch,
# as `mobium test` does. After a case's steps it reads the two times the app
# kept, and the case's own time: from opening the Motion Demo to its last
# check, so not the setting switch before it (25 s through Settings on an
# iPhone) and not the launch. One line per case:
#
#   cli  emulator-5554  on   honoring 2517  control 2584  case 9.81
#
# The device's animation setting is read before and after, and a difference
# is reported, not fixed. MOBIUM=/path/to/mobium if it is not on PATH.
set -e
DEV="$1"; DRIVER="${2:-}"
if [ -z "$DEV" ]; then echo "usage: $0 <device> [driver]" >&2; exit 2; fi
MOBIUM="${MOBIUM:-mobium}"
ROUNDS="${ROUNDS:-1}"
APP=dev.mobium.mobiumapp
m() { if [ -n "$DRIVER" ]; then "$MOBIUM" --driver "$DRIVER" --device "$DEV" "$@"; else "$MOBIUM" --device "$DEV" "$@"; fi; }
now() { python3 -c 'import time; print(time.time())'; }
ms() { sed -n 's/.*tapped \([0-9]*\)ms.*/\1/p'; }

# Same steps as the test file, or nothing runs: the CLI's spelling of each
# step is checked against it, so the two cannot drift apart unseen.
python3 "$(dirname "$0")/same-steps.py" cli || exit 2

# One case of tests/motion.test.json. $1..$4 are the case's values:
# animations, reduce_motion, reported, confetti.
case_steps() {
  m terminate "$APP" >/dev/null 2>&1 || true
  m launch "$APP" >/dev/null
  # --- the test's steps ---
  m accessibility reduce_motion "$2" >/dev/null
  t0=$(now)
  m tap "label=Motion Demo" >/dev/null
  m wait testid=reduceMotion --for text --text "reduceMotion=$3" --exact >/dev/null
  m tap "label=Replay Honoring" >/dev/null
  m tap "label=Honoring target" >/dev/null
  m wait testid=honoringResult --for text --text tapped >/dev/null
  m tap "label=Replay Ignoring" >/dev/null
  m tap "label=Ignoring target" >/dev/null
  m wait testid=ignoringResult --for text --text tapped >/dev/null
  m tap "label=Celebrate 🎉" >/dev/null
  m wait testid=confettiState --for text --text "$4" >/dev/null
  # --- the measurement ---
  t1=$(now)
  h=$(m text testid=honoringResult | ms); c=$(m text testid=ignoringResult | ms)
  printf 'cli  %s  %-3s  honoring %s  control %s  case %.2f\n' "$DEV" "$1" "$h" "$c" "$(python3 -c "print($t1 - $t0)")"
}

before=$(m accessibility reduce_motion | awk '{ print $2 }')
for r in $(seq "$ROUNDS"); do
  case_steps on  off false "confetti: done"
  case_steps off on  true  "still: reduce motion"
done
m daemon stop >/dev/null 2>&1 || true     # the session ends: it puts back what it changed
after=$(m accessibility reduce_motion | awk '{ print $2 }')
m daemon stop >/dev/null 2>&1 || true
if [ "$after" != "$before" ]; then
  echo "WARNING: reduce_motion was $before before and is $after now — put it back by hand" >&2
  exit 1
fi
echo "reduce_motion as found: $after"
