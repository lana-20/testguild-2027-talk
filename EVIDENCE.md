# Where every number in this talk comes from

Every figure on a slide was measured for this talk, with the app under test keeping the time —
MobiumApp's Motion Demo records how long after its own Replay a tap arrived — rather than the
tool reporting on itself. The scripts in `demo/` reproduce them.

**Re-run before quoting anywhere.** A timing is a measurement on one device on one day.

## Devices

| | |
|---|---|
| Real iPhone | iPhone 15 Plus, iOS 26.6.2, over USB |
| iOS simulator | iPhone 17 Pro, iOS 26.5 |
| Real Android phone | Pixel 8 Pro, Android 17 (API 37), over USB |
| Android emulator | Pixel 7 emulator profile, Android 15 (API 35), headless |
| App | MobiumApp, Motion Demo — two targets that slide in over 2 s, identical but for one line |
| Date | 2026-10-04 |

## The numbers

| Claim on a slide | Measured | Script |
|---|---|---|
| iPhone, Reduce Motion on: honoring target 1.3 s | 1298, 1265, 1332, 1297 ms | `demo/reduce-motion.sh` |
| iPhone, Reduce Motion off: honoring target 3.2 s | 3146, 3214, 3163, 3162, 3246 ms | same |
| iPhone control (ignoring target) 3.2 s either way | on: 3180, 3230, 3280, 3246 ms · off: 3229, 3230, 3214, 3164 ms | same |
| 1.3 s is the tool's own round trip | Replay and the tap are two CLI calls; the target is already in place | same |
| iOS Reduce Motion change through Settings ~25 s | 25 s each way on the iPhone | `mobium accessibility reduce_motion off` |
| Android, scales at 1: both targets ~2.5 s | honoring 2516, 2517, 2550, 2601 ms · ignoring 2501, 2534, 2549, 2533 ms | `demo/animation-scales.sh` |
| Android, all scales at 0: honoring well under 1 s | 267, 733, 783, 233, 767 ms | same |
| Android, all scales at 0: ignoring unchanged ~2.5 s | 2599, 2550, 2584, 2618, 2517 ms | same |
| React Native on Android reads the *transition* scale | animator scale 0 alone: `reduceMotion=false`; transition scale 0 alone: `true` | measured by hand, same session |
| A falling confetti piece is refused, exit 6 `timeout` | "failed check stable: it is still moving after 5s", both positions given | `demo/reduce-motion.sh` |
| An untouched emulator reads `animator_duration_scale` as `null` | `settings get global animator_duration_scale` before any change | `demo/animation-scales.sh` restores it by deleting the key |

## Four devices, animations on and off (slide `p4-devices`)

`demo/compare.sh`, one device at a time with nothing else running on the Mac, three rounds per
condition. "Off" is each platform's own switch: Reduce Motion on iOS, all three animation scales
at 0 on Android. Each device's setting was read first and put back after — the iPhone to Reduce
Motion on, the simulator to off, the emulator to `1 1 null`, the Pixel to `1.0 1.0 null`, each
read back. Medians on the slide; every raw value here, in ms.

| Device | Animations | Honoring | Ignoring (control) | Short test |
|---|---|---|---|---|
| iPhone 15 Plus | on | 3230 2897 2829 | 3246 3297 3280 | 10887 10408 10290 |
| | off | 1315 1331 1332 | 3314 3346 2912 | 8942 9138 8940 |
| iPhone 17 Pro simulator | on | 2016 1949 1949 | 1984 2000 2033 | 7179 7113 7234 |
| | off | 933 916 949 | 2016 2017 2017 | 6267 6051 6094 |
| Pixel 8 Pro | on | 3123 3007 3033 | 3094 3086 3104 | 10717 8276 8287 |
| | off | 1457 1225 1267 | 3102 3033 2927 | 6222 6354 5953 |
| Android 15 emulator | on | 2564 2620 2598 | 2534 2550 2517 | 7285 7020 6822 |
| | off | 617 500 250 | 2533 2584 2584 | 4246 4236 4501 |

- **The short test** is wall-clock time for: launch the app, open the Motion Demo, Replay, tap the
  honoring target, read its result. Saved, by median: iPhone 1.5 s (14%), simulator 1.1 s (15%),
  Pixel 2.1 s (25%), emulator 2.8 s (40%).
- **What the extra Android saving is**: on iOS the short test saved about what the honoring
  target saved (1.5 vs 1.6 s; 1.1 vs 1.0 s); on Android, 0.3 s (Pixel) and 0.7 s (emulator)
  more. That the rest is the system's own launch and screen transitions — which the window and
  transition scales cover, and Reduce Motion does not — is the likely reading, **not separately
  measured**.
- **The iPhone's honoring time with animations on is 2.9 s here and 3.2 s on `p4-control`.**
  The procedures differ — here Replay comes straight after the screen opens; `reduce-motion.sh`
  replays a screen that has been open for a while — but why that is worth 0.3 s was not
  established, and the control did not move with it (3.3 s here, 3.2 s there). Each table
  compares its own two conditions, measured the same way.
- The Pixel's first "on" round took 10.7 s against 8.3 s for the next two. The cause was not
  looked into; the median is 8.3 s either way.

## The demo videos (slides `demo-emulator` … `demo-iphone`)

`demo/record.sh` on each device, 2026-10-04, after the four-device table. The app's own
numbers from each recording, in ms — on screen in the clips, and written beside each video:

| Device | Animations on: honoring · control | Off: honoring · control | Confetti |
|---|---|---|---|
| Android 15 emulator | 2547 · 2534 | 249 · 2599 | falling → still |
| Pixel 8 Pro | 3091 · 3120 | 824 · 2932 | falling → still |
| iPhone 17 Pro simulator | 2050 · 2033 | 900 · 2017 | falling → still |
| iPhone 15 Plus | 2996 · 3080 | 1232 · 3130 | falling → still |

- Each clip is one recorded segment, started only once MobiumApp is in front; the relaunch and
  the switch happen between segments and are not in any video. Frames of every video were
  checked for anything else on screen.
- A clip's length is not a timing: it includes the script's pauses for the viewer, and the
  iPhone's off clip runs longer than its on clip. The timings are the app's numbers above.
- Android's status bar is in its demo mode (9:41, no notifications) for the recording, put back
  after; the icon beside the clock is Android's screen-capture indicator. An iPhone shows 9:41
  by itself while its screen is captured.
- Full-resolution originals are kept outside the repo; `deck/media/` holds 1440-pixel-tall
  encodes, under 600 KB each.

## Claims on a slide that are not measurements

| Claim | Basis |
|---|---|
| The one line per framework (`p3-code`) | each platform's documented API: `UIAccessibility.isReduceMotionEnabled`, SwiftUI's `accessibilityReduceMotion`, `ValueAnimator.areAnimatorsEnabled()`, React Native's `AccessibilityInfo.isReduceMotionEnabled()`, CSS `prefers-reduced-motion` |
| Reduce Motion does not replace Settings' own push slide | observed while building the Motion Demo; noted in its source |
| CPU cost of animation (`p1-cost`) | stated, not measured here — the slide says which row was measured |

## Numbers deliberately NOT on a slide

- Suite-level savings ("N minutes per run"). They depend on the app; the talk gives the per-screen cost and lets the audience multiply.
- Any comparison against another tool. This is not a competitive talk, and the CFP penalizes those.
