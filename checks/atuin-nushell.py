import codecs
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
import uuid

import pyte
import tomlkit


class Terminal:
    def __init__(self, environment, config):
        self.screen = pyte.Screen(140, 40)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder("utf-8")("replace")
        self.child, self.master = pty.fork()
        if self.child == 0:
            os.execvpe("nu", ["nu", "--config", config, "-i"], environment)
        fcntl.ioctl(self.master, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 140, 0, 0))

    def send(self, value):
        os.write(self.master, value.encode())

    def read(self, seconds=0.2):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            if not select.select([self.master], [], [], 0.05)[0]:
                continue
            data = os.read(self.master, 65536)
            # Reply from the emulated cursor, including any preceding output.
            # A fixed DSR reply can hide prompt-overwrite bugs in inline TUIs.
            parts = data.split(b"\x1b[6n")
            for index, part in enumerate(parts):
                self.stream.feed(self.decoder.decode(part))
                if index < len(parts) - 1:
                    self.send(
                        f"\x1b[{self.screen.cursor.y + 1};{self.screen.cursor.x + 1}R"
                    )
            if b"\x1b[0c" in data:
                self.send("\x1b[?1;2c")
            if b"\x1b[?u" in data:
                self.send("\x1b[?0u")
            if b"\x1b[>0q" in data:
                self.send("\x1bP>|xterm(1)\x1b\\")
            if b"\x1b]11;?" in data:
                self.send("\x1b]11;rgb:0000/0000/0000\x1b\\")
            for capability in re.findall(rb"\x1bP\+q([^\x1b]+)\x1b\\", data):
                os.write(self.master, b"\x1bP0+r" + capability + b"\x1b\\")

    def wait(self, predicate):
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            self.read()
            if predicate():
                return
        raise AssertionError(
            "Terminal condition not reached:\n" + "\n".join(self.screen.display)
        )

    def close(self):
        os.close(self.master)
        for _ in range(20):
            if os.waitpid(self.child, os.WNOHANG)[0]:
                return
            time.sleep(0.05)
        os.kill(self.child, signal.SIGKILL)
        os.waitpid(self.child, 0)


with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    settings = json.loads(Path(sys.argv[1]).read_text())
    settings["data_dir"] = str(root / "data")
    settings["daemon"]["enabled"] = False
    settings["threads"]["capture"] = False
    (root / "config.toml").write_text(tomlkit.dumps(settings))
    environment = dict(
        os.environ,
        HOME=str(root),
        ATUIN_CONFIG_DIR=str(root),
        ATUIN_SESSION=uuid.uuid4().hex,
        ATUIN_TEST_BUFFER=str(root / "buffer"),
        TERM="xterm-256color",
    )
    token = "atuin-nu-" + uuid.uuid4().hex
    commands = [f"touch '{root}/{token} older'", f"touch '{root}/{token} newer'"]
    for command in commands:
        identifier = subprocess.check_output(
            ["atuin", "history", "start", "--author-kind", "user", "--", command],
            env=environment,
            text=True,
        ).strip()
        subprocess.run(
            ["atuin", "history", "end", "--exit", "0", "--", identifier],
            env=environment,
            check=True,
        )
        time.sleep(0.05)
    terminal = Terminal(environment, sys.argv[2])
    try:
        terminal.wait(
            lambda: any("original-prompt" in row for row in terminal.screen.display)
        )
        terminal.send(token)
        terminal.read()
        terminal.send("\x12")
        terminal.wait(lambda: any("GLOBAL" in row for row in terminal.screen.display))
        rows = terminal.screen.display
        prompt_row = next(
            index
            for index, row in enumerate(rows)
            if "original-prompt" in row and token in row
        )
        query_row = next(
            index for index, row in enumerate(rows) if "GLOBAL" in row and token in row
        )
        assert prompt_row < query_row, "Original prompt was overwritten by the picker"
        for keys, selected in [("\t", "older"), ("\x1b[Z", "newer"), ("\t", "older")]:
            terminal.send(keys)
            terminal.read()
            assert any("GLOBAL" in row for row in terminal.screen.display), (
                "Tab closed the picker"
            )
            assert any(
                re.match(r"\s*>", row) and selected in row
                for row in terminal.screen.display
            ), f"{keys!r} did not select the {selected} command"
        terminal.send("\r")
        terminal.wait(
            lambda: not any("GLOBAL" in row for row in terminal.screen.display)
        )
        terminal.send("\x18")
        buffer = root / "buffer"
        terminal.wait(buffer.exists)
        assert buffer.read_text() == commands[0], (
            "Tab/Shift-Tab did not select and insert the older command"
        )
        assert not (root / f"{token} older").exists(), (
            "Selecting history executed the command"
        )
        terminal.send("\x03")
        terminal.read()
        terminal.send("original-buffer")
        terminal.send("\x12")
        terminal.wait(lambda: any("GLOBAL" in row for row in terminal.screen.display))
        terminal.send("changed-query")
        terminal.read()
        terminal.send("\x03")
        terminal.wait(
            lambda: not any("GLOBAL" in row for row in terminal.screen.display)
        )
        buffer.unlink()
        terminal.send("\x18")
        terminal.wait(buffer.exists)
        assert buffer.read_text() == "original-buffer", (
            "Cancel did not preserve the original editable buffer"
        )
        print(
            "Native Nushell preserves the prompt, navigates with Tab/Shift-Tab, inserts selection, and restores canceled input"
        )
    finally:
        terminal.close()
