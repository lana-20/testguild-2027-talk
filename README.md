# Automation Guild '27 — *It Passed, and It Passed Too Easily*

Everything for the TestGuild [Automation Guild '27](https://testguild.com/call-for-speakers/)
speaker submission: the pitch, the 25-minute run of show, the 26-slide deck, and the
provenance of every number in it.

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

Five months building a native mobile automation tool, with every defect written down as it
happened. **Of 70 substantive defects, 54 were found only by running against a real device** —
not by the compiler, not by review, and not by the test suite, because several defects survived
tests written from the same wrong assumption as the code. The session walks that record as
specific failures: a probe that reported four clean zeroes without ever leaving the launcher, a
truncation test that could not fail, four defects that were in the *witness* rather than the
feature, and a tool that printed passwords in plaintext. It lands on four habits, and on the
question that matters once an agent is writing your tests: not whether they pass, but whether
they *could fail*.

**The tool is the setting. The verification failures are the content.** That distinction is the
whole reason this pitch is shaped the way it is — see
[`research/CFP-REQUIREMENTS.md`](research/CFP-REQUIREMENTS.md), "Why our angle is what it is".

---

## What is here

```
README.md                      you are here
EVIDENCE.md                    every slide number, and the file it came from
submission/
  FORM-ANSWERS.md              the six content fields + vendor answer, paste-ready
  RUN-OF-SHOW.md               25-minute timing plan, slide by slide, with the slack
research/
  CFP-REQUIREMENTS.md          what the Guild wants and forbids, and the two binding clauses
deck/
  deck.json                    the index: title, slide order, sections, typefaces
  slides/<id>.html             26 slides, one file each — the source of truth
  deck.html                    BUILT — standalone, self-contained, what Pages serves
scripts/
  build_deck.py                slides/ + deck.json -> deck.html. Never edits a slide.
```

### Rebuilding the deck

```sh
python3 scripts/build_deck.py     # -> deck/deck.html
```

The slide files are the source of truth and are byte-identical to the ones in the
Claude artifact the deck was designed in. The build script only wraps them in a viewer:
keyboard navigation, a notes panel, a progress bar, and a print stylesheet that lays each
slide out as a 1920×1080 page for PDF export. Edit a slide, re-run, commit both.

---

## Commitments the submission makes

Both are ticked on the form. Both need honoring.

1. **Automation Guild gets the content's first conference outing.** No Mobium talk anywhere
   before Feb 2027. The PNSQC 2026 poster (Oct 12–14) is about Vibium CLI startup overhead and
   does **not** conflict — keep it that way, and do not add a Mobium angle to it.
2. **Unique content, recorded on TestGuild's deck.** Selected speakers are sent the template.
   **This deck is therefore the content and design master, not the final file** — the structure,
   the numbers and the speaker notes port across; the palette probably will not.

---

## Open items

- [ ] **Submit.** Nothing is sent. Deadline Oct 8.
- [ ] **Mobium is private.** The submission promises attendees "the repo, the slides, and the
      exact commands." That repo has to be public by February, and a citable repo is worth more
      on a ballot that opens Oct 9.
- [ ] **`deck/slides/close.html` contains a `[repo link]` placeholder.** Replace before recording.
- [ ] Confirm the LinkedIn slug, X handle and website fields in `FORM-ANSWERS.md`.
- [ ] Time a read-through before recording. The run of show is deliberately long; the slack and
      the two droppable beats are named in `RUN-OF-SHOW.md`.

---

## Design notes for the deck

Committed to for this subject, in case a slide gets added later and should match:

- **Palette.** Slate ink `#141A21` for evidence slides, bone `#F0EDE6` for the rules that follow
  them, amber `#E0A526` for warnings, terracotta `#C4452F` for the single statement slide.
  Muted green `#4C8C6A` is used **only** for the word PASS and for results that turned out to be
  false — the green is the villain. The one honest green in the deck is F-Droid's zero.
- **Type.** Rubik for voice, Fira Code for every artifact — terminal output, counts, exit codes.
  The mono is evidence, not decoration.
- **Rhythm.** Dark slides carry the scars, light slides carry the rule you just earned. By the
  third dark slide the audience knows a confession is coming without being told.
- **Slide format.** 1920×1080, all styles inline, 128px margins (160px bottom where a slide has a
  pinned footer row). Nothing below 24px.

---

## Related

- **PNSQC 2026 poster** — [lana-20/pnsqc-2026-poster](https://github.com/lana-20/pnsqc-2026-poster),
  a different talk about a different tool. Submitted, ID 139.
- Benchmarks and methodology: [github.com/lana-20](https://github.com/lana-20)
