#!/bin/sh
# Records one device running the demo test, for the talk's video slides.
#
#   demo/record.sh <project> <out.mp4>
#
# The project is one in demo/mobium.config.json — emulator, pixel, simulator
# or iphone — with its device in the variable the config names
# (MOBIUM_EMULATOR, MOBIUM_PIXEL, MOBIUM_SIMULATOR, MOBIUM_IPHONE).
#
# What drives the app is tests/motion.test.json and nothing else: this script
# only starts a screen recorder, runs `mobium test --project <project>`, stops
# the recorder, and cuts the video down to the Motion Demo (keep-app.py). The
# recorder is one that holds no automation session — Mobium's own would
# compete with the test's for the one session a device allows:
#
#   Android    screenrecord, on the device; the file is pulled and deleted
#   simulator  simctl's recordVideo
#   iPhone     phone-view --record, from the phone's USB screen — build it
#              with: swiftc -O -o demo/phone-view demo/phone-view.swift
#
# The status bar reads 9:41 with full bars, as an iPhone shows by itself
# while captured: on Android through its demo mode, on the simulator through
# simctl's override — each put back after. The test's own session puts back
# Reduce Motion when it ends.
#
# Writes <out>.mp4, <out>-on.mp4 and <out>-off.mp4, and keeps the uncut
# recording as <out>.raw.mp4 — which may show a home screen or Settings:
# check the cut, then delete the raw file.
set -e
PROJECT="$1"; OUT="$2"
if [ -z "$PROJECT" ] || [ -z "$OUT" ]; then echo "usage: $0 <project> <out.mp4>" >&2; exit 2; fi
case "$OUT" in /*) ;; *) OUT="$(pwd)/$OUT" ;; esac
HERE="$(cd "$(dirname "$0")" && pwd)"
MOBIUM="${MOBIUM:-mobium}"
ADB="${ADB:-adb}"
RAW="${OUT%.*}.raw.mp4"
fail() { echo "FAIL: $*" >&2; exit 1; }
command -v ffmpeg >/dev/null 2>&1 || fail "cutting the video needs ffmpeg"

case "$PROJECT" in
  emulator)  DEV="$MOBIUM_EMULATOR";  KIND=android ;;
  pixel)     DEV="$MOBIUM_PIXEL";     KIND=android ;;
  simulator) DEV="$MOBIUM_SIMULATOR"; KIND=simulator ;;
  iphone)    DEV="$MOBIUM_IPHONE";    KIND=iphone ;;
  *) fail "unknown project $PROJECT: emulator, pixel, simulator or iphone" ;;
esac
[ -n "$DEV" ] || fail "the $PROJECT project's device variable is not set — see demo/mobium.config.json"
a() { "$ADB" -s "$DEV" shell "$@" | tr -d '\r'; }

demo_bar() {
  if [ "$1" = on ]; then
    was_demo=$(a settings get global sysui_demo_allowed)
    a settings put global sysui_demo_allowed 1
    for c in "enter" "clock -e hhmm 0941" "notifications -e visible false" \
             "battery -e level 100 -e plugged false" "network -e wifi show -e level 4 -e mobile show -e level 4"; do
      a am broadcast -a com.android.systemui.demo -e command $c >/dev/null
    done
  else
    a am broadcast -a com.android.systemui.demo -e command exit >/dev/null
    if [ "$was_demo" = null ]; then a settings delete global sysui_demo_allowed >/dev/null; else a settings put global sysui_demo_allowed "$was_demo"; fi
  fi
}

ONDEV=/sdcard/mobium-demo-recording.mp4
REC=
record_start() {
  case "$KIND" in
    android)
      demo_bar on
      "$ADB" -s "$DEV" shell screenrecord --bit-rate 12000000 "$ONDEV" >/dev/null 2>&1 &
      REC=$! ;;
    simulator)
      xcrun simctl status_bar "$DEV" override --time 9:41 --dataNetwork wifi --wifiBars 3 --cellularBars 4 --batteryState charged --batteryLevel 100
      xcrun simctl io "$DEV" recordVideo --codec=h264 --force "$RAW" >/dev/null 2>&1 &
      REC=$! ;;
    iphone)
      [ -x "$HERE/phone-view" ] || fail "no $HERE/phone-view: swiftc -O -o demo/phone-view demo/phone-view.swift"
      "$HERE/phone-view" 820 --record "${RAW%.mp4}.mov" > "$OUT.view.log" 2>&1 &
      REC=$!
      i=0; until grep -q "^recording" "$OUT.view.log" 2>/dev/null; do
        i=$((i + 1)); [ $i -lt 40 ] || fail "phone-view did not start: $(cat "$OUT.view.log")"
        sleep 0.5
      done ;;
  esac
  sleep 2
}
record_stop() {
  sleep 0.3
  case "$KIND" in
    android)
      a pkill -INT screenrecord || true; wait "$REC" || true; sleep 1
      "$ADB" -s "$DEV" pull "$ONDEV" "$RAW" >/dev/null
      a rm -f "$ONDEV"
      demo_bar off ;;
    simulator)
      kill -INT "$REC"; wait "$REC" || true
      xcrun simctl status_bar "$DEV" clear ;;
    iphone)
      kill -INT "$REC"; wait "$REC" || true
      grep -q "^saved" "$OUT.view.log" || fail "phone-view did not save: $(cat "$OUT.view.log")"
      rm -f "$OUT.view.log"
      ffmpeg -v error -y -i "${RAW%.mp4}.mov" -map 0:v -c copy "$RAW" && rm -f "${RAW%.mp4}.mov" ;;
  esac
  REC=
}
cleanup() {
  [ -n "$REC" ] && kill -INT "$REC" 2>/dev/null
  if [ "$KIND" = android ]; then
    a pkill -INT screenrecord >/dev/null 2>&1; a rm -f "$ONDEV" >/dev/null 2>&1; demo_bar off >/dev/null 2>&1
  fi
  [ "$KIND" = simulator ] && xcrun simctl status_bar "$DEV" clear >/dev/null 2>&1
  exit 1
}
trap cleanup INT TERM

# The device's animation setting, read before the run and again after its
# session has ended, which is when the test puts back what it changed. On
# 2026-10-04 one run on a real iPhone left Reduce Motion off when it had been
# on; two runs after it did not, and the cause is not known. So the setting is
# checked rather than trusted — and not fixed here: a fix through `mobium
# accessibility` records an undo of its own, which is how a person's settings
# were left changed once before. Android is read raw, all three scales, so
# "not set at all" is told apart from 1.
setting_now() {
  if [ "$KIND" = android ]; then
    echo "$(a settings get global window_animation_scale) $(a settings get global transition_animation_scale) $(a settings get global animator_duration_scale)"
  else
    "$MOBIUM" --driver wda --device "$DEV" accessibility reduce_motion | awk '{ print $2 }'
    # The test's run needs the device's one session: this read's must end.
    "$MOBIUM" daemon stop >/dev/null 2>&1 || true
  fi
}
before=$(setting_now)
[ -n "$before" ] || fail "could not read the $PROJECT device's animation setting before the run"

record_start
# The recorder stops as soon as the last case reports, not when the run
# exits: the end of the test's session puts Reduce Motion back, and an app
# that listens to the setting redraws itself, sliding, on camera.
: > "$OUT.txt"
( cd "$HERE" && "$MOBIUM" test --project "$PROJECT" --workers 1 --reporter list ) > "$OUT.txt" 2>&1 &
TEST=$!
until grep -q "animations off" "$OUT.txt" 2>/dev/null || ! kill -0 "$TEST" 2>/dev/null; do sleep 0.2; done
record_stop
set +e
wait "$TEST"; st=$?
set -e
cat "$OUT.txt"
trap - INT TERM

after=$(setting_now)
changed=
if [ "$after" != "$before" ]; then
  changed=1
  if [ "$KIND" = android ]; then
    echo "WARNING: the animation scales were \"$before\" (window transition animator) before the run and are \"$after\" now — put each back with adb shell settings put global <scale> <value>, or settings delete global <scale> where it was null" >&2
  else
    echo "WARNING: Reduce Motion was $before before the run and is $after now — put it back with the switch in Settings › Accessibility › Motion, not with mobium accessibility, whose undo would replay when its session ends" >&2
  fi
else
  echo "animation setting as found: $after"
fi

[ "$st" = 0 ] || fail "the test did not pass on $PROJECT — see $OUT.txt; the raw recording is $RAW"
python3 "$HERE/keep-app.py" "$RAW" "$OUT"
echo "saved $OUT, ${OUT%.*}-on.mp4, ${OUT%.*}-off.mp4 — check them, then delete $RAW"
[ -z "$changed" ] || exit 1
