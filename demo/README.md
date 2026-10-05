# Demo — turning off the motion, on Android and a real iPhone

The practice half of the talk, in the order the theory went: Android's animation scales, then
Reduce Motion on a real iPhone, then the same calls from an AI agent. Every script drives
MobiumApp's Motion Demo ([mobiumdev/mobium-app](https://github.com/mobiumdev/mobium-app)), where the app — not the tool — keeps the time:

- **honoring** slides in over two seconds, and appears at once when the platform says motion
  should be reduced;
- **ignoring** always slides. It is the **control**: if its time moves when a setting does, the
  measurement is measuring something else.

Each target records how long after its own Replay the tap arrived. Mobium waits for a target to
stop moving before it touches it, so a slide is time the test spends waiting.

Measured on 2026-10-04: an Android 15 emulator, and an iPhone 15 Plus on iOS 26.6.2 over USB.

## Before recording

1. **Mobium**: `MOBIUM=/path/to/mobium` if it is not on `PATH`.
2. **The emulator**: booted, with MobiumApp installed.
3. **The phone**: plugged in, unlocked, Auto-Lock off for the session, MobiumApp installed, and
   **Reduce Motion on** — the iPhone script starts only from there, and puts it back there.
   `IPHONE` is found by `mobium devices`; set it to choose.
4. **The phone on screen**: `phone-view`, a window showing the phone's own screen over USB:

   ```sh
   swiftc -O -o demo/phone-view demo/phone-view.swift
   demo/phone-view 820 &     # window height in points
   ```

   It opens the phone's screen source only, never a camera. The first time, the phone asks
   **"Are you connecting a pair of headphones?"** — answer **Other Device**. While it runs, the
   status bar reads 9:41 with full bars: iOS's own clean status bar for screen capture.

## The beats

| Script | Time | Part | What it shows |
|---|---|---|---|
| `animation-scales.sh <serial>` | ~40 s | 2, 3 | the standard three scales at 0: the app animation that listens stops, the one on its own clock does not |
| `reduce-motion.sh` | ~2 min | 2, 3, 4 | Reduce Motion moves the honoring target and not the control; confetti stays still, and a falling piece is refused |
| `mcp-session.py` | ~30 s | — | the same calls from an agent's side, over MCP |
| `compare.sh` | 1–3 min a device | 4 | not a stage beat: the four-device table on `p4-devices`, animations on and off |
| `tests/motion.test.json` | — | demo | **the demo itself**: one Mobium test, run unchanged on all four devices by `mobium test`; on `demo-code` |
| `record.sh <project> <out.mp4>` | 1–2 min a device | demo | records a device running that test: the videos on `demo-emulator` … `demo-iphone` |
| Claude Code | live | Q&A | an agent driving the phone through `mcp.json` |

Each script pauses at every beat — press return. `NOPAUSE=1` runs straight through for a rehearsal.

### `animation-scales.sh` — Android

| | scales at 1 | all three at 0 |
|---|---|---|
| honoring | 2.6 s | **0.8 s** |
| ignoring | 2.5 s | **2.5 s** |

The three `adb shell settings put global … 0` commands are shown as typed, then read back: every
one says 0. The app, opened fresh, reports `reduceMotion=true` — the zeroed scales are how Android
says so — and the honoring target appears at once. The ignoring one slides for two and a half
seconds anyway: the scales reach an app's animation only when the app asks.

The scales are device-wide. The script reads them first and puts back exactly what it found — a
value, or no value at all, which is how an untouched emulator reads `animator_duration_scale` —
when it ends, also on a failure. It refuses anything but an emulator unless `ALLOW_PHONE=1`.

### `reduce-motion.sh` — real iPhone

| | Reduce Motion on | off |
|---|---|---|
| honoring | **1.3 s** | **3.2 s** |
| ignoring (the control) | 3.2 s | 3.2 s |

About 1.3 s is the tool's own round trip — Replay and the tap are two calls. The rest is Mobium
waiting for the target to stop moving.

- **The control** held at 3.2 s on every run; the script fails if it moves by 500 ms.
- **Confetti**: with Reduce Motion on, `confetti: still: reduce motion 🎉 Done`; off, `falling`.
  Then the switch that puts the pieces in the tree, and a tap on a falling one: **exit 6,
  `timeout`** — "failed check stable: it is still moving after 5s", with both positions. A target
  that never holds still is refused, not chased.
- **The switch**: `mobium accessibility reduce_motion off` drives the Settings app — about 25 s
  each way, on screen; a real iPhone takes no setting from outside. Then `… on`, read back from
  the Settings switch and from the app. If the script dies on the way, a trap puts it back on; the
  session puts it back again when it ends.

### `mcp-session.py` — an agent's side

Spawns `mobium mcp` and prints every JSON-RPC request and result: `initialize`, `tools/list`
(71 tools), then the Honoring tap with the app as witness. Then an error an agent can act on:
`app_check label=Pieces visible to automation` is refused — React Native repeats the label across
two views — with `structuredContent` `{"code": "ambiguous_locator", "remedy": "… or use a ref
from app_map"}`. The remedy is followed literally: `app_map`, then `app_check @e7` twice — "now
checked", then "already checked".

