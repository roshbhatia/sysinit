"""Check real rendered metadata and every declared managed installation path."""

import json
import re
from pathlib import Path
import sys

manifest = json.loads(Path(sys.argv[1]).read_text())
for file in manifest["paths"] + manifest["fixtureFiles"]:
    assert Path(file).is_file(), file
assert "disable-model-invocation: false" in manifest["rendered"]
assert 'model: "haiku"' in manifest["rendered"]
assert "model:" not in manifest["amp"]
assert (
    json.loads(
        next(
            line.split(": ", 1)[1]
            for line in manifest["rendered"].splitlines()
            if line.startswith("description:")
        )
    )
    == "It's a fixture"
)
print("Skill metadata, root/nested resources, and all managed roots passed")
assert len(manifest["guidance"].splitlines()) <= 100
for case in manifest["cases"]:
    assert case["prompt"].strip()
    assert set(case["expected"] + case["avoid"]) <= set(manifest["names"])
for package in manifest["packages"]:
    for relative in re.findall(
        r"\]\(((?:references|scripts|assets)/[^)#]+)(?:#[^)]*)?\)", package["content"]
    ):
        assert relative in package["files"], (package["name"], relative)
