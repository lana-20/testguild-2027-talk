# Automation Guild '27 — form answers, as drafted

Form: <https://podio.com/webforms/23345311/1672624>
Status: **submitted 2026-10-05**, as below. Community voting opens **Oct 9**.

This is the text as submitted; keep it as the record of what the Guild has.

---

## Presentation Title

**Fast and Robust Mobile Tests with Mobium: Turn Off the Motion**

Alternates, if the title field feels long:
- Animations Are for Humans: Fast, Robust Mobile Tests with Mobium
- Two Seconds a Screen: Making Mobile Tests Fast and Robust with Mobium

---

## What are the 1-3 key takeaways from your session?

1. **Turn off the system's animations once per device, and put them back after.** On Android it is three settings; on iOS it is Reduce Motion, which only the Settings app can change — about 25 seconds, so it belongs in device setup, not in every test.
2. **The app's own animations are where the time goes, and the system switches only reach them if the app listens.** Have the app honor Reduce Motion instead of shipping a test-only build: the fast path your tests take is then a path real users take, in the build you ship.
3. **Prove the motion is gone by timing it, with a control that must not move — and for motion you cannot turn off, wait for stillness and refuse what never stops.** A setting that reads 0 is not an animation that stopped. Mobium, the open-source tool the session is built on, does the last two for every action, and turns the setting on with one call on both platforms — reading it back, and putting it back when the session ends.

---

## What relevant problem(s) do you aim to solve with your session for attendees?

Mobile tests that are slow and flaky because the app is busy being beautiful.

Every slide-in, fade and bounce is time a test spends waiting, or a race it loses: a tap aimed at a button still moving, a read of a screen halfway through a transition. On a real iPhone, one target that slides in costs **3.3 seconds** of a test's time; the same target with its animation off costs **1.3** — the tool's own round trip. Multiply that by every screen in every test.

The standard advice is to switch animations off. This session shows, measured on four devices — a real iPhone and Pixel, an iOS simulator and an Android emulator — what that advice does and does not do:

- **Android's three animation scales at 0** read back 0 — and an app animation running on its own clock still slid for **2.5 seconds**, exactly as with the scales at 1.
- **The same scales made an app that asks "should motion be reduced?" appear at once**: 2.6 seconds down to well under one.
- **iOS has no programmatic switch at all.** Reduce Motion lives in Settings, and changing it from a test means driving the Settings app.
- **With the motion off, the demo test's steps took 23–46% less time on every device** — a real iPhone and Pixel, the simulator and the emulator. That is from opening the screen to the last check, measured three rounds each through both of Mobium's agentic clients, the command line and MCP, with an animation that ignores the setting as the control. The control held on all four.

Then the fix that makes the switch reach the app, how to prove it worked, and what to do about the motion that stays — and how Mobium, an open-source tool for driving native apps from a terminal or an AI agent, builds all of it in: one call that sets Reduce Motion on either platform and puts it back, an action that waits for its target to stop moving, and a refusal, with an error code, for a target that never does.

---

## Why does this problem exist / needs to be solved?

Because animation is a design decision and test speed is somebody else's problem.

**Designers add motion for humans**, and it works: it is how a person follows what changed. A test is not a person. Every animation is either time spent waiting for the screen to settle or a race against it, and the two failure modes look different — one is a slow suite, the other a flaky one — so teams rarely trace both to the same cause.

**The usual fixes stop halfway.** The system switch is real but does not reach an app's own animations unless the app reads it. The other common fix, a test build with every duration forced to zero, means testing a build nobody ships, through a flag nothing tests.

**And nobody measures it.** "We turned animations off" is a setting somebody changed, not a result anybody saw.

---

## What do the attendees lose if they don't solve this problem?

Minutes per run, every run, for everyone — and a steady trickle of flakes with no obvious owner.

Two seconds per animated screen is invisible in one test and enormous in a suite: across hundreds of tests and many runs a day it is the difference between a feedback loop people wait for and one they stop waiting for. The flakes cost more than the minutes, because a race with an animation fails rarely and differently each time, and gets retried rather than fixed.

---

## How would their day-to-day/career become better & easier with your session?

They leave with a short, concrete list:

- **The exact switches**, per platform, and how to put them back so a shared device or someone's phone is left as it was found.
- **A one-line change for the app team**, per framework — UIKit, SwiftUI, Android views, React Native and the web — that makes the system switch reach the app's own animations, and that is an accessibility improvement in its own right.
- **A way to prove it**: let the app time itself, and keep one animation that ignores the setting as the control.
- **What to do with motion that stays** — spinners, confetti, live content: wait for stillness, and treat a target that never holds still as a failure, not something to chase.
- **A tool that does this for them**: Mobium is MIT licensed, a single binary, and drives real iPhones and Android devices from a terminal, from five client languages, or from an AI agent over MCP — the demo is one test file, run unchanged on all four devices; in the Q&A an agent drives the same tools live.

Every second shaved off a test comes off everyone's feedback loop.

---

## Do you work for a test tool vendor?

**Yes** — I founded Mobium AI, a testing consultancy in Seattle, and I build Mobium, an open-source (MIT) mobile automation tool. Nothing is for sale. The session is built on Mobium, but it is not a tour: the techniques are platform settings and app code that work with whatever drives your tests, and Mobium is shown doing them — with the numbers it measured on four devices, through its command-line and MCP clients.

---

## Anything else you want to tell me?

Every number in this session was measured for it, on a real iPhone 15 Plus, a real Pixel 8 Pro, an iOS simulator and an Android emulator, with the app keeping its own time rather than the test tool. Attendees get the slides, the test and the scripts behind every number — the same steps run through the command line and through MCP, with the raw results — and the small open-source app the measurements were taken on — two identical animations, one honoring the setting and one ignoring it as the control. Both are public and MIT licensed: the tool at github.com/mobiumdev/mobium, the app at github.com/mobiumdev/mobium-app.

---

## Remaining form fields

| Field | Value |
|---|---|
| Name | Lana Begunova |
| Email | begunova@gmail.com |
| Country | United States |
| Website | daisyladybug.com |
| LinkedIn | linkedin.com/in/lanabegunova *(confirm exact slug before submitting)* |
| X | *(confirm or leave blank)* |
| Not a recycled vendor webinar / Guild gets first outing | **agree** — see README, "Commitments" |
| External mic + reliable internet | **agree** |
