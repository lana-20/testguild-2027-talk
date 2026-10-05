#!/usr/bin/env python3
"""Build teleprompter.html from submission/TRANSCRIPT.md.

    python3 scripts/build_teleprompter.py     # -> teleprompter.html (served beside the deck)

The transcript is the source; this only lays it out to be read aloud: large type on black,
one block per slide with its number, id and start time, cues in brackets set apart, and a
scroll that runs by itself. Keys, shown on the page:

    space        start / stop scrolling        up / down    slower / faster (0.6 ≈ 150 words a minute)
    + / -        larger / smaller type         m            mirror (for a beam-splitter glass)
    n / p        next / previous slide         home         back to the top

Never edits the transcript.
"""
import html, re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "submission" / "TRANSCRIPT.md"
OUT = ROOT / "teleprompter.html"


def inline(text):
    t = html.escape(text)
    t = re.sub(r"\[([^\]]+)\]", r'<span class="cue">\1</span>', t)
    return t


def main():
    body = SRC.read_text().split("\n---\n", 1)[1]
    blocks = []
    for part in re.split(r"^## ", body, flags=re.M)[1:]:
        head, _, text = part.partition("\n")
        paras = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
        out = []
        for p in paras:
            p = " ".join(p.split("\n"))
            if re.fullmatch(r"\[[^\]]+\]", p):
                cls = "click" if p == "[click]" else "cueline"
                out.append(f'<p class="{cls}">{html.escape(p[1:-1])}</p>')
            else:
                out.append(f"<p>{inline(p)}</p>")
        blocks.append(f'<section class="slide"><h2>{html.escape(head.strip())}</h2>\n' + "\n".join(out) + "</section>")
    OUT.write_text(TEMPLATE.replace("{{BLOCKS}}", "\n".join(blocks)))
    print(f"wrote {OUT} - {len(blocks)} slides")


TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Teleprompter — Fast and Robust Mobile Tests with Mobium</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Rubik:wght@400;500;600&family=Fira+Code:wght@400;500&display=swap">
<style>
  :root { --bg:#000; --ink:#F2EFE8; --dim:#7C8791; --cue:#E0A526; --click:#4C8C6A; --line:rgba(224,165,38,.35); --size:56px; }
  html, body { margin:0; background:var(--bg); color:var(--ink); }
  body { font-family:Rubik, Arial, sans-serif; overflow:hidden; }
  #scroller { position:fixed; inset:0; overflow-y:scroll; scrollbar-width:none; }
  #scroller::-webkit-scrollbar { display:none; }
  #script { max-width:1500px; margin:0 auto; padding:45vh 6vw 80vh; font-size:var(--size); line-height:1.45; }
  #script.mirror { transform:scaleX(-1); }
  .slide { margin-bottom:1.6em; }
  h2 { font-family:'Fira Code', monospace; font-weight:500; font-size:.42em; color:var(--dim); letter-spacing:.06em;
       text-transform:uppercase; margin:0 0 .6em; padding-top:.6em; border-top:2px solid #222; }
  p { margin:0 0 .75em; }
  .cue { color:var(--cue); font-style:italic; font-size:.7em; }
  .cueline { color:var(--cue); font-style:italic; font-size:.6em; }
  .click { color:var(--click); font-family:'Fira Code', monospace; font-size:.45em; letter-spacing:.2em; text-transform:uppercase; }
  .click::before { content:"▶  "; }
  #guide { position:fixed; left:0; right:0; top:38vh; height:0; border-top:3px solid var(--line); pointer-events:none; }
  #hud { position:fixed; left:0; right:0; bottom:0; padding:10px 16px; background:#000; border-top:1px solid #222; display:flex; flex-wrap:wrap; gap:6px 18px; font:14px 'Fira Code', monospace; color:#6A747E; }
  #hud b { color:#C9D1D8; font-weight:500; }
  @media (max-width:700px) { :root { --size:30px; } #hud { font-size:11px; } }
</style>
</head>
<body>
<div id="scroller"><div id="script">
{{BLOCKS}}
</div></div>
<div id="guide"></div>
<div id="hud"><span><b id="state">paused</b> · space</span><span>speed <b id="speed">0.6</b> · ↑ ↓</span><span>type <b id="size">56</b>px · + −</span><span>mirror · m</span><span>slide · n p</span><span>top · home</span><span id="where"></span></div>
<script>
(function () {
  var sc = document.getElementById('scroller'), script = document.getElementById('script');
  var slides = Array.prototype.slice.call(document.querySelectorAll('.slide'));
  var running = false, speed = 0.6, size = window.innerWidth < 700 ? 30 : 56, last = null, carry = 0;
  function store(k, v) { try { localStorage.setItem('tp-' + k, v); } catch (e) {} }
  function load(k) { try { return localStorage.getItem('tp-' + k); } catch (e) { return null; } }
  if (load('size')) size = +load('size');
  if (load('speed')) speed = +load('speed');
  if (load('mirror') === '1') script.classList.add('mirror');
  function hud() {
    document.getElementById('state').textContent = running ? 'running' : 'paused';
    document.getElementById('speed').textContent = speed.toFixed(1);
    document.getElementById('size').textContent = size;
    document.documentElement.style.setProperty('--size', size + 'px');
    var line = sc.scrollTop + window.innerHeight * 0.38, cur = slides[0];
    slides.forEach(function (s) { if (s.offsetTop <= line) cur = s; });
    document.getElementById('where').textContent = cur ? cur.querySelector('h2').textContent : '';
  }
  function frame(t) {
    if (running) {
      if (last !== null) {
        carry += (t - last) / 1000 * 40 * speed * (size / 56);
        var whole = Math.floor(carry); carry -= whole; sc.scrollTop += whole;
      }
      last = t;
    } else { last = null; }
    hud();
  }
  function go(dir) {
    var line = sc.scrollTop + window.innerHeight * 0.38 + 2, i = 0;
    slides.forEach(function (s, k) { if (s.offsetTop <= line) i = k; });
    var j = Math.max(0, Math.min(slides.length - 1, i + dir));
    sc.scrollTop = slides[j].offsetTop - window.innerHeight * 0.38 + 4;
  }
  document.addEventListener('keydown', function (e) {
    if (e.key === ' ') { running = !running; e.preventDefault(); }
    else if (e.key === 'ArrowUp') { speed = Math.max(0.2, speed - 0.1); store('speed', speed); e.preventDefault(); }
    else if (e.key === 'ArrowDown') { speed = Math.min(4, speed + 0.1); store('speed', speed); e.preventDefault(); }
    else if (e.key === '+' || e.key === '=') { size = Math.min(120, size + 4); store('size', size); }
    else if (e.key === '-' || e.key === '_') { size = Math.max(20, size - 4); store('size', size); }
    else if (e.key === 'm') { script.classList.toggle('mirror'); store('mirror', script.classList.contains('mirror') ? '1' : '0'); }
    else if (e.key === 'n') { go(1); } else if (e.key === 'p') { go(-1); }
    else if (e.key === 'Home') { sc.scrollTop = 0; }
  });
  sc.addEventListener('click', function () { running = !running; });
  // A timer, not animation frames: it scrolls the same in a visible tab, and runs where frames
  // are not drawn — a headless check, or a window the prompter software has behind its mirror.
  hud(); setInterval(function () { frame(performance.now()); }, 16);
})();
</script>
</body>
</html>
"""

if __name__ == "__main__":
    main()
