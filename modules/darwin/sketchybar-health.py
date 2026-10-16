import argparse
import json
import os
from pathlib import Path
import subprocess
import time


def run(*args):
    return subprocess.run(
        args, check=True, capture_output=True, text=True, timeout=5
    ).stdout


def probe(sketchybar, now, command=run):
    try:
        bar = json.loads(command(sketchybar, "--query", "bar"))
        if not isinstance(bar, dict):
            raise ValueError("invalid bar response")
    except (subprocess.SubprocessError, ValueError) as error:
        return False, f"bar query failed: {error}"
    required = {"logo", "front_app", "clock", "battery", "sysinit_health"}
    items = bar.get("items")
    if not isinstance(items, list) or not all(isinstance(item, str) for item in items):
        return True, "invalid widget list"
    if not required.issubset(items):
        return True, "required widgets are missing"
    try:
        heartbeat = json.loads(command(sketchybar, "--query", "sysinit_health"))
        age = now - int(heartbeat["label"]["value"])
        if not 0 <= age <= 90:
            return True, f"Lua heartbeat is stale ({age}s)"
    except (subprocess.SubprocessError, ValueError, KeyError, TypeError) as error:
        return True, f"heartbeat query failed: {error}"
    return True, ""


def decide(state, now, reason, monitors):
    if now - state.get("last_check", now) > 90:
        state["ready_at"] = now + 60
        state["failures"] = 0
    state["last_check"] = now
    state.setdefault("ready_at", now + 60)
    state["failures"] = state.get("failures", 0) + 1 if reason else 0
    changed = monitors is not None and monitors != state.get("monitors")
    if now < state["ready_at"] or now - state.get("last_recovery", 0) < 120:
        return ""
    if reason and state["failures"] >= 2:
        return reason
    if not reason and changed:
        return "monitor configuration changed"
    return ""


def recover(sketchybar, reachable, previous_reload, now, command=run):
    if reachable and now - previous_reload >= 600:
        try:
            command(sketchybar, "--reload")
            return "reload"
        except subprocess.SubprocessError:
            pass
    command(
        "/bin/launchctl", "kickstart", "-k", f"gui/{os.getuid()}/org.nixos.sketchybar"
    )
    return "restart"


def save(path, state):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(state) + "\n")
    temporary.replace(path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sketchybar", required=True)
    parser.add_argument("--aerospace", required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    now = int(time.time())
    reachable, reason = probe(args.sketchybar, now)
    if args.check:
        print(reason or "SketchyBar is healthy")
        return int(bool(reason))
    cache = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
    path = cache / "sketchybar" / "health.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        state = json.loads(path.read_text())
        if not isinstance(state, dict):
            raise ValueError("invalid health state")
    except (FileNotFoundError, ValueError):
        state = {}
    try:
        monitors = sorted(run(args.aerospace, "list-monitors").splitlines()) or None
    except subprocess.SubprocessError as error:
        print(f"Monitor query failed: {error}", flush=True)
        monitors = None
    action = decide(state, now, reason, monitors)
    if action:
        previous_reload = state.get("last_reload", 0) if reason else 0
        state["last_recovery"] = now
        state["failures"] = 0
        save(path, state)
        result = recover(args.sketchybar, reachable, previous_reload, now)
        if result == "reload":
            state["last_reload"] = now
        if monitors is not None:
            state["monitors"] = monitors
        print(f"SketchyBar {result}: {action}", flush=True)
    elif monitors is not None and "monitors" not in state:
        state["monitors"] = monitors
    save(path, state)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
