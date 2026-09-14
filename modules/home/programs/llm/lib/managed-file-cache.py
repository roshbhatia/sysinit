import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile


def fingerprint(paths, policy):
    hashes = []
    for name in paths:
        path = Path(name)
        if not path.is_file() or path.is_symlink():
            raise ValueError("managed file is missing or is a symlink")
        hashes.append(hashlib.sha256(path.read_bytes()).hexdigest())
    return {"files": hashes, "inputs": paths[2:], "policy": policy}


def run(arguments):
    operation, cache, target, base, declared, schema, *policy = arguments
    paths = [target, base, declared] + ([schema] if schema != "-" else [])
    state = Path(cache)
    try:
        current = fingerprint(paths, policy)
        if operation == "check":
            return 0 if json.loads(state.read_text()) == current else 1
        if operation != "record":
            raise ValueError("invalid operation")
        state.parent.mkdir(parents=True, exist_ok=True)
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(mode="w", dir=state.parent, delete=False) as handle:
                temporary = Path(handle.name)
                json.dump(current, handle)
            os.replace(temporary, state)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
        return 0
    except (OSError, ValueError):
        return 1


def main():
    if sys.argv[1] != "batch":
        return run(sys.argv[1:])
    manifest, revision = sys.argv[2:]
    for entry in json.loads(Path(manifest).read_text()):
        name, relative, format_name, declared, declared_format, schema, enforced, retired, create = entry
        target = Path.home() / relative
        base = target.with_name(("" if target.name.startswith(".") else ".") + target.name + ".nix-base")
        arguments = ["check", str(base) + ".cache", str(target), str(base), declared, schema,
                     format_name, declared_format, enforced, retired, create, revision]
        if run(arguments):
            sys.stdout.buffer.write(name.encode() + b"\0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
