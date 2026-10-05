# Run of show — 25 minutes

Pre-recorded on TestGuild's own deck template, then ~20 minutes of live Q&A.
Theory first, practice last: everything the demo shows has been explained before it runs.
The umbrella is **fast and durable mobile tests, with Mobium**; turning off motion is the
technique, and each part ends on what Mobium does about it.
Slide ids in brackets match `deck/slides/<id>.html`.

| Time | Beat | Slides |
|---|---|---|
| 0:00–1:30 | Cold open — the same tap, 3.2 s and 1.3 s | `cover` `open-numbers` |
| 1:30–3:00 | Animations are for humans | `premise` |
| 3:00–6:30 | **Part 1** — what motion costs a test | `part1` `p1-cost` `p1-two-kinds` |
| 6:30–10:30 | **Part 2** — the system's animations | `part2` `p2-android` `p2-ios` `p2-rule` |
| 10:30–15:00 | **Part 3** — the app's own animations | `part3` `p3-scales` `p3-two-fixes` `p3-code` `p3-rule` |
| 15:00–17:30 | **Part 4** — proving it, and what stays | `part4` `p4-control` `p4-devices` `p4-stays` |
| 17:30–23:30 | **Demo** — four devices, recorded, animations on and off side by side | `demo` `demo-code` `demo-run` `demo-emulator` `demo-pixel` `demo-simulator` `demo-iphone` `demo-results` |
| 23:30–25:00 | Habits, and the conclusion | `habits` `close` |

## 0:00–1:30 — Cold open

Open on the two numbers. Same app, same target, same tap: 3.2 seconds, then 1.3.

> "Same screen. Same button. Same tap. One run took three point two seconds, the other one point three. Nothing about the test changed. One setting on the phone did, and one line in the app."

Name yourself in one line, then the premise.

## 1:30–3:00 — Premise

> "Animations are for humans. They're how a person follows what changed on a screen. Your test isn't a person — every animation is either time it waits, or a race it can lose."

## 3:00–6:30 — Part 1: what motion costs

Three costs: **time** (a tool waits for the screen to settle — about two seconds per sliding target, measured on both platforms), **races** (a tap aimed at something still moving; a read halfway through a transition), and **CPU** on the device under test. Then the distinction the rest hangs on: the **system's** animations (transitions between screens and apps) and the **app's own** (anything the app animates itself).

## 6:30–10:30 — Part 2: the system's animations

Android: three `settings put global` commands, no root, emulator or phone — and put them back after, because on a phone they belong to somebody. iOS: no command at all. Reduce Motion is in Settings › Accessibility › Motion, and changing it from a test means driving the Settings app — about 25 seconds a change on a real iPhone. So: once per device, in setup, never per test. **Mobium:** `mobium accessibility reduce_motion on` is one call on both — the three scales on Android, a trip through Settings on an iPhone — read back, and put back when the session ends. Then the caveat the slide carries: read it afterwards anyway — one run on the iPhone left Reduce Motion off when it had been on, put back by hand, cause still open. It is the talk's own rule, applied to the tool.

## 10:30–15:00 — Part 3: the app's own animations

The measurement: with all three Android scales at 0, an animation on the app's own clock still took 2.5 seconds — unchanged. The one that asked whether motion was reduced appeared at once. Two ways to close the gap: a **test build** with every duration at zero, or an app that **honors Reduce Motion**. Recommend the second: the fast path is then a real path, in the build you ship, and it is an accessibility fix the app owes its users anyway. Show the one line per framework.

## 15:00–17:30 — Part 4: proving it, and what stays

Let the app time itself, and keep one animation that ignores the setting as the **control**: if the control's time moves when the setting does, the measurement is measuring something else. Then the same measurement on four devices — real iPhone, simulator, real Pixel, emulator: a short test saved 14–40%, and the control held flat on every one. Then the motion you cannot turn off — spinners, confetti, live content: wait for stillness, and refuse a target that never holds still rather than chase it. **Mobium:** every action waits for its target to stop moving, and a target still moving after five seconds is refused with exit 6, `timeout`, and both positions it was seen at.

## 17:30–23:30 — Demo

Recorded, not live. First the code: one Mobium test, `demo/tests/motion.test.json`, and the
config naming four devices — the same file ran on all of them (`demo-code`, `demo-run`). Then
four videos of it running, made by `demo/record.sh` — the Android emulator, the real Pixel, the
iPhone simulator, the real iPhone, in the order the theory went. Each slide plays
the same steps twice side by side: animations on, then with the platform's own switch off.
Narrate one slide fully (the emulator: the honoring target is in place before the tap, the
control still slides, the confetti holds still), then let the other three confirm it in about
a minute each. Only MobiumApp is ever on screen; the switch itself, on the iPhone a trip
through Settings, happens between the two clips. The live terminal beats
(`reduce-motion.sh`, `mcp-session.py`) and the agent stay for the Q&A.

## 23:30–25:00 — Close

The four habits on one card, then the conclusion, close to verbatim:

> "Turn off every animation you can — the system's with a setting, the app's by having it listen to that setting — and wait out the rest. You'll get time back, and you'll take a whole class of races out of your suite. How much time depends on your app and how much it moves. But every second you take off a test comes off the feedback loop of everyone who waits on your build."

---

## Fit and slack

Roughly **2 minutes of slack**, from two droppable beats:
- Part 2: `p2-rule` can go; its point is on `habits`.
- Demo: narrate only the emulator slide in full; the other three can run under one sentence each.

Time the read-through before recording. Terminal beats always take longer than they look.

## Held back for the live Q&A

- Which Android scale an app reads: the React Native app here decides on the *transition* scale alone; native code asks the animator scale. Zero all three.
- Why iOS has no programmatic switch, and what driving Settings costs.
- Animations that run on the GPU without moving an element's frame — whether a tool can see them at all.
- The agent, live: ask it whether this app honors Reduce Motion, and to prove it with a control.

## Known risk

Two lines in the CFP to stay on the right side of:
- **"Product tours … if the logo is required for the talk to make sense, it is a pitch."** The techniques must stand without Mobium — every part states the platform fact first, then what Mobium does with it. Never open a part on the tool.
- **Accessibility, "avoid unless you have a specific trench case."** This is one — measured, with numbers — and the subject is test speed and durability; Reduce Motion is the mechanism.
