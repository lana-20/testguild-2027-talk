# Speaker transcript — Fast and Robust Mobile Tests with Mobium

The words to say, slide by slide, for the 25-minute recording. Each section starts with the
slide's number and id, as in `deck/slides/`, and the time it should start by — the run of show's
plan. `[click]` moves to the next slide. `[pause]` is a beat of silence. Bracketed lines are cues,
not words. Numbers match the slides and `EVIDENCE.md`; if a slide changes, change the line here
too.

`teleprompter.html` shows this script large and scrolling, and
`python3 scripts/build_teleprompter.py` rebuilds it from this file. The spoken words come to
about 2,650 — some 19 minutes at 140 words a minute. The videos and pauses bring it to about 22,
which leaves three minutes of slack in the 25.

---

## 1 · cover · 0:00

[No introduction yet. The logo loops on the right. Two seconds, then move on.]

[click]

## 2 · open-numbers · 0:05

Same screen. Same button. Same tap.

[pause]

On a real iPhone, the app recorded this tap three point three seconds after I asked for it.

[pause]

And this one — one point three.

Nothing about the test changed. Not a line of it. One setting changed on the phone, and one line
changed in the app.

[pause]

I'm Lana Begunova. I'm an SDET in Seattle, I test mobile apps for a living, and I build an
open-source mobile automation tool called Mobium. This talk is about those two numbers — where
the other two seconds went, and how to get them back on every screen of every test.

[click]

## 3 · premise · 1:30

Let's start with something we all agree on. Animations are for humans.

They're how a person follows what changed on a screen. A button slides in, and your eye goes to
it. A sheet rises from the bottom, and you know where it came from. That's good design, and I'm
not here to argue with designers.

But a test isn't a person. A test doesn't need to be guided. To a test, every animation is one of
two things.

It's time the test waits. Multiply that by every screen and every test, and you have a slow
suite.

Or it's a race the test can lose. A tap aimed at a button that's still moving. A read of a screen
halfway through a transition. That's a flaky suite.

Those two failures look completely different. One shows up on a dashboard as minutes. The other
shows up as a test that fails once in fifty runs and passes on retry. So teams rarely trace them
back to the same cause. Today we trace both of them to motion — and then we turn it off.

[click]

## 4 · part1 · 3:00

[Section divider — say nothing.]

[click]

## 5 · p1-cost · 3:05

Motion costs a test three things.

The first is time, and it's the one we can measure. A careful tool won't touch a target while
it's moving — it waits for it to settle. So a two-second slide-in isn't two seconds. On the
iPhone it cost about three point three seconds, waiting included, and two and a half on the
Android emulator. With the motion off, the same steps took one point three on the iPhone, and
about a quarter of a second on the emulator.

The second cost is races. A tap aimed at something still moving lands wherever the thing happens
to be. A read in the middle of a transition sees half of one screen and half of another. That
doesn't show up as time. It shows up as a flake. And then a retry hides it, and nobody fixes it.

The third cost is CPU. The device under test is rendering frames that nobody is watching — on an
emulator that's sharing a CI machine with everything else.

Two seconds is invisible in one test. Nobody files a bug about two seconds. But across a suite,
on every run, for everyone who's waiting on the build — it's the feedback loop.

[click]

## 6 · p1-two-kinds · 4:30

Before we turn anything off, one distinction that the rest of the talk hangs on. There are two
kinds of animation, and they have different switches.

The system's own. The transitions between screens and between apps — the slide when you push a
new screen, the zoom when an app opens. The operating system draws those, and a device setting
turns them off.

And the app's own. Anything the app animates itself: a card that slides in, a bounce, a
spinner, confetti when you finish a purchase. The app's code draws those, and only the app can
turn them off.

Hold on to that split. Part two is the left box — the system's switches. Part three is the right
box. And part three is where the time actually goes.

[click]

## 7 · part2 · 6:30

[Section divider — say nothing.]

[click]

## 8 · p2-android · 6:35

Android first, because Android makes this easy.

There are three animation scales. The window scale, for windows opening and closing. The
transition scale, for moving between activities. And the animator scale, for animations inside
apps. Set all three to zero with adb shell settings. It needs no root, and it works on an
emulator or a phone.

Then put them back after — and put them back as you found them. That sounds obvious, and it has
a trap in it. An untouched device doesn't report "one" for the animator scale. It reports "not set
at all." If your cleanup writes "one", the device now reads differently from how you found it.
So remember what was there, and if nothing was there, delete the key.

Why care? Because on a phone, these settings belong to somebody. A test that leaves a person's
phone changed has a bug in it, even if every assertion passed.

[click]

## 9 · p2-ios · 8:00

On iOS there's no command at all.

