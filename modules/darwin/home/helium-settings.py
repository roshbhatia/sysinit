import argparse
import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


def merge(target, desired):
    for key, value in desired.items():
        if isinstance(value, dict):
            if not isinstance(target.get(key), dict):
                target[key] = {}
            merge(target[key], value)
        else:
            target[key] = value


def running():
    result = subprocess.run(
        ["/usr/bin/pgrep", "-x", "Helium"],
        stdout=subprocess.DEVNULL,
        check=False,
    )
    if result.returncode not in (0, 1):
        raise RuntimeError("Cannot determine whether Helium is running")
    return result.returncode == 0


def main():
    parser = argparse.ArgumentParser(description="Merge managed Helium preferences")
    parser.add_argument("settings", type=Path)
    parser.add_argument("preferences", type=Path)
    parser.add_argument("--defer-running", action="store_true")
    args = parser.parse_args()
    desired = json.loads(args.settings.read_text())
    target = args.preferences
    if target.is_symlink():
        raise RuntimeError("Helium Preferences must remain a writable regular file")
    original = target.read_bytes() if target.exists() else None
    current = json.loads(original) if original is not None else {}
    updated = copy.deepcopy(current)
    merge(updated, desired)
    if current == updated:
        print("Helium preferences already match Home Manager")
        return
    if running():
        message = "Quit Helium, then run helium-settings to apply pending preferences"
        if args.defer_running:
            print(message)
            return
        raise SystemExit(message)
    target.parent.mkdir(parents=True, exist_ok=True)
    if original is not None:
        backup = target.with_name(f"Preferences.sysinit-backup-{time.time_ns()}")
        shutil.copy2(target, backup)
        backup.chmod(0o600)
    descriptor, temporary = tempfile.mkstemp(prefix=".sysinit-", dir=target.parent)
    try:
        with os.fdopen(descriptor, "w") as stream:
            json.dump(updated, stream, separators=(",", ":"))
            stream.flush()
            os.fsync(stream.fileno())
        if running() or (target.read_bytes() if target.exists() else None) != original:
            raise RuntimeError("Helium profile changed; quit Helium and retry")
        os.replace(temporary, target)
    finally:
        Path(temporary).unlink(missing_ok=True)
    print("Applied managed Helium preferences")


if __name__ == "__main__":
    main()
