# Run of show — 25 minutes

Pre-recorded on TestGuild's own deck template, then ~20 minutes of live Q&A.
Cut for a recording, not a live room. Slide ids in brackets match `deck/slides/<id>.html`.

| Time | Beat | Slides |
|---|---|---|
| 0:00–1:45 | Cold open — the 0.31s green test, then what actually ran | `cover` `open-green` `open-reveal` |
| 1:45–4:00 | Why you care even though this is mobile | `premise` `bridge` |
| 4:00–9:30 | **Act I** — the probe that never ran | `act1` `a1-question` `a1-result` `a1-tell` `a1-rule` `a1-echo` |
| 9:30–15:00 | **Act II** — exit 0 is not evidence | `act2` `a2-table` `a2-silent` `a2-devnull` `a2-agent` |
| 15:00–20:00 | **Act III** — the test that could not fail | `act3` `a3-test` `a3-reveal` `a3-witness` `a3-counter` |
| 20:00–23:30 | **Act IV** — fixtures, and the password | `act4` `a4-arc` `a4-password` |
| 23:30–25:00 | Four habits, and the handoff | `habits` `close` |

## 0:00–1:45 — Cold open, no introduction

Open on the terminal. A suite goes green in 0.31 seconds. Let it sit.

> "That's an iOS test. It creates a simulator, boots it, runs against it, and deletes it. It passed in three hundred and ten milliseconds. Create, boot and delete never ran — the simulator it asked for was already booted, so every step short-circuited and the assertions ran against a device I didn't set up. It passed, and it passed too easily. This talk is about the second half of that sentence."

Name yourself in one line, then the premise.

## 1:45–4:00 — The bridge

Half the room switches off at the word "mobile". This is where you keep them.

> "You're not here for mobile. You're here because your model now writes the test and the implementation, and you have to decide whether green means anything."

## 4:00–9:30 — Act I

Question (reasonable) → four zeroes (believable) → **32 nodes, four times** (the tell). The probe never left the launcher. Then Rule 01, then point it at the audience's own pipeline: the flake detector that finds no flakes, the a11y scan with zero violations, the LLM judge that approves everything.

## 9:30–15:00 — Act II

Read **three** rows of the table aloud, not all six. The `pm grant` row — nothing on any stream, exit 0 — is the one they remember. Then the silent trio, then `mobium back >/dev/null 2>&1`, where the redirect hid a **missing feature**, not a failing call. Close on error messages as instructions an agent obeys unconditionally.

## 15:00–20:00 — Act III

Show the passing test and ask the room what's wrong with it. Give them three seconds; almost nobody sees it. Then 24 bytes per repeat, a 120-byte cut, zero ways to fail. Then the four witnesses (defects 67–70) — the gesture code was right all four times. Then `app_check`, the counter-example, which is what makes the rest credible.

## 20:00–23:30 — Act IV

Wikipedia (3 defects, first screen, one 876-character label) → F-Droid (0, and that is the point) → Aegis (the password). Do not soften the password slide.

## 23:30–25:00 — Close

The four habits on one card, then:

> "Five months, seventy defects, and the only thing that reliably told me the truth was running it. Your agent will write you a thousand tests this quarter. The question isn't whether they pass. It's whether they could fail."

---

## Fit and slack

Runs long by design. Two droppable examples give roughly **2 minutes of slack**:
- Act I: the clean-stop script (`a1-echo` — the whole slide can go)
- Act III: the U+FFFD detail in `a3-reveal`'s notes

Time the read-through before recording. Terminal beats always take longer than they look.

## Held back for the live Q&A

Each opens a thread rather than closing one:
- the scroll-axis signal that does not exist — measured zero overflow in both axes, every time
- `webinspectord` taking 10.2 seconds to send its first byte, after three plausible and wrong timing diagnoses
- the three "limitations" that turned out to be false, including geolocation readback via a test provider
- why the tool is one static binary with no Node

## Known risk

Acts I–III are platform-agnostic; Act IV is unmistakably mobile. If the recording feels lopsided, trim Act IV to Aegis alone and drop Wikipedia — the password lands without the setup, and the Guild's "mobile, only as a real case" is satisfied either way.
