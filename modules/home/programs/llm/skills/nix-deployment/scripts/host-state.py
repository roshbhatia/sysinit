#!/usr/bin/env python3
"""Read source pins and compare a prepared Nix host with the active system."""

import argparse
import json
import os
from pathlib import Path
import subprocess


def inspect(flake, result=None, active=Path("/run/current-system")):
    flake = Path(flake).resolve(strict=True)
    revision = subprocess.run(
        ["git", "-C", str(flake), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
        timeout=15,
    ).stdout.strip()
    dirty = subprocess.run(
        ["git", "-C", str(flake), "status", "--porcelain"],
        check=True,
        capture_output=True,
        text=True,
        timeout=15,
    ).stdout.splitlines()
    lock = json.loads((flake / "flake.lock").read_text())
    pins = {
        name: node["locked"].get("rev")
        for name, node in lock["nodes"].items()
        if "locked" in node
    }
    state = {
        "flake": str(flake),
        "revision": revision,
        "changes": dirty,
        "pins": pins,
        "active": str(active.resolve()) if active.exists() else None,
    }
    if result is not None:
        state["prepared"] = str(Path(result).resolve(strict=True))
        state["matches"] = state["active"] == state["prepared"]
    return state


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--flake",
        default=os.environ.get("NH_FLAKE"),
        required=not os.environ.get("NH_FLAKE"),
    )
    parser.add_argument("--result")
    args = parser.parse_args()
    state = inspect(args.flake, args.result)
    print(json.dumps(state, sort_keys=True))
    return 1 if state.get("matches") is False else 0


if __name__ == "__main__":
    raise SystemExit(main())
