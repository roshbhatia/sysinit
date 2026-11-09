#!/usr/bin/env python3
"""Inspect managed skill coverage and differing copies without changing them."""

import argparse
import hashlib
import json
import os
from pathlib import Path


def inventory(catalog, home, extra_roots):
    declared = json.loads(catalog.read_text())
    managed = [home / root for root in declared["roots"]]
    roots = list(dict.fromkeys(managed + extra_roots))
    copies = {}
    missing = {}
    for root in roots:
        names = set()
        for file in sorted(root.glob("*/SKILL.md")):
            names.add(file.parent.name)
            copies.setdefault(file.parent.name, []).append(
                {
                    "path": str(file),
                    "managed": root in managed,
                    "sha256": hashlib.sha256(file.read_bytes()).hexdigest(),
                }
            )
        if root in managed:
            missing[str(root)] = sorted(set(declared["descriptions"]) - names)
    return {
        "missing": missing,
        "copies": copies,
        "different_copies": sorted(
            name
            for name, files in copies.items()
            if len({file["sha256"] for file in files}) > 1
        ),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--catalog",
        type=Path,
        default=Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
        / "sysinit/skills.json",
    )
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--root", type=Path, action="append", default=[])
    parser.add_argument(
        "--check",
        action="store_true",
        help="fail if a managed root lacks declared skills",
    )
    args = parser.parse_args()
    result = inventory(
        args.catalog, args.home, [root.expanduser() for root in args.root]
    )
    print(json.dumps(result, sort_keys=True))
    return 1 if args.check and any(result["missing"].values()) else 0


if __name__ == "__main__":
    raise SystemExit(main())
