# Automation Guild '27 — form answers, as drafted

Form: <https://podio.com/webforms/23345311/1672624>
Status: **not yet submitted.** Deadline **Oct 8, 2026**; community voting opens **Oct 9**.

Paste each block into the matching field. Nothing here is submitted until the form is sent.

---

## Presentation Title

**It Passed, and It Passed Too Easily: 70 Defects and the Tests That Agreed With Them**

Alternates, if the title field feels long:
- The Green Suite That Couldn't Fail: 70 Defects From Building a Tool for AI Agents
- Positive Controls: How to Tell a Passing Test From a Test That Can't Fail

---

## What are the 1-3 key takeaways from your session?

1. **Any result of "zero" or "no difference" needs a positive control before you believe it.** Make the measurement report the thing you expect it to find, *then* trust the zero. A probe that never ran and a check that silently passes are the same defect wearing different clothes.
2. **Exit code 0 is not evidence — read the state back.** Across every tool in this project, failures arrive on stderr with a zero exit, on stdout with a zero exit, or with no output at all. There is no convention, so assert on the resulting state, not on the command's own opinion of itself.
3. **Mutate the code and watch the test fail before you trust it.** A test written from the same assumption as the code it checks will pass forever. This is now the core skill for reviewing AI-generated tests, because the model writes both sides.

---

## What relevant problem(s) do you aim to solve with your session for attendees?

Tests that cannot fail, and the false confidence they buy.

I spent five months building a mobile automation tool and kept a record of every defect. **Of 70 substantive defects, 54 were found only by running against a real device.** Not by reading code. Not by the compiler. Not by the test suite — several defects *survived tests written from the same wrong assumption as the code*.

The session is that record, walked through as specific failures with the artifacts on screen:

- A probe asked whether Android ever marks a UI node hidden. It launched four apps, found zero every time, and reported **32 nodes every time** — it had never left the launcher. Four clean zeroes were four readings of the same screen, and only the identical count gave it away.
- A truncation test proved labels are cut on characters, not bytes. Its sample was a 24-byte string repeated, so every byte-cut landed on a character boundary anyway. The test passed on the broken implementation.
- An iOS test went green in 0.31 seconds because the simulator it asked for was already booted, so create, boot and delete never ran.
- The last four defects I logged were all in the **witness** rather than in the feature — the code was right and the thing observing it was lying.
- And the one that still stings: my tool printed passwords in plaintext, because both platforms mark a password field and I parsed the flag without ever reading it. Three real third-party apps found it. The fixtures could not.

---

## Why does this problem exist / needs to be solved?

Three reasons, and AI has made all three worse.

**The author of the test is the author of the assumption.** A hand-written fixture encodes what you already believe. Mine weren't careless — the first was modeled on a real login screen with deliberate edge cases — and they still certified the wrong behavior, because a fixture can prove logic self-consistent while saying nothing about platform semantics.

**Tooling defaults to reporting success.** `pm grant` exits 0 and grants nothing for a permission an app never declared. `simctl privacy` accepts a bundle ID for an app that isn't installed and does nothing, successfully. `adb uninstall` reports `Success` when all it removed was updates to a system app. If your verification stops at the exit code, this entire class of defect is invisible by construction.

**Now the model writes both sides.** When an agent generates the implementation *and* the test, "all green" is the implementation asserting itself. Everything the Guild is asking about evals and LLM-as-judge runs into this: a judge you can't falsify isn't a judge. I'll show what we actually check instead, and what it costs.

---

## What do the attendees lose if they don't solve this problem?

They ship on evidence that was never evidence — and they find out on a real user's device, which is the most expensive place to learn it.

Concretely: the bug reaches production with a green pipeline behind it, so nobody looks at the tests, because the tests passed. Time goes into the wrong diagnosis — three of my "flaky" cases already had a plausible story attached, and every story was wrong. And the failure mode is **silence**: the code, the fixture and the test all agree, everything passes, and the tool is wrong on the first real screen it sees.

The multiplier is agent throughput. If you can't tell a passing test from a test that cannot fail, and your team has just increased test volume tenfold with AI, you haven't scaled your coverage. You've scaled your false confidence.

---

## How would their day-to-day/career become better & easier with your session?

They leave with four habits they can apply on Monday, each one cheap and each one earned the hard way:

- **Give every negative result a positive control.** Before believing "no difference," make the measurement show you a difference it should catch.
- **Read the state back after every action** — and capture both streams, because there is no convention about which one carries the error.
- **Mutate, then watch it fail.** A test you haven't seen fail is a test you haven't tested.
- **Capture fixtures from real devices rather than writing them**, and when you correct a heuristic, keep a real capture that fails under the old rule.

For anyone reviewing AI-generated tests, these are the questions that separate a real check from a rubber stamp — which is quietly becoming the SDET's main job. And for anyone whose roadmap says "add more tests," this reframes the work: the next useful thing is usually proving the existing suite can fail, not adding to it.

---

## Do you work for a test tool vendor?

**Yes** — I founded Mobium AI, a testing consultancy in Seattle, and I build an open-source (MIT) mobile automation tool. Nothing is for sale, there's no product tour in this session, and the talk stands entirely on the defect record. The tool is the setting; the failures are the content.

---

## Anything else you want to tell me?

Every number in this session comes from a written record kept while building, not reconstructed afterward — the defect log, the captured device hierarchies, the commands. Attendees get the repo, the slides, and the exact commands they watched, including the regression fixture whose password value is literally `PASSWORD-MUST-NOT-APPEAR`, so a leak names itself in the failure output.

Fits the *Automation Enlightenment* theme from the unflattering direction: this is five months of being wrong in public, with the receipts.

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