It stops the CLI's daemon first: a phone holds one automation session, and `mobium mcp` opens its own.

### Claude Code, for the Q&A

```sh
claude --mcp-config demo/mcp.json --strict-mcp-config
```

`mcp.json` reads `MOBIUM` and `IPHONE` from the environment. Run `mobium daemon stop` first, and
don't run the scripts while the agent is attached — the same one-session rule. Tested 2026-10-04:
asked to read `reduceMotion`, tap Replay Honoring and the target, and report, it answered "tapped
1299ms after replay" in 19 s.

Prompts that work against this screen and change nothing on the phone:

- "Read the Motion Demo and tell me whether this app honors Reduce Motion. Prove it with a
  control, without changing any setting."
- "Tap the Ignoring target. How do you know the tap arrived?"
- "Turn on 'Pieces visible to automation', press Celebrate, and tap a piece of confetti. What
  happened, and why?"

Anything that changes Reduce Motion: say in the prompt to put it back on and read the switch.

### `compare.sh` — the evidence table

`IPHONE=<udid>` for a real iPhone or a simulator, `ANDROID=<serial>` for an emulator or a phone.
Animations on, then off, three rounds each (`ROUNDS=` to change): the honoring and ignoring times
as the app counts them, and the wall-clock time of a short test — launch, open the Motion Demo,
Replay, tap, read. One tab-separated line per condition, medians first and every raw value after.
It reads the device's setting first and puts it back at the end, also on a failure; on Android
exactly as found, a missing key included. Run one device at a time — two measurements on one Mac
slow each other down. The 2026-10-04 run is in `EVIDENCE.md`.

### The demo: one test, four devices

`tests/motion.test.json` is the code the demo ran — the same file on every device, nothing but
the device changing. `mobium.config.json` names the four as projects, each taking its device from
the environment:

```sh
cd demo
MOBIUM_EMULATOR=emulator-5554 MOBIUM_PIXEL=<serial> \
MOBIUM_SIMULATOR=<udid> MOBIUM_IPHONE=<udid> mobium test --workers 1
```

Two cases from one `each`: animations on (Reduce Motion off) and off (Reduce Motion on). Each
switches the platform's own setting through `app_accessibility` — the three scales on Android,
the Settings app on an iPhone — opens the Motion Demo, checks what the app says
(`reduceMotion=…`), taps both targets after their Replay, presses Celebrate, and waits for the
confetti to read `confetti: done` or `still: reduce motion`. Every test starts from a fresh
launch, and the run's session puts the setting back when it ends. The runs behind the slides are
in `results/runs.txt`: eight passes, two per device.

### `record.sh` — the videos of that test

`demo/record.sh <project> <out.mp4>`, the project's device variable set as above. It starts a
screen recorder that holds no automation session — screenrecord on Android, simctl on the
simulator, `phone-view --record` on a real iPhone — runs `mobium test --project <project>`,
stops the recorder the moment the last case reports, and cuts the video with `keep-app.py`.

- **Only the Motion Demo is kept.** Each frame is scored against the recording's last frame; a
  launch, a home screen, MobiumApp's own home list and Settings score far from it. Measured on
  the iPhone: everything kept at most 38, everything rejected at least 46, the cut-off at 40. The
  written file is checked frame by frame against it and deleted if one frame fails. The raw
  recording is kept as `<out>.raw.mp4` for checking — on a phone it shows the home screen and
  Settings, whose first screen shows the owner's name: check the cut, then delete it.
- **The setting put back is not in the video.** The session restores it the moment the last case
  passes, and an app that listens redraws itself; the last case's clip ends before that redraw.
- **The setting is checked, not trusted.** The script reads it before the run and after the
  session ends, and fails loudly if they differ, saying how to put it back by hand. One run on
  the iPhone left Reduce Motion off when it had been on; two runs after it did not, and the cause
  is open (Mobium's ROADMAP).
- **A clean status bar:** 9:41 and full bars — Android's demo mode, the simulator's status-bar
  override, and an iPhone shows it by itself while captured. Each put back after.
- Writes `<out>.mp4`, and `<out>-on.mp4` and `<out>-off.mp4` for the side-by-side slides. Needs
  ffmpeg. The test's own pass or fail is in `<out>.txt`.

## Why not iPhone Mirroring

Re-measured on 2026-10-04: while Mirroring is connected, the phone is locked to it and touch
belongs to it. MobiumApp, already open, read as one empty line, and `tap label=Motion Demo`
answered "tapped at (645, 2136)" while the Mirroring window still showed the home list — a tap
reported as done that never arrived. Over USB, with `phone-view` open, the same taps land and the
app says so.

## Not a beat, on purpose

A tap at coordinates read from an earlier `map`, right after Replay, was measured as a contrast
and **still landed** (three of three, ~1.3 s): the slide eases out, so by then the target is 96%
of the way home. A failure that does not happen is not staged.
