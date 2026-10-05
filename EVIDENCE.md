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

"By hand" means `mobium` commands typed in the session, before the script that now runs them
existed — the same commands: Replay, tap the target, read the app's result with `mobium text`.
Each value is listed under the source it really came from.

| Claim on a slide | By hand | By script | Script |
|---|---|---|---|
| iPhone, Reduce Motion on: honoring target 1.3 s (earlier `p4-control` and `open-numbers`) | 1298, 1265, 1332 ms | 1297, 1298 ms | `demo/reduce-motion.sh` |
| iPhone, Reduce Motion off: honoring target 3.2 s (earlier `p4-control` and `open-numbers`) | 3146, 3214, 3163 ms | 3162, 3246 ms | same |
| iPhone control (ignoring target) 3.2 s either way (earlier `p4-control`) | on 3180, 3230, 3280 · off 3229, 3230, 3214 ms | on 3246 · off 3164, 3214 ms | same |
| 1.3 s is the tool's own round trip | — | Replay and the tap are two CLI calls; the target is already in place | same |
| iOS Reduce Motion change through Settings ~25 s (`p2-ios`) | 25 s, `mobium accessibility reduce_motion off`, timed | — | — |
| Android, scales at 1: both targets ~2.5 s (`p3-scales`) | honoring 2516, 2517, 2550 · ignoring 2501, 2534, 2549 ms | honoring 2516, 2601 · ignoring 2547, 2533 ms | `demo/animation-scales.sh` |
| Android, all scales at 0: honoring well under 1 s (`p3-scales`) | 267, 733, 783 ms | 233, 767 ms | same |
| Android, all scales at 0: ignoring unchanged ~2.5 s (`p3-scales`) | 2599, 2550, 2584 ms | 2618, 2517 ms | same |
| React Native on Android reads the *transition* scale (`p3-code` notes) | animator scale 0 alone: `reduceMotion=false`; transition scale 0 alone: `true` | — | — |
| A falling confetti piece is refused, exit 6 `timeout` (`p4-stays`) | refused, 5 s, both positions | the same, on the slide | `demo/reduce-motion.sh` |
| An untouched emulator reads `animator_duration_scale` as `null` (`p2-android` notes) | read before any change | restored by deleting the key | `demo/animation-scales.sh` |

The slide `p3-scales` shows the script's run (2533/2517, 2601/767). The iPhone rows fed an earlier
`p4-control` and `open-numbers`; both now show the two clients' runs, below.

## Four devices, two clients (slides `p4-control`, `p4-devices`, `open-numbers`)

