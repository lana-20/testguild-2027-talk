#!/usr/bin/env python3
"""The same phone, through the door an agent uses: `mobium mcp`, spoken to
directly over stdio, every request and every result printed.

    demo/mcp-session.py            # pauses at each beat; press return
    NOPAUSE=1 demo/mcp-session.py  # straight through

Same MOBIUM and IPHONE variables as the shell scripts. It changes nothing on
the phone outside MobiumApp.

The beat is the error an agent reads. A locator that matches two elements is
refused, with a code and a remedy, and the remedy is followed literally —
because an agent will. Then app_check, which reaches a state rather than
toggling toward one, is asked twice and does nothing the second time.
"""
import json, os, re, shutil, subprocess, sys

MOBIUM = os.environ.get("MOBIUM") or shutil.which("mobium")
if not MOBIUM:
    sys.exit("no mobium binary: set MOBIUM=/path/to/mobium")
APP = "dev.mobium.mobiumapp"

B, DIM, G, R, C, Y, N = "\033[1m", "\033[2m", "\033[32m", "\033[31m", "\033[36m", "\033[33m", "\033[0m"


def iphone():
    if os.environ.get("IPHONE"):
        return os.environ["IPHONE"]
    out = subprocess.run([MOBIUM, "devices"], capture_output=True, text=True).stdout
    for line in out.splitlines():
        if "(ios device" in line:
            return line.split()[0]
    sys.exit("no iPhone connected: plug it in, unlock it, and check 'mobium devices'")


def pause():
    if not os.environ.get("NOPAUSE"):
        input(f"{DIM}  ⏎{N}")


def say(s):
    print(f"\n{B}{s}{N}")


def note(s):
    print(f"{DIM}  {s}{N}")


class Session:
    def __init__(self, udid):
        # One automation session per phone: the CLI's daemon holds one,
        # and this process is about to open its own.
        subprocess.run([MOBIUM, "daemon", "stop"], capture_output=True)
        self.p = subprocess.Popen([MOBIUM, "mcp", "--driver", "wda", "--device", udid],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.DEVNULL, text=True, bufsize=1)
        self.next = 0

    def send(self, method, params=None, quiet=False):
        self.next += 1
        msg = {"jsonrpc": "2.0", "id": self.next, "method": method}
        if params is not None:
            msg["params"] = params
        if not quiet:
            print(f"{C}→ {json.dumps(msg, ensure_ascii=False)}{N}")
        self.p.stdin.write(json.dumps(msg) + "\n")
        self.p.stdin.flush()
        while True:
            line = self.p.stdout.readline()
            if not line:
                sys.exit("mobium mcp exited")
            reply = json.loads(line)
            if reply.get("id") == self.next:
                return reply

    def notify(self, method):
        self.p.stdin.write(json.dumps({"jsonrpc": "2.0", "method": method}) + "\n")
        self.p.stdin.flush()

    def call(self, tool, quiet=False, **args):
        reply = self.send("tools/call", {"name": tool, "arguments": args}, quiet=quiet)
        if "error" in reply:
            sys.exit(f"protocol error: {reply['error']}")
        res = reply["result"]
        text = "\n".join(c.get("text", "") for c in res.get("content", []))
        if not quiet:
            if res.get("isError"):
                sc = res.get("structuredContent") or {}
                print(f"{R}← isError: true{N}")
                print(f"{R}  {text}{N}")
                if sc:
                    keep = {k: sc[k] for k in ("code", "remedy", "retryable") if k in sc}
                    print(f"{Y}  structuredContent: {json.dumps(keep, ensure_ascii=False)}{N}")
            else:
                print(f"{G}← {text}{N}")
        return res, text

    def close(self):
        self.p.stdin.close()
        self.p.wait(timeout=60)


def main():
    s = Session(iphone())
    say("An agent's front door: mobium mcp, on stdio")
    init = s.send("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                 "clientInfo": {"name": "testguild-demo", "version": "1"}})
    info = init["result"]["serverInfo"]
    print(f"{G}← {info['name']} {info.get('version', '')}{N}")
    s.notify("notifications/initialized")
    tools = s.send("tools/list")["result"]["tools"]
    print(f"{G}← {len(tools)} tools: {', '.join(t['name'] for t in tools[:6])}, …{N}")
    note("the same tools as the CLI, by the same names — the CLI only parses flags and calls them")
    pause()

    s.call("app_terminate", quiet=True, app=APP)
    s.call("app_launch", app=APP)
    s.call("app_scroll_to", quiet=True, target="label=Motion Demo", direction="down")
    s.call("app_tap", target="label=Motion Demo")
    s.call("app_text", target="testid=reduceMotion")
    s.call("app_tap", target="label=Replay Honoring")
    s.call("app_tap", target="label=Honoring target")
    s.call("app_text", target="testid=honoringResult")
    note("the app is the witness: it says when the tap arrived, not the tool")
    pause()

    say("The error is an instruction, and an agent obeys it")
    res, _ = s.call("app_check", target="label=Pieces visible to automation")
    if not res.get("isError"):
        sys.exit("expected the ambiguous locator to be refused")
    note("React Native repeats a label across the views it renders: two matches,")
    note("and a tool that picked one would tap something silently. So: refused, with a code.")
    pause()
    note("the remedy says: use a ref from app_map. Followed literally —")
    _, m = s.call("app_map")
    ref = next((l.split()[0] for l in m.splitlines() if "Pieces visible to automation (switch" in l), None)
    if not ref:
        sys.exit("no switch in the map")
    s.call("app_check", target=ref)
    s.call("app_check", target=ref)
    note("asked twice, done once: app_check reaches a state, and reads it back to say so")
    s.call("app_check", quiet=True, target=ref, checked=False)
    pause()

    s.close()
    print(f"\n{G}  ✓ session closed{N}")


if __name__ == "__main__":
    main()
