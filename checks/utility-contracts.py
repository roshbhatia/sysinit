import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
with tempfile.TemporaryDirectory() as temporary:
    scratch = Path(temporary)
    env = os.environ | {
        "PATH": temporary + os.pathsep + os.environ["PATH"],
        "WEZTERM_PANE": "fixture",
        "ASK_CAPTURE": "1",
    }

    def stub(name, body):
        file = scratch / name
        file.write_text("#!/bin/sh\n" + body + "\n")
        file.chmod(0o755)

    def run(args, **kwargs):
        return subprocess.run(
            args, env=env, capture_output=True, text=True, timeout=4, **kwargs
        )

    stub("wezterm", 'printf "fixture failure\\n" >&2\nexit 23')
    result = run(
        [
            "nu",
            "--no-config-file",
            str(root / "modules/home/programs/utils/dev/connect.nu"),
            "fixture",
        ]
    )
    assert result.returncode == 23 and "fixture failure" in result.stderr, result
    record = scratch / "calls"
    stub("sudo", 'printf "%s\\n" "$*" >> "$CALLS"\nexit "${FAIL:-0}"')
    env["CALLS"] = str(record)
    dns = root / "modules/home/programs/utils/network/dns-flush.nu"
    for platform, expected in [
        ("macos", ["dscacheutil -flushcache", "killall -HUP mDNSResponder"]),
        ("linux", ["resolvectl flush-caches"]),
    ]:
        record.write_text("")
        result = run(
            [
                "nu",
                "--no-config-file",
                "-c",
                f"use {json.dumps(str(dns))} flush; flush {platform}",
            ]
        )
        assert result.returncode == 0, result.stderr
        assert record.read_text().splitlines() == expected
    env["FAIL"] = "7"
    record.write_text("")
    result = run(
        [
            "nu",
            "--no-config-file",
            "-c",
            f"use {json.dumps(str(dns))} flush; flush macos",
        ]
    )
    assert result.returncode == 7 and len(record.read_text().splitlines()) == 1
    source = scratch / "seshy.zsh"
    source.write_text(
        (root / "modules/home/programs/zsh/integrations/seshy-wezterm.zsh")
        .read_text()
        .replace("@seshySessions@", "'/tmp/custom sessions'")
    )
    result = run(
        [
            "zsh",
            "-f",
            "-c",
            'source "$1"; weznot() { :; }; capture() { printf "<%s>\\n" "$@"; return 19; }; wezmon capture "one two" "" "literal; echo BAD"',
            "fixture",
            str(source),
        ]
    )
    assert result.returncode == 19, result
    assert result.stdout == "<one two>\n<>\n<literal; echo BAD>\n", result.stdout
    result = run(
        [
            "zsh",
            "-f",
            "-c",
            'source "$1"; wezmon printf "%s" data',
            "fixture",
            str(source),
        ]
    )
    assert result.returncode == 0 and result.stdout == "data", result
    result = run(
        [
            "zsh",
            "-f",
            "-c",
            'source "$1"; _seshy_session_name "/tmp/custom sessions/project/repo"',
            "fixture",
            str(source),
        ]
    )
    assert result.stdout == "project\n", result
    stub("wezterm", "printf snapshot")
    stub("ask", "sleep 10")
    hook = scratch / "hook.zsh"
    hook.write_text(
        (root / "modules/home/programs/zsh/integrations/ask.zsh")
        .read_text()
        .replace("@timeout@", "timeout")
    )
    result = run(
        [
            "zsh",
            "-f",
            "-c",
            'source "$1"; _ask_capture; printf ready',
            "fixture",
            str(hook),
        ]
    )
    assert result.returncode == 0 and result.stdout == "ready", result
    for name in ["gh", "chafa"]:
        stub(name, "exit 0")
    wallpapers = scratch / "home/.local/share/wallpapers"
    wallpapers.mkdir(parents=True)
    selected = str(wallpapers / 'name "quoted" and trailing ')
    env["HOME"] = str(scratch / "home")
    env["SELECTED"] = selected
    env["PICKER_EXIT"] = "0"
    env["APPLY_EXIT"] = "0"
    stub("fd", 'printf "%s\\0" "$SELECTED"')
    stub("fzf", 'cat >/dev/null; printf "%s\\0" "$SELECTED"; exit "$PICKER_EXIT"')
    stub("osascript", 'printf "%s" "$3" > "$CALLS"; exit "$APPLY_EXIT"')
    wallpaper = root / "modules/home/programs/utils/system/set-background.nu"
    if sys.platform == "darwin":
        result = run(["nu", "--no-config-file", str(wallpaper)])
        assert result.returncode == 0 and record.read_text() == selected, result
        env["APPLY_EXIT"] = "9"
        result = run(["nu", "--no-config-file", str(wallpaper)])
        assert result.returncode == 9, result
    record.write_text("untouched")
    env["PICKER_EXIT"] = "130"
    result = run(["nu", "--no-config-file", str(wallpaper)])
    assert result.returncode == 0 and record.read_text() == "untouched", result
    env["PICKER_EXIT"] = "2"
    result = run(["nu", "--no-config-file", str(wallpaper)])
    assert result.returncode == 2, result
print("Utility runtime contracts passed")
