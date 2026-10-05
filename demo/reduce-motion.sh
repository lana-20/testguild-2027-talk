#!/bin/sh
# Reduce Motion, on a real iPhone, with the app as the stopwatch.
#
#   demo/reduce-motion.sh            # pauses at each beat; press return
#   NOPAUSE=1 demo/reduce-motion.sh  # straight through, for a rehearsal
#
# MobiumApp's Motion Demo has two targets that slide in over two seconds,
# identical but for one line: "honoring" appears at once when Reduce Motion
# is on, "ignoring" always slides. Mobium waits for a target to stop moving
# before it touches it, so a slide is time spent waiting. Each target records
# how long after its own Replay the tap arrived — the app keeps the time, not
# the tool.
#
# The ignoring target is the control. If its time moves when the setting
# does, the measurement is measuring something else, and the script says so.
#
# Beats:
#   1. Reduce Motion on: honoring fast, ignoring slow. Confetti stays still.
#   2. Reduce Motion off: honoring slows to match; the control does not move.
#      Confetti falls, and a falling piece is refused, not tapped.
#   3. Reduce Motion back on, read from the Settings switch and from the app.
#
# This changes a setting on the phone. It starts only with Reduce Motion on,
# turns it off for beat 2, and turns it back on — also if anything fails on
# the way, and again when the session ends.
set -e
. "$(dirname "$0")/lib.sh"

restore() {
  if [ "$CHANGED" = 1 ]; then
    printf '\n%sputting Reduce Motion back on%s\n' "$Y" "$N" >&2
    m accessibility reduce_motion on >/dev/null 2>&1 || true
  fi
}
trap restore EXIT INT TERM

round() {
  m tap "label=Replay Honoring" >/dev/null
  m tap "label=Honoring target" >/dev/null
  m tap "label=Replay Ignoring" >/dev/null
  m tap "label=Ignoring target" >/dev/null
  echo "$(ms honoring) $(ms ignoring)"
}

# --- before anything: where the phone is
motion
case "$(m text testid=reduceMotion)" in
  reduceMotion=true) ;;
  *) fail "start with Reduce Motion on (Settings > Accessibility > Motion) — the restore puts it back as it was" ;;
esac

say "1. Reduce Motion is on"
show text testid=reduceMotion
pause
show tap "label=Replay Honoring"
show tap "label=Honoring target"
show text testid=honoringResult
show tap "label=Replay Ignoring"
show tap "label=Ignoring target"
show text testid=ignoringResult
set -- $(round); on_h=$1; on_i=$2
note "again, quietly: honoring ${on_h}ms, ignoring ${on_i}ms"
note "about 1.3s is the tool's own round trip: Replay and the tap are two calls"
pause
show tap "label=Celebrate 🎉"
show text testid=confettiState
pause

say "2. Reduce Motion off"
note "a real iPhone takes no setting from outside: mobium goes through the Settings app"
CHANGED=1
show accessibility reduce_motion off
show text testid=reduceMotion
show tap "label=Replay Honoring"
show tap "label=Honoring target"
show text testid=honoringResult
show tap "label=Replay Ignoring"
show tap "label=Ignoring target"
show text testid=ignoringResult
set -- $(round); off_h=$1; off_i=$2
note "again, quietly: honoring ${off_h}ms, ignoring ${off_i}ms"
pause

printf '\n%s                 Reduce Motion on   off%s\n' "$B" "$N"
printf '  honoring        %6sms    %6sms\n' "$on_h" "$off_h"
printf '  ignoring        %6sms    %6sms   %s← the control%s\n' "$on_i" "$off_i" "$DIM" "$N"
[ "$on_h" -lt 2000 ] || fail "honoring took ${on_h}ms with Reduce Motion on: it did not appear at once"
[ "$off_h" -ge 2000 ] || fail "honoring took ${off_h}ms with Reduce Motion off: no slide was waited for"
d=$((on_i - off_i)); [ ${d#-} -lt 500 ] || fail "the control moved by ${d#-}ms: the measurement is measuring something else"
ok "the setting moved the honoring target, and only that"
pause

show tap "label=Celebrate 🎉"
show text testid=confettiState
pause
note "the pieces are drawn, not elements — so turn on the switch that puts them in the tree"
SW=$(m map | awk '/Pieces visible to automation \(switch/ { print $1; exit }')
[ -n "$SW" ] || fail "no 'Pieces visible to automation' switch in the map"
show check "$SW"
show tap "label=Celebrate 🎉"
PIECES=$(m map)
P=$(echo "$PIECES" | awk '/ confetti [0-9]+ / { print $1; exit }')
[ -n "$P" ] || fail "no confetti piece in the map while it falls"
printf '%s$ mobium map%s\n' "$C" "$N"
echo "$PIECES" | grep ' confetti ' | head -4
note "… $(echo "$PIECES" | grep -c ' confetti ') pieces in the map, every one moving"
set +e
show tap "$P"; st=$?
set -e
[ "$st" = 6 ] || fail "the tap on a falling piece exited $st, not 6 (timeout)"
ok "exit $st, timeout: a target that never holds still is refused, not tapped"
pause

say "3. Reduce Motion back on"
show accessibility reduce_motion on
CHANGED=
show accessibility reduce_motion
note "that read is the Settings switch itself; and the app agrees:"
show text testid=reduceMotion
[ "$(m accessibility reduce_motion | awk '{ print $2 }')" = on ] || fail "Reduce Motion did not come back on"
[ "$(m text testid=reduceMotion)" = reduceMotion=true ] || fail "the app does not see Reduce Motion on"
ok "Reduce Motion on, by the switch and by the app"
