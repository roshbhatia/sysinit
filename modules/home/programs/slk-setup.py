import os
import sys
import tempfile
from collections.abc import Mapping
from pathlib import Path

import tomlkit


def merge(target, settings):
    for key, value in settings.items():
        if isinstance(value, Mapping):
            if key not in target:
                target[key] = tomlkit.table()
            if not isinstance(target[key], Mapping):
                raise ValueError(f"Expected table for {key}")
            merge(target[key], value)
        else:
            target[key] = value


def configure(path, settings):
    original = path.read_text() if path.exists() else ""
    document = tomlkit.parse(original)
    merge(document, tomlkit.parse(settings.read_text()))
    contents = tomlkit.dumps(document)
    if contents == original:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=".config.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as stream:
            stream.write(contents)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == "__main__":
    configure(Path(sys.argv[1]), Path(sys.argv[2]))
