# Demo — turning off the motion, on Android and a real iPhone

The practice half of the talk, in the order the theory went: Android's animation scales, then
Reduce Motion on a real iPhone, then the same calls from an AI agent. Every script drives
MobiumApp's Motion Demo, where the app — not the tool — keeps the time:

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
