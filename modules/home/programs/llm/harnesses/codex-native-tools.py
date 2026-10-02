import os
from pathlib import Path
import shutil
import tempfile

import tomlkit


def migrate(root):
    marker = root / ".sysinit-native-tools-v1"
    config = root / "config.toml"
    if marker.exists() or not config.exists():
        return

    for path in (config, root / ".config.toml.nix-base"):
        if not path.exists():
            continue
        original = path.read_text()
        document = tomlkit.parse(original)
        servers = document.get("mcp_servers", {})
        for name in ("computer-use", "cua_repl", "node_repl"):
            server = servers.get(name)
            if server is None:
                continue
            if path != config or (
                server.get("enabled") is False
                and (
                    name != "node_repl"
                    or server.get("command", "").endswith("/bin/false")
                )
            ):
                del servers[name]
            elif server.get("enabled") is False:
                del server["enabled"]

        plugins = document.get("plugins", {})
        for name in ("computer-use@openai-bundled", "browser@openai-bundled"):
            if name in plugins:
                if path == config:
                    plugins[name]["enabled"] = name != "computer-use@openai-bundled"
                else:
                    del plugins[name]
        document.get("features", {}).pop("js_repl", None)

        updated = tomlkit.dumps(document)
        if not updated.strip():
            updated = "[mcp_servers]\n"
        if updated != original:
            backup = path.with_name(path.name + ".before-native-tools")
            if not backup.exists():
                shutil.copy2(path, backup)
                backup.chmod(0o600)
            fd, temporary = tempfile.mkstemp(dir=root, prefix=".native-tools-")
            try:
                with os.fdopen(fd, "w") as output:
                    output.write(updated)
                os.replace(temporary, path)
            finally:
                Path(temporary).unlink(missing_ok=True)
    marker.touch(mode=0o600)


if __name__ == "__main__":
    migrate(Path.home() / ".codex")
