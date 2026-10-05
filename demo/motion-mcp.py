#!/usr/bin/env python3
"""The demo test, through MCP: tests/motion.test.json's steps sent to
`mobium mcp` as tools/call requests, as they are in the file.

    demo/motion-mcp.py <device> [driver]          # driver: wda for iOS
    ROUNDS=3 demo/motion-mcp.py emulator-5554
    SHOW=1 demo/motion-mcp.py emulator-5554       # print every request

A test step is already a tool call — {"tap": "label=Motion Demo"} is app_tap
with that target — so this reads the steps from the test file and sends
them, each case's values filled in. Nothing is restated, nothing can drift.

Each round runs both cases from a fresh launch, as `mobium test` does, then
reads the two times the app kept and the case's own time: from opening the
Motion Demo to its last check, not the setting switch or the launch. One
line per case, in the CLI client's format:

    mcp  emulator-5554  on   honoring 2517  control 2584  case 9.81

The device's animation setting is read before and after the run, each in a
session of its own, and a difference is reported, not fixed.
MOBIUM=/path/to/mobium if it is not on PATH.
"""
import json, os, re, shutil, subprocess, sys, time
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = "dev.mobium.mobiumapp"
MOBIUM = os.environ.get("MOBIUM") or shutil.which("mobium") or sys.exit("no mobium: set MOBIUM")
SHOW = bool(os.environ.get("SHOW"))


class MCP:
    """One `mobium mcp` server on stdio: one session on the device."""

    def __init__(self, device, driver):
        cmd = [MOBIUM, "mcp", "--device", device] + (["--driver", driver] if driver else [])
        self.p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.DEVNULL, text=True, bufsize=1)
        self.n = 0
        self.request("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                    "clientInfo": {"name": "motion-mcp", "version": "1"}})
        self.p.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n")

    def request(self, method, params):
        self.n += 1
        self.p.stdin.write(json.dumps({"jsonrpc": "2.0", "id": self.n, "method": method, "params": params}) + "\n")
        self.p.stdin.flush()
        while True:
            line = self.p.stdout.readline()
            if not line:
                sys.exit("mobium mcp exited")
            reply = json.loads(line)
            if reply.get("id") == self.n:
                return reply

    def call(self, name, args):
        if SHOW:
            print(f"  → {name} {json.dumps(args, ensure_ascii=False)}")
        res = self.request("tools/call", {"name": name, "arguments": args})["result"]
        text = "\n".join(c.get("text", "") for c in res.get("content", []))
        if res.get("isError"):
            code = (res.get("structuredContent") or {}).get("code", "")
            sys.exit(f"{name} {json.dumps(args, ensure_ascii=False)} failed [{code}]: {text}")
        return text

    def close(self):
        # Closing stdin ends the session, which puts back what it changed.
        self.p.stdin.close()
        self.p.wait(timeout=120)


def long_form(step):
    if "name" in step:
        return step["name"], step.get("arguments", {})
    (key, value), = step.items()
    return "app_" + key, (value if isinstance(value, dict) else {"target": value})


def fill(value, case):
    if isinstance(value, str):
        return re.sub(r"\$\{(\w+)\}", lambda m: str(case[m.group(1)]), value)
    if isinstance(value, dict):
        return {k: fill(v, case) for k, v in value.items()}
    return value


def tapped(text):
    m = re.search(r"tapped (\d+)ms", text)
    return m.group(1) if m else "?"


def setting(device, driver):
    s = MCP(device, driver)
    v = s.call("app_accessibility", {"setting": "reduce_motion"}).split()[1]
    s.close()
    return v


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: motion-mcp.py <device> [driver]")
    device, driver = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "")
    rounds = int(os.environ.get("ROUNDS", "1"))
    test = json.loads((HERE / "tests" / "motion.test.json").read_text())["tests"][0]
    steps = [long_form(s) for s in test["steps"]]

    # One session per device: a CLI daemon holding one would be cut off.
    subprocess.run([MOBIUM, "daemon", "stop"], capture_output=True)
    before = setting(device, driver)
    s = MCP(device, driver)
    for _ in range(rounds):
        for case in test["each"]:
            s.call("app_terminate", {"app": APP})
            s.call("app_launch", {"app": APP})
            # --- the test's steps, from the file ---
            t0 = None
            for name, args in steps:
                if name != "app_accessibility" and t0 is None:
                    t0 = time.time()
                s.call(name, fill(args, case))
            t1 = time.time()
            # --- the measurement ---
            h = tapped(s.call("app_text", {"target": "testid=honoringResult"}))
            c = tapped(s.call("app_text", {"target": "testid=ignoringResult"}))
            print(f"mcp  {device}  {case['animations']:<3}  honoring {h}  control {c}  case {t1 - t0:.2f}", flush=True)
    s.close()
    after = setting(device, driver)
    if after != before:
        sys.exit(f"WARNING: reduce_motion was {before} before and is {after} now — put it back by hand")
    print(f"reduce_motion as found: {after}")


if __name__ == "__main__":
    main()
