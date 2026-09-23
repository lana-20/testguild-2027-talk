# Where every number in this talk comes from

The talk argues that unsourced figures drift, so the figures in it carry their sources.
Everything below is traceable to the Mobium repo's own written record (`~/mobium`, private
at the time of writing), kept while building rather than reconstructed afterward.

**Re-check before quoting anywhere.** These counts have gone stale twice; a note is not a source.

| Claim on a slide | Where it comes from | Last verified |
|---|---|---|
| 70 substantive defects | `docs/STATE.md` — "Of 70 substantive defects…" | 2026-09-22 |
| 54 found only on a real device | same line; restated at `docs/STATE.md` "where 54 of 70 defects came from" | 2026-09-22 |
| Test passed in 0.31s, simulator already booted | Mobium defect log; the create/boot/delete steps short-circuited | 2026-09-14 |
| Probe: 0 hidden nodes, **32 nodes every time** | the hidden-node probe; four launches, identical counts, never left the launcher | 2026-09-14 |
| `TestTruncationCountsCharactersNotBytes` — 24-byte repeats | the test's own sample, `strings.Repeat("日本語のテキスト", 40)`; 120-byte cut lands on a char boundary | 2026-09-14 |
| Defects 67–70 all in the witness | `docs/CHALLENGES.md` §§67–70; `docs/STATE.md` gesture row | 2026-09-22 |
| `app_check` — neither platform found anything | `docs/STATE.md`, "the exception that is worth noticing" | 2026-09-22 |
| Wikipedia: 3 defects, 876-character label, 91% of map text | rollout gate G4 notes | 2026-09-13 |
| F-Droid: 0 defects | third-party app pass | 2026-09-14 |
| Aegis: `map` printed passwords in plaintext | third-party app pass; fix routes all node text through `uitree.Redact` | 2026-09-14 |
| Regression fixture `PASSWORD-MUST-NOT-APPEAR` | `internal/uitree/testdata/aegis-password-uia2.xml` | 2026-09-14 |
| `mobium back >/dev/null 2>&1` hid a missing command | Mobium defect log; there is no `back` command | 2026-09-14 |
| "unknown ref … run app_map again" — impossible advice | WebView locator refusal | 2026-09-14 |
| clean-stop script zeroed on unset `$ANDROID_HOME` | `docs/checks/clean-stop.sh` history | 2026-09-12 |

## The exit-code table (slide `a2-table`)

Every row was observed directly while building, not read from documentation.

| command | failure text | exit |
|---|---|---|
| `adb` (device offline / unauthorized) | stderr | 0 |
| `am start` | stdout | 0 |
| `uiautomator dump` | "killed" stdout, `ERROR: could not get idle state.` stderr | 0 |
| `pm grant` (permission never declared) | nothing on any stream | 0 |
| `adb uninstall` | `Failure [DELETE_FAILED_INTERNAL_ERROR]` on stdout | 1 |
| `simctl privacy` | `An error was encountered processing the command` on stderr | 0 |

`adb uninstall` also reports `Success` when all it removed was the *updates* to a system app.

## Held back for Q&A, with sources

| Claim | Source |
|---|---|
| Scroll-axis overflow signal does not exist — zero in both axes, every time | measured across every scrollable on the launcher and two Settings screens |
| `webinspectord` takes 10.2s to send its first byte on any connection after the first | message-arrival trace, after three wrong timing diagnoses |
| Three "limitations" were false, incl. geolocation readback via a test provider | `cmd location providers set-test-provider-location` + `dumpsys location` |

## Numbers deliberately NOT on a slide

- Current tool/client/surface counts. They were wrong within a day, twice. The talk needs none of them.
- Any comparison against Appium or another tool. This is not a competitive talk, and the CFP penalizes those.
