#!/usr/bin/env python3
"""Keep only the stretches of a recording where the Motion Demo is on screen.

    demo/keep-app.py raw.mp4 out.mp4

A `mobium test` run of tests/motion.test.json starts each case from a fresh
launch — the home screen, briefly — and on a real iPhone switches Reduce
Motion through the Settings app, whose first screen shows the owner's name.
None of that may be in a video. Every run ends on the Motion Demo, so the
recording's own last frame is the reference: each frame is shrunk to 36×80
gray pixels and kept when it is close to it. A home screen, Settings, a
launch animation — and MobiumApp's own home list — are far from it; the Motion
Demo with targets sliding or confetti falling is close. The two longest
stretches are the two cases; a shorter one is what the device showed before
the test restarted the app — or, on iOS, the snapshot of the app's last
screen that the system shows while relaunching it.

Writes out.mp4 (the kept stretches, joined) and, when there are two — one per
case — out-on.mp4 and out-off.mp4. Prints each frame's distance in a summary
and the stretches kept, so a threshold that is wrong for a device shows. Look
at the result before it goes anywhere: this decides what is on screen.
Needs ffmpeg and ffprobe.
"""
import subprocess, sys

W, H, FPS = 36, 80, 30   # every output frame is judged: the cut is exact
THRESHOLD = 40      # mean absolute difference, 0-255. Measured on the emulator: the
                    # Motion Demo 0-27 (a target sliding in up to 12, a Replay's jump
                    # back 18-27); MobiumApp's own home list 77; the launch splash
                    # 50-144; the frame between two screens 34-37. On the iPhone 15
                    # Plus everything rejected — home screen, Settings, launches —
                    # measured 46 or more, and every kept frame 38 or less: a narrow
                    # margin, so the written file is checked against it too. Nothing glues two
                    # stretches across a frame above it, however short: a Settings
                    # frame is exactly that short dip, and it must never be kept.
MIN_RUN = 1.0       # seconds: shorter stretches are transitions, not the app
REDRAW = 25         # frame-to-frame jump in the last case's final second: the end of
                    # the session putting the setting back, the app redrawing itself
                    # — 33 to 37 measured; nothing the test does at its end exceeds 2


def frames(path):
    out = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-vf", f"fps={FPS},scale={W}:{H},format=gray",
         "-f", "rawvideo", "-"], capture_output=True, check=True).stdout
    n = W * H
    return [out[i:i + n] for i in range(0, len(out) - n + 1, n)]


def distance(a, b):
    return sum(abs(x - y) for x, y in zip(a, b)) / len(a)


def main():
    src, out = sys.argv[1], sys.argv[2]
    fs = frames(src)
    if len(fs) < FPS * 3:
        sys.exit(f"{src}: only {len(fs)} frames — nothing was recorded")
    ref = fs[-1]
    ds = [distance(f, ref) for f in fs]
    keep = [d < THRESHOLD for d in ds]

    spans, start = [], None
    for i, k in enumerate(keep + [False]):
        if k and start is None:
            start = i
        elif not k and start is not None:
            spans.append([start / FPS, i / FPS])
            start = None
    runs = [(a, b) for a, b in spans if b - a >= MIN_RUN]
    print(f"{len(fs)} frames; distance min {min(ds):.1f}, max {max(ds):.1f}; "
          f"{sum(keep)} under {THRESHOLD}")
    for a, b in runs:
        print(f"  keep {a:6.1f}s – {b:6.1f}s  ({b - a:.1f}s)")
    if not runs:
        sys.exit("no stretch of the app found — is the recording of the Motion Demo?")
    if len(runs) > 2:
        # A recording starts on whatever the device last showed — often the
        # Motion Demo of the run before, until the test restarts the app. The
        # two cases are the two longest stretches; keep them, in order.
        longest = sorted(runs, key=lambda r: r[1] - r[0], reverse=True)[:2]
        for r in runs:
            if r not in longest:
                print(f"  drop {r[0]:6.1f}s – {r[1]:6.1f}s  (not one of the two cases)")
        runs = [r for r in runs if r in longest]

    # The run's session puts the setting back the moment the last case
    # passes, and an app that listens redraws itself — reduceMotion flips,
    # both targets reset and slide in again — before the recorder has
    # stopped. That is not the case being shown: end the last stretch
    # before it.
    a, b = runs[-1]
    first, last = round(a * FPS), round(b * FPS)
    for i in range(max(first + 1, last - FPS), last):
        if distance(fs[i], fs[i - 1]) > REDRAW:
            print(f"  trim {i / FPS:6.1f}s – {b:6.1f}s  (the setting put back, on camera)")
            runs[-1] = (a, i / FPS)
            break

    def cut(parts, dst):
        # Frame numbers after the same fps filter the frames were judged
        # through, so the output holds exactly the frames that were kept.
        sel = "+".join(f"between(n,{round(a * FPS)},{round(b * FPS) - 1})" for a, b in parts)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-an",
                        "-vf", f"fps={FPS},select='{sel}',setpts=N/{FPS}/TB",
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18",
                        "-movflags", "+faststart", dst], check=True)
        # And checked: every frame of what was written is the app, or the
        # file goes — a frame of somebody's Settings must never be kept.
        worst = max(distance(f, ref) for f in frames(dst))
        if worst >= THRESHOLD:
            import os
            os.remove(dst)
            sys.exit(f"{dst}: a frame {worst:.0f} from the app was written — removed; look at the recording")
        print(f"  {dst}: every frame within {worst:.0f} of the app")

    cut(runs, out)
    if len(runs) == 2:
        base = out.rsplit(".", 1)[0]
        cut([runs[0]], base + "-on.mp4")
        cut([runs[1]], base + "-off.mp4")
    else:
        print(f"  {len(runs)} stretches, not 2: no -on/-off clips — look at the recording")


if __name__ == "__main__":
    main()
