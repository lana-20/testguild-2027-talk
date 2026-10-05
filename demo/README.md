# Demo — a real iPhone, from the terminal

Two front doors to the same phone: the CLI (`reduce-motion.sh`) and MCP
(`mcp-session.py`, and Claude Code for the live Q&A). Both drive MobiumApp's
Motion Demo, where the app — not the tool — keeps the time.

Measured on 2026-10-04: iPhone 15 Plus, iOS 26.6.2, over USB.

## Before recording

1. **The phone**: plugged in, unlocked, Auto-Lock off for the session,
   MobiumApp installed, and **Reduce Motion on** — the script starts only
   from there, and puts it back there.
2. **Mobium**: `MOBIUM=/path/to/mobium` if it is not on `PATH`. `IPHONE` is
   found by `mobium devices`; set it to choose.
3. **The phone on screen**: `phone-view`, a window showing the phone's own
   screen over USB:

   ```sh
   swiftc -O -o demo/phone-view demo/phone-view.swift
   demo/phone-view 820 &     # window height in points
   ```

   It opens the phone's screen source only, never a camera. The first time,
   the phone asks **"Are you connecting a pair of headphones?"** — answer
   **Other Device**. While it runs, the phone's status bar reads 9:41 with
   full bars: iOS's own clean status bar for screen capture.

## The beats

| Script | Time | Act | What it shows |
|---|---|---|---|
| `reduce-motion.sh` | ~2 min straight through | I, III | the setting moves the honoring target and not the control; a falling piece is refused |
| `mcp-session.py` | ~30 s | II | the same tools over MCP; an error with a code and a remedy, followed literally |
| Claude Code | live | Q&A | an agent driving the phone through `mcp.json` |

Both scripts pause at every beat — press return. `NOPAUSE=1` runs straight
through for a rehearsal.

### `reduce-motion.sh`

| | Reduce Motion on | off |
|---|---|---|
| honoring | **1.3 s** | **3.2 s** |
| ignoring (the control) | 3.2 s | 3.2 s |

Measured three times each way, within 70 ms. About 1.3 s is the tool's own
round trip — Replay and the tap are two calls. The rest is Mobium waiting for
the target to stop moving.

- **The control is the point** (Act I). If the ignoring target's time moved
  with the setting, the measurement would be measuring something else; the
  script fails if it moves by 500 ms.
- **Confetti**: with Reduce Motion on, `confetti: still: reduce motion 🎉 Done`;
  off, `falling`. Then the switch that puts the pieces in the tree, and a tap
  on a falling one: **exit 6, `timeout`** — "failed check stable: it is still
  moving after 5s", with both positions. A target that never holds still is
  refused, not tapped (Act III).
- **The restore**: `accessibility reduce_motion on`, read back from the
  Settings switch and from the app. If the script dies on the way, a trap puts
  it back; the session puts it back again when it ends.
- Switching the setting goes through the Settings app — about 25 s each way,
  and on screen. A real iPhone takes no setting from outside.

### `mcp-session.py`

Spawns `mobium mcp` and prints every JSON-RPC request and result:
`initialize`, `tools/list` (71 tools), then the Honoring tap with the app as
witness. Then the beat: `app_check label=Pieces visible to automation` is
refused — React Native repeats the label across two views — with
`structuredContent` `{"code": "ambiguous_locator", "remedy": "… or use a ref
from app_map"}`. The remedy is followed literally, as an agent would:
`app_map`, then `app_check @e7` twice — "now checked", then "already
checked". A state reached, and read back to say so.

It stops the CLI's daemon first: a phone has one WebDriverAgent session, and
`mobium mcp` holds its own.

### Claude Code, for the Q&A

```sh
claude --mcp-config demo/mcp.json --strict-mcp-config
```

`mcp.json` reads `MOBIUM` and `IPHONE` from the environment. Run
`mobium daemon stop` first, and don't run the scripts while the agent is
attached — same one-session rule. Tested 2026-10-04 with a prompt to read
`reduceMotion`, tap Replay Honoring and the target, and report: it answered
"tapped 1299ms after replay" in 19 s.

Prompts that work against this screen, and change nothing on the phone:

- "Read the Motion Demo and tell me whether this app honors Reduce Motion.
  Prove it with a control, without changing any setting."
- "Tap the Ignoring target. How do you know the tap arrived?"
- "Turn on 'Pieces visible to automation', press Celebrate, and tap a piece of
  confetti. What happened, and why?"

Anything that changes Reduce Motion: say in the prompt to put it back on and
read the switch to confirm.

## Why not iPhone Mirroring

Re-measured on 2026-10-04, the same as on 2026-09-23 (Mobium's
`docs/IPHONE-MIRRORING.md`):

- Mirroring connects only while the phone is locked, and WebDriverAgent then
  reports it **unlocked**.
- MobiumApp, already open, read as **one empty line**; relaunched, 22.
- `tap label=Motion Demo` answered **"tapped at (645, 2136)"** — and the
  Mirroring window still showed the home list. Touch belongs to Mirroring;
  the tap was dropped, and reported as done.

It is a good slide for Act II — a tool saying "tapped" about a tap that never
arrived — but it cannot carry a live beat. Over USB, with `phone-view` open,
the same taps land and the app says so.

## Not a beat, on purpose

A tap at coordinates read from an earlier `map`, right after Replay, was
measured as a contrast and **still landed** (three of three, ~1.3 s): the
slide eases out, so by then the target is 96% of the way home. A failure that
does not happen is not staged.
