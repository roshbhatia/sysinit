import json
import os
from pathlib import Path
import shutil
import tempfile


def configure(root):
    for path in root.glob("plugins/cache/openai-codex/codex/*/hooks/hooks.json"):
        original = path.read_text()
        document = json.loads(original)
        changed = False
        for group in document.get("hooks", {}).get("SessionEnd", []):
            for hook in group.get("hooks", []):
                timeout = hook.get("timeout")
                if isinstance(timeout, (int, float)) and timeout > 3:
                    hook["timeout"] = 3
                    changed = True
        if not changed:
            continue
        backup = path.with_name("hooks.json.before-sysinit-timeout")
        if not backup.exists():
            shutil.copy2(path, backup)
        fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=".hooks-")
        try:
            with os.fdopen(fd, "w") as output:
                output.write(json.dumps(document, indent=2) + "\n")
            os.chmod(temporary, path.stat().st_mode & 0o777)
            os.replace(temporary, path)
        finally:
            Path(temporary).unlink(missing_ok=True)


if __name__ == "__main__":
    configure(Path.home() / ".codex")