The switch is Reduce Motion, in Settings, under Accessibility, under Motion. Nothing outside the
phone can set it. A test that wants it has to drive the Settings app — open it, walk down the
pages, flip the switch, come back. On my iPhone that's about twenty-five seconds a change. I
timed it.

So the rule is: once per device, in setup. Never per test. Twenty-five seconds per test would eat
everything we're trying to save.

And know what you're getting. Reduce Motion reduces — it doesn't remove. Settings' own push
transition still slides with it on. Its real power isn't what it does to the system. It's what it
tells the app. Hold that thought for part three.

[click]

## 10 · p2-rule · 9:15

With Mobium, both platforms are one call: accessibility, reduce motion, on. Underneath, that's
the three scales on Android, and a trip through Settings on an iPhone. Mobium reads the setting
back to confirm it actually changed, and when the session ends, it puts back whatever it found.

But read it afterwards anyway. Once, on my own iPhone, a run did not put Reduce Motion back. Two
reruns afterwards did, and I still don't know why. It's an open lead in the tool's roadmap. I'm
telling you because it's this talk's own rule, applied to my own tool: a setting that says it was
restored is not the same as a setting you read.

A setting changed on somebody's phone and never changed back is a defect, whoever wrote the test.
So every recording in the demo reads the setting before the run and after it.

[click]

## 11 · part3 · 10:30

[Section divider — say nothing.]

[click]

## 12 · p3-scales · 10:35

So here's the experiment that changed how I think about this.

Android emulator. All three scales at zero, the standard advice, done by the book. Every one of
them read back zero.

On screen, the app has two animations, identical except for one line. Both slide in over two
seconds, and the app times each one itself.

The first one ignores the setting. With the scales at one, it took two and a half seconds. With
the scales at zero — two and a half seconds. It slid anyway, as if nothing had changed.

The second one asks the platform a single question: should motion be reduced? With the scales at
one, two point six seconds. At zero — under one second. It appeared at once.

[pause]

The zeroed scales are how Android answers "yes, reduce motion." The app that asked got the
answer. The app that didn't ask kept animating on its own clock.

So the system switch turns off the app's animations only when the app listens.

[click]

## 13 · p3-two-fixes · 12:00

There are two ways to stop the app's own motion.

The first is a test build. You force every animation duration to zero behind a flag that's only
on in testing. It works — the animations are gone. But look at what you're testing now: a build
nobody ships, through a flag nothing tests. Your fastest path runs through code your users never
execute.

The second is to make the app honor Reduce Motion. When the user asks for less motion, the app
skips its animations. Then the switch from part two reaches it — in the build you ship, on a
path that real users take every day.

Use the second one. The fast path becomes a real path. And it's an accessibility fix your app owes
its users anyway — people with vestibular disorders turn that switch on for a reason.

[click]

## 14 · p3-code · 13:15

And it really is one line per framework.

UIKit asks UIAccessibility whether Reduce Motion is enabled. SwiftUI reads it from the
environment. Android views ask the value animator whether animators are enabled. React Native has
AccessibilityInfo. And on the web, or inside a WebView, it's a media query: prefers reduced
motion.

Then animate with a duration of zero, or skip straight to the final state. And listen for changes
— the setting can flip while the app is running.

One detail I measured: React Native on Android decides from the transition scale alone. Zero just
the animator scale, and it still says motion is on. Zero all three, and every reader agrees.

[click]

## 15 · p3-rule · 14:15

So the rule is: make the fast path a real path.

Turn motion off through the switch your users already have, and make the app listen to it. The
speed-up and the accessibility fix are the same line of code. And your test now exercises
something users actually get, instead of something only your CI ever sees.

A test-only shortcut is a second app. And nobody tests that one.

[click]

## 16 · part4 · 15:00

[Section divider — say nothing.]

[click]

## 17 · p4-control · 15:05

Now, how do you prove the motion is gone? Because "we turned animations off" is a setting
somebody changed. It isn't a result anybody saw.

Two habits. First, let the app keep the time. The app records how long after its own Replay the
tap arrived. So the tool isn't grading itself — the tool's opinion of how fast it was isn't the
evidence.

Second, keep a control: one animation that ignores the setting, on purpose. If the control's time
moves when the setting does, you're measuring something else — the device warming up, the
machine being busy, the network. The control is how you know.

On the iPhone, I ran the same test through both of Mobium's agentic clients — the command line,
and MCP, which is how an AI agent drives it. Three rounds each. The honoring target dropped from
about three seconds to one point three. The control stayed inside its own spread, two point nine
to three point four, both ways.

So the time the honoring target lost belongs to the setting.

[click]

## 18 · p4-devices · 16:05

Then the same measurement everywhere. Four devices: a real iPhone, a real Pixel, the iOS
simulator and the Android emulator. Two clients each, three rounds each.

