# Shared by the demo scripts. Sourced, not run.
#
#   MOBIUM   the mobium binary (default: mobium on PATH)
#   IPHONE   the phone's UDID (default: the one iPhone mobium lists)
#   ANDROID  an Android serial; set by the Android script, which drives that instead
MOBIUM="${MOBIUM:-mobium}"
command -v "$MOBIUM" >/dev/null 2>&1 || { echo "no mobium binary: set MOBIUM=/path/to/mobium" >&2; exit 2; }
if [ -n "$ANDROID" ]; then
  DEVARGS="--device $ANDROID"
else
  if [ -z "$IPHONE" ]; then
    IPHONE=$("$MOBIUM" devices 2>/dev/null | awk '/\(ios device/ { print $1; exit }')
  fi
  [ -n "$IPHONE" ] || { echo "no iPhone connected: plug it in, unlock it, and check 'mobium devices'" >&2; exit 2; }
  DEVARGS="--driver wda --device $IPHONE"
fi
APP=dev.mobium.mobiumapp

B=$(printf '\033[1m'); DIM=$(printf '\033[2m'); G=$(printf '\033[32m'); R=$(printf '\033[31m')
C=$(printf '\033[36m'); Y=$(printf '\033[33m'); N=$(printf '\033[0m')

# m runs mobium against the phone, quietly.
m() { "$MOBIUM" $DEVARGS "$@"; }
# show prints the command the way it would be typed, then runs it.
show() { printf '%s$ mobium %s%s\n' "$C" "$*" "$N"; m "$@"; }
say() { printf '\n%s%s%s\n' "$B" "$*" "$N"; }
note() { printf '%s  %s%s\n' "$DIM" "$*" "$N"; }
ok() { printf '%s  ✓ %s%s\n' "$G" "$*" "$N"; }
fail() { printf '%s  ✗ %s%s\n' "$R" "$*" "$N" >&2; exit 1; }
pause() { [ -n "$NOPAUSE" ] || { printf '%s  ⏎%s' "$DIM" "$N"; read -r _; }; }

# ms prints the number of milliseconds in an app's "tapped 1298ms after replay".
ms() { m text "testid=$1Result" | sed -n 's/.*tapped \([0-9]*\)ms.*/\1/p'; }

# motion opens MobiumApp's Motion Demo from a fresh launch.
motion() {
  m terminate "$APP" >/dev/null 2>&1 || true
  m launch "$APP" >/dev/null || fail "could not launch MobiumApp"
  m scroll-to "label=Motion Demo" >/dev/null 2>&1 || true
  m tap "label=Motion Demo" >/dev/null || fail "MobiumApp has no Motion Demo"
  m wait "testid=reduceMotion" >/dev/null || fail "the Motion Demo did not come up"
}
