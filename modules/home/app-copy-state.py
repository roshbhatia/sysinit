import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


def app_snapshot(origin, app, codesign):
    if not app.name.endswith(".app") or not app.is_dir() or app.is_symlink():
        raise ValueError("application is not a copied bundle")
    subprocess.run(
        [codesign, "--verify", "--deep", "--strict", str(app)],
        check=True,
        capture_output=True,
    )
    requirement = subprocess.run(
        [codesign, "-d", "-r-", str(app)],
        check=True,
        capture_output=True,
        text=True,
    )
    return {
        "source": str(origin.resolve(strict=True)),
        "requirement": requirement.stdout + requirement.stderr,
    }


def snapshot(source, target, codesign):
    if not source.is_dir() or not target.is_dir() or target.is_symlink():
        raise ValueError("application directory is missing or is a symlink")
    names = sorted(path.name for path in source.iterdir())
    if names != sorted(path.name for path in target.iterdir()):
        raise ValueError("application lists differ")
    result = {}
    for name in names:
        origin, app = source / name, target / name
        result[name] = app_snapshot(origin, app, codesign)
    return result


def unchanged_apps(args):
    try:
        previous = json.loads(args.state.read_text())
    except (OSError, ValueError):
        previous = {}
    if not isinstance(previous, dict):
        previous = {}
    unchanged = set()
    for origin in args.source.iterdir():
        try:
            current = app_snapshot(origin, args.target / origin.name, args.codesign)
        except (OSError, ValueError, subprocess.CalledProcessError):
            continue
        if current == previous.get(origin.name):
            unchanged.add(origin.name)
    return unchanged


def guard_running(args, unchanged):
    for name in args.protect_running:
        if f"{name}.app" in unchanged:
            continue
        result = subprocess.run([args.pgrep, "-x", name], capture_output=True)
        if result.returncode == 0:
            raise ValueError(
                f"Quit {name} before switching: its app bundle would be replaced or removed"
            )
        if result.returncode != 1:
            raise ValueError(
                f"Cannot check whether {name} is running: pgrep exited {result.returncode}"
            )


def sync_apps(args):
    unchanged = unchanged_apps(args)
    guard_running(args, unchanged)
    excludes = []
    for name in sorted(unchanged):
        literal_name = re.sub(r"([\\*?\[])", r"\\\1", name)
        excludes.append(f"--exclude=/{literal_name}")
    args.target.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            args.rsync,
            "--recursive",
            "--checksum",
            "--perms",
            "--links",
            "--copy-unsafe-links",
            "--specials",
            "--delete",
            "--chmod=+w",
            *excludes,
            f"{args.source}/",
            str(args.target),
        ],
        check=True,
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("operation", choices=["check", "record", "sync", "preflight"])
    parser.add_argument("source", type=Path)
    parser.add_argument("target", type=Path)
    parser.add_argument("state", type=Path)
    parser.add_argument("--codesign", default="/usr/bin/codesign")
    parser.add_argument("--rsync", default="rsync")
    parser.add_argument("--protect-running", action="append", default=[])
    parser.add_argument("--pgrep", default="/usr/bin/pgrep")
    args = parser.parse_args()
    temporary = None
    try:
        if args.operation == "preflight":
            guard_running(args, unchanged_apps(args))
            return 0
        if args.operation == "sync":
            sync_apps(args)
            return 0
        previous = (
            json.loads(args.state.read_text()) if args.operation == "check" else None
        )
        current = snapshot(args.source, args.target, args.codesign)
        if args.operation == "check":
            return 0 if current == previous else 1
        args.state.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(
            mode="w", dir=args.state.parent, delete=False
        ) as handle:
            temporary = Path(handle.name)
            json.dump(current, handle, sort_keys=True)
        os.replace(temporary, args.state)
        temporary = None
        return 0
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        if args.operation in {"preflight", "sync"}:
            print(f"sysinit: {error}", file=sys.stderr)
        return 1
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())
