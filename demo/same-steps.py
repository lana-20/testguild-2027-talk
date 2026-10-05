#!/usr/bin/env python3
"""Checks that motion-cli.sh runs the steps of tests/motion.test.json.

    demo/same-steps.py cli

The test file is the one source of the demo's steps. The MCP client sends
them as they are; the CLI client spells each as a mobium command, so this
reads the commands between "the test's steps" and "the measurement" in
motion-cli.sh, turns each back into the test's long form — the tool and its
arguments, the case's placeholders restored — and compares the two lists.
Exits 1 naming the first difference.
"""
import json, re, shlex, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PLACEHOLDERS = {"$1": "${animations}", "$2": "${reduce_motion}", "$3": "${reported}", "$4": "${confetti}"}


def long_form(step):
    """A test step in shorthand or long form, as {"name": app_x, "arguments": {...}}."""
    if "name" in step:
        return {"name": step["name"], "arguments": step.get("arguments", {})}
    (key, value), = step.items()
    args = value if isinstance(value, dict) else {"target": value}
    return {"name": "app_" + key, "arguments": args}


def test_steps():
    test = json.loads((HERE / "tests" / "motion.test.json").read_text())
    return [long_form(s) for s in test["tests"][0]["steps"]]


def cli_steps():
    src = (HERE / "motion-cli.sh").read_text()
    block = src.split("# --- the test's steps ---", 1)[1].split("# --- the measurement ---", 1)[0]
    steps = []
    for line in block.splitlines():
        line = line.strip()
        if not line.startswith("m "):
            continue
        cmd = line.split(">/dev/null")[0]
        for k, v in PLACEHOLDERS.items():
            cmd = cmd.replace(f'"{k}"', shlex.quote(v)).replace(k, v)
        words = shlex.split(cmd)[1:]
        tool, rest = words[0], words[1:]
        if tool == "accessibility":
            steps.append({"name": "app_accessibility", "arguments": {"setting": rest[0], "value": rest[1]}})
        elif tool == "tap":
            steps.append({"name": "app_tap", "arguments": {"target": rest[0]}})
        elif tool == "wait":
            args = {"target": rest[0]}
            i = 1
            while i < len(rest):
                flag = rest[i]
                if flag == "--for":
                    args["condition"] = rest[i + 1]; i += 2
                elif flag == "--text":
                    args["text"] = rest[i + 1]; i += 2
                elif flag == "--exact":
                    args["exact"] = True; i += 1
                else:
                    sys.exit(f"same-steps: a wait flag this check does not know: {flag}")
            steps.append({"name": "app_wait_for", "arguments": args})
        else:
            sys.exit(f"same-steps: a command this check does not know: {tool}")
    return steps


def main():
    if sys.argv[1:] != ["cli"]:
        sys.exit("usage: same-steps.py cli")
    want, got = test_steps(), cli_steps()
    for i, (w, g) in enumerate(zip(want, got), 1):
        if w != g:
            sys.exit(f"motion-cli.sh step {i} is not the test's:\n  test: {json.dumps(w, ensure_ascii=False)}\n  cli:  {json.dumps(g, ensure_ascii=False)}")
    if len(want) != len(got):
        sys.exit(f"motion-cli.sh has {len(got)} steps, the test {len(want)}")
    print(f"motion-cli.sh runs the test's {len(want)} steps")


if __name__ == "__main__":
    main()
