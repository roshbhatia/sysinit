import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys


def apply(entries, defaults="/usr/bin/defaults", restart="/usr/bin/killall"):
    domains = {}
    for domain, values in entries:
        domain = os.path.expanduser(domain)
        domains.setdefault(domain, {}).update(values)
    changed = 0
    dock_changed = False
    for domain, desired in domains.items():
        result = subprocess.run([defaults, "export", domain, "-"], capture_output=True)
        if result.returncode:
            if b"does not exist" not in result.stderr + result.stdout:
                raise RuntimeError(result.stderr.decode(errors="replace"))
            current = {}
        else:
            current = plistlib.loads(result.stdout)
        for key, value in desired.items():
            if key in current and current[key] == value:
                continue
            payload = plistlib.dumps(value).decode()
            subprocess.run([defaults, "write", domain, key, payload], check=True)
            changed += 1
            dock_changed |= domain == "com.apple.dock"
    if dock_changed:
        subprocess.run([restart, "-q", "Dock"], check=False)
    print(f"sysinit: updated {changed} macOS defaults")
    return changed


if __name__ == "__main__":
    apply(json.loads(Path(sys.argv[1]).read_text()))
