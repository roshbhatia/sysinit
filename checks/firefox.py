import json
from pathlib import Path
import re
import sys


for fixture in json.loads(Path(sys.argv[1]).read_text()):
    for name in ("chrome", "content", "tridactyl", "newtab"):
        css = fixture[name]
        assert not re.search(r"@(?:base\w+|opacity|blur|monospace-font)\s*@", css), name
        assert "var(--sysinit-" not in css, name
        assert "#" + fixture["background"] in css, name
    policies = fixture["policies"]
    assert "HomepageURL" not in policies and "NewTabURL" not in policies
    assert policies["Homepage"]["StartPage"] == "previous-session"

bindings = {}
for line in Path(sys.argv[2]).read_text().splitlines():
    if not line.startswith("bind "):
        continue
    fields = line.split()
    mode = "normal"
    if fields[1].startswith("--mode="):
        mode = fields.pop(1).split("=", 1)[1]
    key = tuple(re.findall(r"<[^>]+>|.", fields[1]))
    scoped = bindings.setdefault(mode, {})
    assert key not in scoped, (mode, key, "duplicate")
    for other in scoped:
        assert not (key[: len(other)] == other or other[: len(key)] == key), (
            mode,
            key,
            other,
            "prefix collision",
        )
    scoped[key] = " ".join(fields[2:])
normal = bindings["normal"]
assert ("<A-p>",) not in normal and ("<A-m>",) not in normal
assert normal[("<Space>", "t", "u")] == "undo"
print("Rendered themes and scoped binding prefixes passed")
