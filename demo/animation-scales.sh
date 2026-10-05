#!/bin/sh
# Android's three animation scales, turned off the standard way, and what
# that does to an app's own animation.
#
#   demo/animation-scales.sh <emulator-serial>
#   NOPAUSE=1 demo/animation-scales.sh emulator-5554
#
# The standard advice for fast, steady Android tests is three adb commands
# that set the system's animation scales to 0. They work: the settings read
# back 0 and the system's transitions stop. This shows the other half — the
# app's own animation, on MobiumApp's Motion Demo, timed by the app:
#
#   - "ignoring" slides for two seconds whatever the device says. It runs
#     on the app's own clock, and the scales do not reach it.
#   - "honoring" asks the platform whether motion should be reduced, and
#     the zeroed scales are how Android answers yes — so it appears at once.
#
# So the scales disable the app's animation only when the app listens.
#
# These are device-wide settings. The script reads them first and puts back
# exactly what it found — a value, or no value at all — when it ends, even
# on a failure. It refuses a real phone unless ALLOW_PHONE=1.
set -e
ANDROID="$1"
if [ -z "$ANDROID" ]; then echo "usage: $0 <android-serial>" >&2; exit 2; fi
. "$(dirname "$0")/lib.sh"
ADB="${ADB:-adb}"
a() { "$ADB" -s "$ANDROID" shell "$@" | tr -d '\r'; }
KEYS="window_animation_scale transition_animation_scale animator_duration_scale"

case "$ANDROID" in
  emulator-*) ;;
  *) [ -n "$ALLOW_PHONE" ] || fail "$ANDROID is not an emulator: these are settings on somebody's phone. ALLOW_PHONE=1 to go ahead" ;;
esac

# What the device had, so the end can put back exactly that.
for k in $KEYS; do eval "was_$k=\$(a settings get global $k)"; done
restore() {
  for k in $KEYS; do
    eval "v=\$was_$k"
    if [ "$v" = null ]; then a settings delete global "$k" >/dev/null; else a settings put global "$k" "$v"; fi
  done
}
trap restore EXIT INT TERM

adbshow() { printf '%s$ adb shell %s%s\n' "$C" "$*" "$N"; a "$@"; }
round() {
  m tap "label=Replay Honoring" >/dev/null
  m tap "label=Honoring target" >/dev/null
  m tap "label=Replay Ignoring" >/dev/null
  m tap "label=Ignoring target" >/dev/null
  echo "$(ms honoring) $(ms ignoring)"
}
timed() {
  show tap "label=Replay Ignoring"
  show tap "label=Ignoring target"
  show text testid=ignoringResult
  show tap "label=Replay Honoring"
  show tap "label=Honoring target"
  show text testid=honoringResult
}

for k in $KEYS; do a settings put global "$k" 1; done
motion

say "1. Animations on: the scales at 1"
for k in $KEYS; do adbshow settings get global "$k"; done
show text testid=reduceMotion
timed
set -- $(round); on_h=$1; on_i=$2
note "again, quietly: honoring ${on_h}ms, ignoring ${on_i}ms"
pause

say "2. The standard advice: every scale to 0"
for k in $KEYS; do adbshow settings put global "$k" 0; done
for k in $KEYS; do adbshow settings get global "$k"; done
note "every setting says off. Now the app, opened fresh:"
motion
show text testid=reduceMotion
timed
set -- $(round); off_h=$1; off_i=$2
note "again, quietly: honoring ${off_h}ms, ignoring ${off_i}ms"
pause

printf '\n%s                 scales at 1    at 0%s\n' "$B" "$N"
printf '  honoring        %6sms    %6sms\n' "$on_h" "$off_h"
printf '  ignoring        %6sms    %6sms   %s← its own clock%s\n' "$on_i" "$off_i" "$DIM" "$N"
[ "$on_h" -ge 2000 ] || fail "honoring took ${on_h}ms with the scales at 1: no slide was waited for"
[ "$off_h" -lt 2000 ] || fail "honoring took ${off_h}ms with the scales at 0: it did not appear at once"
[ "$off_i" -ge 2000 ] || fail "ignoring took ${off_i}ms with the scales at 0: the scales did stop it"
ok "the scales turned off the animation that asked, and not the one that did not"
pause

say "3. Put back as found"
restore
for k in $KEYS; do adbshow settings get global "$k"; done
trap - EXIT INT TERM
ok "the device's scales are as they were"
