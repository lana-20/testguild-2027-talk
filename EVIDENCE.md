# Where every number in this talk comes from

Every figure on a slide was measured for this talk, with the app under test keeping the time —
MobiumApp's Motion Demo records how long after its own Replay a tap arrived — rather than the
tool reporting on itself. The scripts in `demo/` reproduce them.

**Re-run before quoting anywhere.** A timing is a measurement on one device on one day.

## Devices

| | |
|---|---|
| Real iPhone | iPhone 15 Plus, iOS 26.6.2, over USB |
| Android | Pixel 7 emulator profile, Android 15 (API 35), headless |
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

## Claims on a slide that are not measurements

| Claim | Basis |
|---|---|
| The one line per framework (`p3-code`) | each platform's documented API: `UIAccessibility.isReduceMotionEnabled`, SwiftUI's `accessibilityReduceMotion`, `ValueAnimator.areAnimatorsEnabled()`, React Native's `AccessibilityInfo.isReduceMotionEnabled()`, CSS `prefers-reduced-motion` |
| Reduce Motion does not replace Settings' own push slide | observed while building the Motion Demo; noted in its source |
| CPU cost of animation (`p1-cost`) | stated, not measured here — the slide says which row was measured |

## Numbers deliberately NOT on a slide

- Suite-level savings ("N minutes per run"). They depend on the app; the talk gives the per-screen cost and lets the audience multiply.
- Any comparison against another tool. This is not a competitive talk, and the CFP penalizes those.