The demo test's steps, run through Mobium's two agentic clients: `demo/motion-cli.sh` (the CLI —
each step a `mobium` command, checked against `tests/motion.test.json` before it runs) and
`demo/motion-mcp.py` (MCP — the test file's steps sent to `mobium mcp` as `tools/call` requests).
Three rounds per client per device, one device at a time, 2026-10-04. "Off" is each platform's
own switch, set by the test's first step. Each client read Reduce Motion before and after its
run, and every device came back as found; the Android scales were also read raw before, between
and after (`1 1 null` on the emulator, `1.0 1.0 null` on the Pixel). Raw output in
`demo/results/<device>-<client>.txt`; every value, in ms and seconds:

| Device | Client | Animations | Honoring (ms) | Control (ms) | Case (s) |
|---|---|---|---|---|---|
| iPhone 15 Plus | CLI | on | 3331 3297 3330 | 3414 2879 2897 | 18.73 18.05 18.11 |
|  | CLI | off | 1348 1348 1315 | 3313 3312 3363 | 13.91 13.97 13.84 |
|  | MCP | on | 2830 2847 3346 | 2897 3297 3446 | 17.50 18.03 18.60 |
|  | MCP | off | 1314 1315 1315 | 2864 3430 3398 | 13.33 13.80 13.89 |
| iPhone 17 Pro simulator | CLI | on | 1999 1983 2016 | 1983 2033 2017 | 12.79 12.60 12.48 |
|  | CLI | off | 950 917 900 | 2050 2017 2050 | 8.96 8.86 8.93 |
|  | MCP | on | 2049 2016 2016 | 2000 2000 1950 | 12.43 12.43 12.69 |
|  | MCP | off | 917 916 900 | 2017 2017 1967 | 8.67 8.71 8.65 |
| Pixel 8 Pro | CLI | on | 3191 2995 3084 | 3126 3033 3033 | 17.50 15.97 16.98 |
|  | CLI | off | 1394 1275 1158 | 3087 3146 2982 | 11.07 10.94 11.01 |
|  | MCP | on | 3171 3000 3163 | 3196 3109 3154 | 16.54 16.18 16.90 |
|  | MCP | off | 1215 826 783 | 2969 3153 2981 | 11.01 11.74 11.19 |
| Android 15 emulator | CLI | on | 2599 2530 2547 | 2584 2546 2533 | 12.66 13.13 12.94 |
|  | CLI | off | 250 267 1151 | 2599 2567 2584 | 8.05 8.03 7.22 |
|  | MCP | on | 2515 2565 2619 | 2547 2519 2581 | 13.62 12.68 13.40 |
|  | MCP | off | 1166 1047 234 | 2600 2550 2502 | 7.20 7.17 7.94 |

- **The case** is the test from opening the Motion Demo to its last check — replay and tap both
  targets, celebrate, wait for the confetti — so not the setting switch before it (25 s through
  Settings on an iPhone) and not the launch. With animations on it also waits out the falling
  confetti, which is animation too. Saved, by median: iPhone 4.2 s (23%) through either client,
  simulator 3.7–3.8 s (29–30%), Pixel 5.4–6.0 s (32–35%), emulator 4.9–6.2 s (38–46%).
- **Honoring with the motion off lands at two levels on Android** — about 0.25 or about 1.1 s —
  in both clients: how long Mobium's tap takes to confirm the target is still, depending on when
  its read meets the app's redraw. A median of three can fall on either, which is why the CLI and
  MCP rows differ there, not because of the client. The iOS devices are steady.
- **The iPhone's control** moved between its on and off medians by up to 0.4 s, within its own
  spread of 2.86–3.45 s on both sides.
- **`open-numbers`** shows round 1 of the CLI on the iPhone: 3331 ms on, 1348 ms off.

## Earlier: four devices by `compare.sh` (no longer on a slide)

Measured before the demo test existed, with a different flow and a different span; superseded on
the slides by the two clients above, kept for the record. `demo/compare.sh`, one device at a
time with nothing else running on the Mac, three rounds per
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

## The demo videos (slides `demo-code` … `demo-iphone`)

Every video is one device running `demo/tests/motion.test.json` — the same file on all four —
under `demo/record.sh`, 2026-10-04. Each test passed on each device (`demo/results/runs.txt`).
The app's own numbers, read from each clip's last frame, in ms:

| Device | Animations on: honoring · control | Off: honoring · control | Confetti |
|---|---|---|---|
| Android 15 emulator | 2517 · 2584 | 233 · 2533 | done → still |
| Pixel 8 Pro | 3114 · 2876 | 1192 · 3140 | done → still |
| iPhone 17 Pro simulator | 2016 · 2033 | 917 · 2066 | done → still |
| iPhone 15 Plus | 3213 · 3213 | 1282 · 3114 | done → still |

- **The cut**, by `demo/keep-app.py`: only frames close to the Motion Demo are kept. On the iPhone
  every kept frame scored at most 38 and every rejected one — home screen, Settings, launches —
  at least 46, against a cut-off of 40; on the Pixel, 28 and 43. Each written file was checked
  frame by frame. Raw recordings of the phones were deleted once their cuts were checked.
- **The clips end before the restore.** The session puts the setting back the moment the last
  case passes; on the emulator, simulator and Pixel the app redrew itself within a second, and
  those last frames are trimmed (a jump of 33–37 between two frames).
- **The iPhone's video is from a second run.** The first, at 22:13, passed but left Reduce Motion
  off when it had been on; it was put back on the Settings switch, and two runs after it
  restored correctly. The video is from the second of those (22:35). Cause open: Mobium's ROADMAP.
- A clip's length is not a timing: it includes waits for what the test checks.
- Full-resolution originals are kept outside the repo; `deck/media/` holds 1440-pixel-tall
  encodes, under 500 KB each.

## Claims on a slide that are not measurements

| Claim | Basis |
|---|---|
| The one line per framework (`p3-code`) | each platform's documented API: `UIAccessibility.isReduceMotionEnabled`, SwiftUI's `accessibilityReduceMotion`, `ValueAnimator.areAnimatorsEnabled()`, React Native's `AccessibilityInfo.isReduceMotionEnabled()`, CSS `prefers-reduced-motion` |
| Reduce Motion does not replace Settings' own push slide | observed while building the Motion Demo; noted in its source |
| CPU cost of animation (`p1-cost`) | stated, not measured here — the slide says which row was measured |

## Numbers deliberately NOT on a slide

- Suite-level savings ("N minutes per run"). They depend on the app; the talk gives the per-screen cost and lets the audience multiply.
- Any comparison against another tool. This is not a competitive talk, and the CFP penalizes those.
