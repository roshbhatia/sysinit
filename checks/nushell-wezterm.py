import base64
import fcntl
import os
from pathlib import Path
import pty
import re
import select
import signal
import struct
import sys
import tempfile
import termios
import time
from urllib.parse import unquote, urlparse


def check(config, terminal):
    with tempfile.TemporaryDirectory() as directory:
        child, master = pty.fork()
        if child == 0:
            environment = dict(
                os.environ,
                HOME=directory,
                TERM="xterm-256color",
                TERM_PROGRAM=terminal,
                USER="integration-user",
                WEZTERM_HOSTNAME="integration-host",
                ASK_CAPTURE="0",
            )
            for key in ["WEZTERM_PANE", "TMUX"]:
                environment.pop(key, None)
            os.execvpe("nu", ["nu", "--config", config, "-i"], environment)
        fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))
        output = bytearray()

        def wait(predicate):
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline:
                if select.select([master], [], [], 0.1)[0]:
                    data = os.read(master, 65536)
                    output.extend(data)
                    if b"\x1b[6n" in data:
                        os.write(master, b"\x1b[1;1R")
                    if predicate(bytes(output)):
                        return
            raise AssertionError(bytes(output[-4000:]))

        try:
            wait(lambda data: b"\x1b]133;B" in data)
            command = 'print "integration-output"'
            os.write(master, (command + "\r").encode())
            wait(lambda data: b"\x1b]133;D;0" in data)
            os.write(master, b"^sh -c 'exit 7'\r")
            wait(lambda data: b"\x1b]133;D;7" in data)
            target = Path(directory) / "directory with spaces"
            target.mkdir()
            os.write(master, f"cd '{target}'\r".encode())
            wait(
                lambda data: any(
                    unquote(urlparse(value.decode()).path) == str(target)
                    for value in re.findall(rb"\x1b]7;([^\x1b\x07]+)", data)
                )
            )
            data = bytes(output)
            for marker in [
                b"133;A",
                b"133;B",
                b"133;C",
                b"133;D;0",
                b"133;D;7",
                b"]7;file://",
            ]:
                assert marker in data, marker
            values = [
                (name.decode(), base64.b64decode(value).decode())
                for name, value in re.findall(
                    rb"\x1b]1337;SetUserVar=([^=]+)=([^\x07]*)\x07", data
                )
            ]
            if terminal == "WezTerm":
                for pair in [
                    ("WEZTERM_USER", "integration-user"),
                    ("WEZTERM_HOST", "integration-host"),
                    ("WEZTERM_IN_TMUX", "0"),
                    ("WEZTERM_PROG", command),
                    ("WEZTERM_PROG", ""),
                ]:
                    assert pair in values, (pair, values)
            else:
                assert not values, values
        finally:
            os.close(master)
            os.kill(child, signal.SIGTERM)
            os.waitpid(child, 0)


check(sys.argv[1], "WezTerm")
check(sys.argv[1], "other-terminal")
print(
    "Nushell emits native semantic zones, exit status, CWD, and WezTerm user variables"
)
