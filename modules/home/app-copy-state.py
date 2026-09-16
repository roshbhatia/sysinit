import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile


def snapshot(source, target, codesign):
    if not source.is_dir() or not target.is_dir() or target.is_symlink():
        raise ValueError("application directory is missing or is a symlink")
    names = sorted(path.name for path in source.iterdir())
    if names != sorted(path.name for path in target.iterdir()):
        raise ValueError("application lists differ")
    result = {}
    for name in names:
        origin, app = source / name, target / name
        if not name.endswith(".app") or not app.is_dir() or app.is_symlink():
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
        result[name] = {
            "source": str(origin.resolve(strict=True)),
            "requirement": requirement.stdout + requirement.stderr,
        }
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("operation", choices=["check", "record"])
    parser.add_argument("source", type=Path)
    parser.add_argument("target", type=Path)
    parser.add_argument("state", type=Path)
    parser.add_argument("--codesign", default="/usr/bin/codesign")
    args = parser.parse_args()
    temporary = None
    try:
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
    except (OSError, ValueError, subprocess.CalledProcessError):
        return 1
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())
