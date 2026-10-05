#!/bin/sh
# Animations on, then off, on one device: the evidence table behind the talk.
#
#   IPHONE=<udid> demo/compare.sh            # a real iPhone or a simulator
#   ANDROID=<serial> demo/compare.sh         # an emulator or a real phone
#   ROUNDS=5 ANDROID=emulator-5554 demo/compare.sh
#
# For each condition, on MobiumApp's Motion Demo, ROUNDS times (default 3):
#
#   honoring   ms from Replay to the tap, as the app counts it
#   ignoring   the same for the control, which slides whatever the setting
#   flow       wall-clock ms for a short test: launch the app, open the
#              Motion Demo, Replay, tap the honoring target, read its result
#
# "Animations off" is the switch each platform has: all three Android scales
# at 0; Reduce Motion on iOS. Both are device-wide. The device's own values
# are read first and put back when the script ends, also on a failure — on
# Android exactly as found, a missing key included; on iOS by the switch,
# read back.
#
# Prints one line per condition, tab-separated, with the medians and every
# raw value, for EVIDENCE.md.
set -e
NOPAUSE=1
. "$(dirname "$0")/lib.sh"
ROUNDS="${ROUNDS:-3}"
now() { python3 -c 'import time; print(int(time.time() * 1000))'; }
median() { tr ' ' '\n' | grep . | sort -n | awk '{ a[NR] = $1 } END { print a[int((NR + 1) / 2)] }'; }

if [ -n "$ANDROID" ]; then
  ADB="${ADB:-adb}"
  a() { "$ADB" -s "$ANDROID" shell "$@" | tr -d '\r'; }
  KEYS="window_animation_scale transition_animation_scale animator_duration_scale"
  for k in $KEYS; do eval "was_$k=\$(a settings get global $k)"; done
  restore() {
    for k in $KEYS; do
      eval "v=\$was_$k"
      if [ "$v" = null ]; then a settings delete global "$k" >/dev/null; else a settings put global "$k" "$v"; fi
    done
  }
  animations() { for k in $KEYS; do a settings put global "$k" "$([ "$1" = on ] && echo 1 || echo 0)"; done; }
  DEVICE="$ANDROID"
else
  was_rm=$(m accessibility reduce_motion | awk '{ print $2 }')
  restore() { m accessibility reduce_motion "$was_rm" >/dev/null 2>&1 || true; }
  animations() {
    want=$([ "$1" = on ] && echo off || echo on)
    [ "$(m accessibility reduce_motion | awk '{ print $2 }')" = "$want" ] || m accessibility reduce_motion "$want" >/dev/null
  }
  DEVICE="$IPHONE"
fi
trap restore EXIT INT TERM

measure() {
  animations "$1"
  hs=; is=; fs=
  for i in $(seq "$ROUNDS"); do
    t0=$(now)
    motion
    m tap "label=Replay Honoring" >/dev/null
    m tap "label=Honoring target" >/dev/null
    h=$(ms honoring)
    fs="$fs $(( $(now) - t0 ))"
    m tap "label=Replay Ignoring" >/dev/null
    m tap "label=Ignoring target" >/dev/null
    hs="$hs $h"; is="$is $(ms ignoring)"
  done
  rm_line=$(m text testid=reduceMotion)
  printf '%s\tanimations %s\t%s\thonoring %s\tignoring %s\tflow %s\t|%s |%s |%s\n' \
    "$DEVICE" "$1" "$rm_line" \
    "$(echo $hs | median)" "$(echo $is | median)" "$(echo $fs | median)" "$hs" "$is" "$fs"
}

measure on
measure off
