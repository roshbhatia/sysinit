import fcntl
import json
import os
from pathlib import Path
import pty
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time

import pyte


queue = str(Path(sys.argv[1]).resolve())
with tempfile.TemporaryDirectory(prefix="queue-browser-", dir="/tmp") as directory:
    root = Path(directory).resolve()
    config = root / "pueue.json"
    config.write_text(
        json.dumps(
            {
                "shared": {
                    "pueue_directory": str(root / "data"),
                    "runtime_directory": str(root),
                    "unix_socket_path": str(root / "socket"),
                }
            }
        )
    )
    atuin = root / "atuin"
    atuin.write_text("""#!/bin/sh
if [ "$*" = 'threads list --style json' ]; then
  printf '%s' '[{"atuin_id":"thread-a"},{"atuin_id":"thread-b"}]'
else
  printf '\\nCONVERSATION:'; printf ' <%s>' "$@"; printf '\\n'
fi
""")
    atuin.chmod(0o700)
    env = os.environ | {
        "HOME": str(root),
        "PUEUE_CONFIG_PATH": str(config),
        "PATH": str(root) + os.pathsep + os.environ["PATH"],
        "TERM": "xterm-256color",
    }
    command = [queue, "--state", str(root / "attempts")]

    def run(*args):
        return subprocess.run(
            args, env=env, text=True, capture_output=True, check=True, timeout=10
        ).stdout

    daemon = subprocess.Popen(
        ["pueued"], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    try:
        for _ in range(100):
            if (root / "socket").exists():
                break
            time.sleep(0.05)
        else:
            raise AssertionError("isolated Pueue daemon did not start")
        for thread, marker in (
            ("thread-a", "OLDER"),
            ("thread-b", "UNRELATED"),
            ("thread-a", "NEWER"),
        ):
            run(
                *command,
                "submit",
                "--cwd",
                str(root),
                "--thread",
                thread,
                "--",
                "printf",
                marker,
            )
        for _ in range(100):
            records = json.loads(run(*command, "status"))
            if all(
                isinstance(a["result"], dict) and "Done" in a["result"] for a in records
            ):
                break
            time.sleep(0.05)
        else:
            raise AssertionError("fixture commands did not finish")
        for cancel in (False, True):
            child, master = pty.fork()
            if child == 0:
                os.write(1, b"original prompt > task-queue browse\r\n")
                os.execvpe(queue, command + ["browse", "--thread", "thread-a"], env)
            fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))
            screen = pyte.Screen(120, 30)
            stream = pyte.ByteStream(screen)
            output = bytearray()

            def collect():
                if select.select([master], [], [], 0.05)[0]:
                    try:
                        data = os.read(master, 65536)
                    except OSError:
                        return
                    output.extend(data)
                    stream.feed(data)
                    if b"\x1b[6n" in data:
                        os.write(
                            master,
                            f"\x1b[{screen.cursor.y + 1};{screen.cursor.x + 1}R".encode(),
                        )

            def visible(text):
                for _ in range(100):
                    collect()
                    if text in "\n".join(screen.display):
                        return
                raise AssertionError((text, screen.display))

            def send(keys, text):
                os.write(master, keys)
                visible(text)

            try:
                visible("queue>")
                assert "UNRELATED" not in "\n".join(screen.display)
                # Reading status must remain possible while the browser waits for input.
                assert len(json.loads(run(*command, "status"))) == 3
                if cancel:
                    os.write(master, b"\x1b")
                else:
                    send(b"j", "> #0")
                    send(b"k", "> #2")
                    send(b"/missing", "No matches")
                    os.write(master, b"\r")
                    visible("No matches")
                    send(b"\x15", "NEWER")
                    send(b"\x1b", "NORMAL")
                    send(b"\r", "action>")
                    send(b"j", "> Inspect captured conversation")
                    os.write(master, b"\r")
                for _ in range(100):
                    collect()
                    found, status = os.waitpid(child, os.WNOHANG)
                    if found:
                        child = None
                        break
                    time.sleep(0.02)
                else:
                    raise AssertionError("browser did not exit")
                assert os.waitstatus_to_exitcode(status) == 0, bytes(output[-2000:])
                assert (
                    b"CONVERSATION: <threads> <show> <thread-a>" in output
                ) != cancel
                assert b"\x1b[?1049h" not in output
                assert "original prompt > task-queue browse" in "\n".join(
                    screen.display
                )
            finally:
                os.close(master)
                if child:
                    os.kill(child, signal.SIGTERM)
                    os.waitpid(child, 0)
        print(
            "Queue browser: j/k, filtering, thread identity, unlocked status, inspection, cancellation, and prompt preservation passed"
        )
    finally:
        subprocess.run(["pueue", "kill", "--all"], env=env, capture_output=True)
        daemon.terminate()
        daemon.wait(timeout=10)
