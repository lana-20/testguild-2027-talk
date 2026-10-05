# Automation Guild '27 — *Fast and Robust Mobile Tests with Mobium*

Everything for the TestGuild [Automation Guild '27](https://testguild.com/call-for-speakers/)
speaker submission: the pitch, the 25-minute run of show, the 29-slide deck, the demo scripts,
and the provenance of every number in them.

**▶ View the deck: [lana-20.github.io/testguild-2027-talk](https://lana-20.github.io/testguild-2027-talk/)**
· arrow keys to move · **S** for speaker notes · **F** for full screen · `#12` in the URL jumps to a slide

---

## Status — read this first

| | |
|---|---|
| **Submitted?** | **No.** Nothing has been sent yet. |
| **Deadline** | **Oct 8, 2026** — submissions close |
| **Voting** | opens **Oct 9, 2026**; the community votes sessions in |
| **Event** | Feb 8–12, 2027, online |
| **Form** | <https://podio.com/webforms/23345311/1672624> |
| **Paste from** | [`submission/FORM-ANSWERS.md`](submission/FORM-ANSWERS.md) — every field, ready to paste |

### To submit

1. Open [`submission/FORM-ANSWERS.md`](submission/FORM-ANSWERS.md) and paste each block into the matching field.
2. Fill the three fields marked *confirm* in that file's last table (LinkedIn slug, X, website).
3. Answer the vendor question **yes**, with the qualifier already drafted there.
4. Tick both agreements — see **Commitments** below before you do.
5. Record the submission ID here in this README once it comes back.

---

## The talk in one paragraph

Animations are for humans. To a test, every slide-in and fade is either time spent waiting for
the screen to settle or a race against it — a slow suite or a flaky one. The session makes mobile
tests **fast and robust** by turning the motion off, measured on four devices — a real iPhone and
Pixel, an iOS simulator and an Android emulator: the system's animations first (Android's three scales; iOS's Reduce Motion, which only
Settings can change), then the app's own — which the system switch reaches **only if the app
listens**. With all three Android scales at 0, an app animation on its own clock still slid for
2.5 seconds; the one that asked whether motion was reduced appeared at once. The fix is to have
the app honor Reduce Motion, so the fast path is a real one in the build you ship; the proof is a
control that must not move; and the motion that stays is waited out, or refused when it never
stops. **[Mobium](https://github.com/mobiumdev/mobium)**, the open-source tool it is built on, does each step — and the demo is one Mobium
test file, run unchanged on all four devices and recorded; an AI agent drives the same tools in the
live Q&A.

The techniques stand without the tool; the tool is shown doing them. That balance is what the
CFP asks for — see [`research/CFP-REQUIREMENTS.md`](research/CFP-REQUIREMENTS.md), "Why our angle is what it is".

---

## What is here

```
README.md                      you are here
EVIDENCE.md                    every slide number, and the measurement it came from
submission/
  FORM-ANSWERS.md              the six content fields + vendor answer, paste-ready
  RUN-OF-SHOW.md               25-minute timing plan, slide by slide, with the slack
research/
  CFP-REQUIREMENTS.md          what the Guild wants and forbids, and the two binding clauses
demo/                          the scripts the demo runs, and how to set it up — see demo/README.md
index.html                     BUILT — the standalone deck, and what Pages serves
deck/
  deck.json                    the index: title, slide order, sections, typefaces
  slides/<id>.html             29 slides, one file each — the source of truth
  media/                       the demo's video clips and their stills; assets.json maps each
                               artifact upload (/_blob/<id>) to its file here
scripts/
  build_deck.py                slides/ + deck.json -> index.html. Never edits a slide.
```

### Rebuilding the deck

```sh
python3 scripts/build_deck.py     # -> index.html
```

The slide files are the source of truth and are byte-identical to the ones in the
Claude artifact the deck was designed in. The build script only wraps them in a viewer:
keyboard navigation, a notes panel, a progress bar, and a print stylesheet that lays each
slide out as a 1920×1080 page for PDF export. Edit a slide, re-run, commit both.
A slide names a video or picture the artifact's way (`/_blob/<id>`); the build swaps in the
copy under `deck/media/` and plays a clip as a looping, muted video, and fails on an id that
`deck/media/assets.json` does not map.

---

## Commitments the submission makes

Both are ticked on the form. Both need honoring.

1. **Automation Guild gets the content's first conference outing.** No Mobium talk anywhere
   before Feb 2027. The PNSQC 2026 poster (Oct 12–14) is about a different tool's CLI startup
   overhead and does **not** conflict — keep it that way, and do not add a Mobium angle to it.
2. **Unique content, recorded on TestGuild's deck.** Selected speakers are sent the template.
   **This deck is therefore the content and design master, not the final file** — the structure,
   the numbers and the speaker notes port across; the palette probably will not.

---

## Open items

- [ ] **Submit.** Nothing is sent. Deadline Oct 8.
- [x] ~~Mobium and MobiumApp public~~ **done** — [mobiumdev/mobium](https://github.com/mobiumdev/mobium)
      and [mobiumdev/mobium-app](https://github.com/mobiumdev/mobium-app), both MIT, are on the closing slide.
- [ ] Confirm the LinkedIn slug, X handle and website fields in `FORM-ANSWERS.md`.
- [ ] Time a read-through before recording, and a rehearsal of the demo with `NOPAUSE=1`. The
      slack and the droppable beats are named in `RUN-OF-SHOW.md`.

---

## Design notes for the deck

Committed to for this subject, in case a slide gets added later and should match:

- **Palette.** Slate ink `#141A21` for evidence slides, bone `#F0EDE6` for the rules that follow
  them, amber `#E0A526` for time spent waiting, terracotta `#C4452F` for races and refusals.
  Muted green `#4C8C6A` is used **only** for a time that came down because the motion was off.
- **Type.** Rubik for voice, Fira Code for every artifact — terminal output, settings, timings,
  exit codes. The mono is evidence, not decoration.
- **Rhythm.** Theory first, practice last. Each part states the platform fact first and what
  Mobium does with it second — never the other way round.
- **Slide format.** 1920×1080, all styles inline, 128px margins (160px bottom where a slide has a
  pinned footer row). Nothing below 24px.

---

## Related

- **PNSQC 2026 poster** — [lana-20/pnsqc-2026-poster](https://github.com/lana-20/pnsqc-2026-poster),
  a different talk about a different tool. Submitted, ID 139.
- Benchmarks and methodology: [github.com/lana-20](https://github.com/lana-20)