The column on the right is the one to read. The case is the demo test from opening the screen to
its last check: replay and tap both targets, celebrate, wait for the confetti. With animations
off, every device, through both clients, lost between a quarter and nearly half of that time.
Twenty-three percent on the iPhone. Thirty-five on the Pixel. Up to forty-six on the emulator.

Two honest notes. On Android, the honoring time with the motion off lands at one of two levels —
about a quarter of a second or about a second — in both clients. That's how long the tool takes
to confirm the target is still. So a median of three can fall on either. It isn't the client.

And the control held on every device.

[click]

## 19 · p4-stays · 16:50

Some motion never stops. Spinners. Live content. Confetti.

You can't turn those off, so the tool has to deal with them honestly. Mobium waits for every
target to stop moving before it acts. And a target that never holds still is a failure, with a
code — not something to chase.

Here it's a single falling piece of confetti. Mobium watched it for five seconds, reported where
it was and where it went, and refused to tap it. Exit code six: timeout.

Chasing a moving target is how a race becomes a flake. Sometimes the tap lands, sometimes it
doesn't, and the retry hides it. A refusal fails the same way, every single time. You can fix
something that fails the same way every time.

[click]

## 20 · demo · 17:30

Now the demo. It's recorded, on four devices, in the order the theory went — Android first.

[click]

## 21 · demo-code · 17:40

This is the code that ran. One Mobium test file — and it ran unchanged on all four devices. Only
the device name changed.

Two cases from one list: animations on, and animations off. Each case flips the platform's own
switch, opens the Motion screen, checks that the app actually sees the setting, taps both targets
after their Replay, presses Celebrate, and waits for the confetti to say "done" — or "still."

Notice the first step. The setting is part of the test. It isn't a manual prerequisite
someone forgets.

[click]

## 22 · demo-clients · 18:30

And because every step in that file is a tool call, Mobium's two agentic clients can run the same
steps.

Here are the first three steps, in three forms. On top, the test file itself — one JSON document,
which the test runner built into Mobium reads and runs. In the middle, the command line: one
command per step — what you'd type, or what a shell script runs. At the bottom, MCP, the Model
Context Protocol: JSON-RPC requests to Mobium's MCP server, one message per line — exactly what an
AI agent sends.

The same tools underneath all three. The command-line version is checked against the test file
before it runs. The MCP version reads its steps straight from the file. So they can't drift apart.
And those two clients are where every number on the four-device slide came from.

[click]

## 23 · demo-run · 19:15

The config names the four devices as projects. One command per device. Eight passes — two cases
on each of four devices.

The phones take longer than the virtual devices, and the iPhone takes longest. Switching Reduce
Motion there is a trip through Settings, twice per run.

[click]

## 24 · demo-emulator · 19:45

The Android emulator. Animations on, on the left. Animations off, on the right.

[Let both clips play. Point as they run.]

Watch the honoring target — the top green button. On the left it slides in. On the right it's
already in place before the tap.

Now the control, below it. On both sides it slides for two and a half seconds. The scales don't
reach an animation on the app's own clock.

And Celebrate. On the left the confetti falls. On the right it never starts.

[click]

## 25 · demo-pixel · 21:00

My own Pixel. Same picture, on real hardware.

[Let it play.]

Three point one seconds down to one point two. The confetti falls on the left and holds still on
the right.

[click]

## 26 · demo-simulator · 21:40

The iPhone simulator. Reduce Motion is the only switch iOS has.

[Let it play.]

The app asks for it and skips its slide. The control doesn't. Two seconds down to under one.

[click]

## 27 · demo-iphone · 22:20

And my own iPhone, recorded over USB.

[Let it play.]

Three point two seconds down to one point three. The trip through Settings happened between the
two clips — I cut it out, because the first screen of Settings shows my name.

[click]

## 28 · demo-results · 23:00

So, what you just watched.

On every device, with the switch off, the app that listens is in place before the tap.

The control never moved.

The confetti fell with animations on, and stayed still with them off.

And one test file did all of it. Only the device changed.

[click]

## 29 · habits · 23:30

Four habits to take home.

One: turn off the system's animations once per device — and put them back as you found them.

Two: make the app honor Reduce Motion. The fast path becomes a real path, in the build you ship.

Three: time it with the app, and keep a control. A setting that reads zero is not an animation
that stopped.

Four: wait for stillness — and refuse what never stops.

[click]

## 30 · close · 24:15

Turn off every animation you can — the system's with a setting, the app's by having it listen —
and wait out the rest.

You get time back. And a whole class of races leaves your suite.

How much depends on your app, and how much it moves.

[pause]

But every second you take off a test comes off the feedback loop of everyone who waits on your
build.

[pause]

The tool and the demo app are open source, at github dot com slash mobiumdev. The slides and the
scripts you watched are linked at the bottom. Thank you.

[End of recording. Q&A follows live.]
