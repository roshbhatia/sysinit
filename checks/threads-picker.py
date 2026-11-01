import fcntl
import json
import os
from pathlib import Path
import pty
import select
import signal
import struct
import sys
import tempfile
import termios
import time

import pyte

binary = sys.argv[1]
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    fixture = root / "atuin"
    fixture.write_text("""#!/bin/sh
if [ "$*" = 'threads list --style json' ]; then
  printf '%s' '[{"atuin_id":"thread-a","harness":"claude-code","preview":"alpha","cwd":"/fixture"},{"atuin_id":"thread-b","harness":"codex","preview":"beta","cwd":"/fixture"}]'
else
  printf '\\nNATIVE:'
  printf ' <%s>' "$@"
  printf '\\n'
fi
""")
    fixture.chmod(0o700)
    for harness in ("codex", "claude"):
        executable = root / harness
        executable.write_text("#!/bin/sh\nexit 0\n")
        executable.chmod(0o700)
    (root / "sysinit").mkdir()
    (root / "sysinit/agents.json").write_text(
        json.dumps(
            {
                "version": 1,
                "agents": [
                    {
                        "name": name,
                        "label": name.capitalize(),
                        "command": str(root / name),
                    }
                    for name in ("claude", "codex")
                ],
            }
        )
    )
    cases = [
        ("Resume", 0, None, None, "<--as-is>"),
        ("Resume (Switch)", 1, 0, None, "<--in> <claude>"),
        ("Fork", 2, None, None, "<--fork>"),
        ("Fork (Switch)", 3, 0, None, "<--in> <claude>"),
        ("Inspect", 4, None, None, "NATIVE: <threads> <show> <thread-b>"),
        ("Resume original", 1, 1, None, "<--as-is>"),
        ("Fork original", 3, 1, None, "<--fork>"),
        ("Cancel thread", 0, None, "thread", None),
        ("Cancel action", 0, None, "action", None),
        ("Cancel harness", 1, 0, "harness", None),
        ("Fuzzy search", 0, None, None, "<--as-is>"),
        ("Normal navigation", 2, None, None, "<--fork>"),
        ("Resize", 0, None, None, "<--as-is>"),
    ]
    for name, action, target, cancel, expected in cases:
        child, master = pty.fork()
        if child == 0:
            os.write(1, b"original prompt > threads\r\n")
            os.execvpe(
                binary,
                [binary, "threads", "--print"],
                dict(
                    os.environ,
                    TERM="xterm-256color",
                    XDG_CONFIG_HOME=directory,
                    PATH=directory + os.pathsep + os.environ["PATH"],
                ),
            )
        rows = 12 if name == "Resize" else 30
        fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", rows, 140, 0, 0))
        screen = pyte.Screen(140, rows)
        stream = pyte.ByteStream(screen)
        output = bytearray()

        def collect(duration):
            deadline = time.monotonic() + duration
            while time.monotonic() < deadline:
                if select.select([master], [], [], 0.03)[0]:
                    try:
                        data = os.read(master, 65536)
                    except OSError:
                        return
                    if not data:
                        return
                    output.extend(data)
                    stream.feed(data)
                    if b"\x1b[6n" in data:
                        os.write(
                            master,
                            f"\x1b[{screen.cursor.y + 1};{screen.cursor.x + 1}R".encode(),
                        )

        def choose(stage, index):
            for _ in range(80):
                collect(0.05)
                visible = "\n".join(screen.display)
                if stage + ">" in visible:
                    break
            else:
                raise AssertionError((name, "missing picker", stage, screen.display))
            assert "original prompt > threads" in visible, (
                name,
                "original prompt erased",
            )
            if stage == "action":
                for label in (
                    "Resume",
                    "Resume (Switch)",
                    "Fork",
                    "Fork (Switch)",
                    "Inspect",
                ):
                    assert label in visible, (name, "missing action", label)
            if stage == cancel:
                os.write(master, b"\x03")
                return False
            if stage == "thread" and name == "Fuzzy search":
                os.write(master, b"bta")
                collect(0.15)
                assert "thread> bta" in "\n".join(screen.display), "typed query hidden"
            elif stage == "thread":
                os.write(master, b"\t")
                collect(0.05)
                os.write(master, b"\x1b[Z")
                collect(0.05)
                os.write(master, b"\t")
            elif stage == "action" and name == "Normal navigation":
                os.write(master, b"\x1b")
                collect(0.1)
                os.write(master, b"j" * index)
            else:
                for _ in range(index):
                    os.write(master, b"\x1b[B")
                    collect(0.05)
            if stage == "thread" and name == "Resize":
                fcntl.ioctl(
                    master, termios.TIOCSWINSZ, struct.pack("HHHH", 20, 46, 0, 0)
                )
                screen.resize(lines=20, columns=46)
                os.kill(child, signal.SIGWINCH)
                collect(0.2)
            collect(0.1)
            os.write(master, b"\r")
            collect(0.15)
            return True

        try:
            if choose("thread", 0) and choose("action", action) and target is not None:
                choose("harness", target)
            for _ in range(80):
                collect(0.05)
                found, status = os.waitpid(child, os.WNOHANG)
                if found:
                    child = None
                    break
            else:
                raise AssertionError((name, "did not exit", screen.display))
            assert os.waitstatus_to_exitcode(status) == 0, (name, bytes(output[-1500:]))
            visible = "\n".join(screen.display)
            if expected:
                assert expected.encode() in output, (name, visible)
                if name != "Inspect":
                    assert b"NATIVE: <resume> <thread-b> <--print>" in output, (
                        name,
                        visible,
                    )
            else:
                assert "NATIVE:" not in visible, (
                    name,
                    "cancellation launched a command",
                )
            assert b"\x1b[?1049h" not in output, (name, "fullscreen picker")
            assert "original prompt > threads" in visible, (name, "prompt lost on exit")
            print(name + ": passed", flush=True)
        finally:
            os.close(master)
            if child:
                os.kill(child, signal.SIGTERM)
                os.waitpid(child, 0)
