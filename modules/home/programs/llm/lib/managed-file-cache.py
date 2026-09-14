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


def main():
    operation, cache, target, base, declared, schema, *policy = sys.argv[1:]
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


if __name__ == "__main__":
    sys.exit(main())
