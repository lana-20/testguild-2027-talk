#!/bin/sh
# A video of one device, animations on and then off, for the talk.
#
#   IPHONE=<udid> demo/record.sh out.mp4      # a simulator, or a real iPhone
#   ANDROID=<serial> demo/record.sh out.mp4   # an emulator, or a real phone
#
# The flow, at a pace a viewer can follow, on MobiumApp's Motion Demo:
#
#   1. Animations on. Both targets slide in; each is tapped after its
#      Replay, and the app shows how long the tap took. Confetti falls.
#   2. The platform's own switch: all three Android scales to 0, or Reduce
#      Motion on iOS — on a real iPhone a trip through Settings, which is
#      left out of the video.
#   3. Animations off. The same steps: the honoring target is there at once,
#      the ignoring one still slides, and the confetti holds still.
#
# Only MobiumApp is ever on screen in the video: it is recorded in two
# segments, one per condition, each started once the app is in front, and
# joined. The relaunches and the trip through Settings happen between them —
# on somebody's phone those show the home screen, the wallpaper and, at the
# top of Settings, the owner's name. The device's setting is put back
# afterwards, as compare.sh does. Joining needs ffmpeg.
#
# The simulator and Android are recorded by `mobium record`. A real iPhone
# is not — mobium refuses it — so it is recorded from the phone's own USB
# screen by phone-view (demo/phone-view.swift, built beside this script),
# which has to be free to open that screen: close any other viewer first.
# The timings are printed, and written next to the video as <out>.txt.
#
# Besides the joined <out>.mp4, each condition is kept on its own as
# <out>-on.mp4 and <out>-off.mp4, for showing them side by side.
#
# On Android the status bar is put in the system's demo mode while
# recording — 9:41, full bars, no notifications — which is what an iPhone
# shows by itself while its screen is captured. Its setting is put back.
set -e
NOPAUSE=1
OUT="$1"
if [ -z "$OUT" ]; then echo "usage: $0 <out.mp4>" >&2; exit 2; fi
case "$OUT" in /*) ;; *) OUT="$(pwd)/$OUT" ;; esac
. "$(dirname "$0")/lib.sh"
take_animations
hold() { sleep "${1:-1.5}"; }

REAL_IPHONE=
if [ -z "$ANDROID" ] && "$MOBIUM" devices 2>/dev/null | grep "^$IPHONE " | grep -q "(ios device"; then
  REAL_IPHONE=1
  VIEW="$(cd "$(dirname "$0")" && pwd)/phone-view"
  [ -x "$VIEW" ] || fail "no $VIEW: swiftc -O -o demo/phone-view demo/phone-view.swift"
fi

command -v ffmpeg >/dev/null 2>&1 || fail "joining the segments needs ffmpeg"
SEG="${OUT%.*}.seg"
record_start() {   # $1: the segment's file, without extension
  if [ -n "$REAL_IPHONE" ]; then
    "$VIEW" 820 --record "$1.mov" > "$OUT.view.log" 2>&1 &
    VIEW_PID=$!
    i=0; until grep -q "^recording" "$OUT.view.log" 2>/dev/null; do
      i=$((i + 1)); [ $i -lt 40 ] || fail "phone-view did not start recording: $(cat "$OUT.view.log")"
      kill -0 "$VIEW_PID" 2>/dev/null || fail "phone-view exited: $(cat "$OUT.view.log")"
      sleep 0.5
    done
  else
    m record start >/dev/null
  fi
}
record_stop() {    # $1: the same
  if [ -n "$REAL_IPHONE" ]; then
    kill -INT "$VIEW_PID"; wait "$VIEW_PID" || true
    grep -q "^saved" "$OUT.view.log" || fail "phone-view did not save the recording: $(cat "$OUT.view.log")"
    rm -f "$OUT.view.log"
    # The phone's feed carries an audio track too; the video alone, as mp4.
    ffmpeg -v error -y -i "$1.mov" -map 0:v -c copy "$1.mp4" && rm -f "$1.mov"
  else
    m record stop -o "$1.mp4" >/dev/null
  fi
  echo "file '$1.mp4'" >> "$SEG.list"
}
join() {
  ffmpeg -v error -y -f concat -safe 0 -i "$SEG.list" -c copy "$OUT"
  mv "$SEG-on.mp4" "${OUT%.*}-on.mp4"; mv "$SEG-off.mp4" "${OUT%.*}-off.mp4"
  rm -f "$SEG.list"
  echo "saved $OUT: $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT" | cut -c1-5)s"
}

# Android's status bar demo mode, put back as found.
demo_bar() {
  [ -n "$ANDROID" ] || return 0
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

flow() {
  m tap "label=Replay Honoring" >/dev/null; m tap "label=Honoring target" >/dev/null; hold
  m tap "label=Replay Ignoring" >/dev/null; m tap "label=Ignoring target" >/dev/null; hold
  h=$(ms honoring); i=$(ms ignoring)
  m tap "label=Celebrate 🎉" >/dev/null; hold 0.5
  c=$(m text testid=confettiState); hold 3.5
  printf 'animations %-3s  %s  honoring %sms  ignoring %sms  %s\n' "$1" "$(m text testid=reduceMotion)" "$h" "$i" "$c" | tee -a "$OUT.txt"
}

: > "$OUT.txt"; : > "$SEG.list"
demo_bar on
trap 'demo_bar off; restore' EXIT INT TERM
animations on
motion; hold 2.5
record_start "$SEG-on"; hold 1
m tap "label=Back" >/dev/null; m tap "label=Motion Demo" >/dev/null; hold 2.5
flow on
record_stop "$SEG-on"
animations off
motion; hold 2.5
record_start "$SEG-off"; hold 1
m tap "label=Back" >/dev/null; m tap "label=Motion Demo" >/dev/null; hold 2.5
flow off
record_stop "$SEG-off"
join
demo_bar off
restore
trap - EXIT INT TERM
ok "saved $OUT"
