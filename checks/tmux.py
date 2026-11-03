import fcntl
import os
import pty
import select
import shlex
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest
from pathlib import Path

TMUX, CONFIG = sys.argv[1:3]
del sys.argv[1:3]


class LifecycleTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="sysinit-tmux-")
        self.socket = str(Path(self.directory.name) / "socket")
        self.clients = []

    def tearDown(self):
        self.command("kill-server", check=False)
        for client in self.clients[:]:
            self.close_client(client)
        self.directory.cleanup()

    def command(self, *args, check=True):
        return subprocess.run(
            [TMUX, "-S", self.socket, *args],
            capture_output=True,
            text=True,
            check=check,
        ).stdout.strip()

    def exists(self):
        return bool(self.command("list-sessions", "-F", "#{session_name}", check=False))

    def wait_for(self, predicate):
        for _ in range(100):
            if predicate():
                return
            time.sleep(0.05)
        self.fail("tmux did not reach the expected state within 5 seconds")

    def attach(self, terminal="wezterm"):
        pid, fd = pty.fork()
        if pid == 0:
            for _, inherited_fd in self.clients:
                os.close(inherited_fd)
            env = os.environ | {"TERM": terminal}
            env.pop("TMUX", None)
            env.pop("TMUX_PANE", None)
            os.execve(
                TMUX,
                [
                    TMUX,
                    "-S",
                    self.socket,
                    "-f",
                    CONFIG,
                    "new-session",
                    "-A",
                    "-s",
                    "test",
                    "/bin/sh",
                ],
                env,
            )
        client = (pid, fd)
        self.clients.append(client)
        fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))
        self.wait_for(lambda: bool(select.select([fd], [], [], 0)[0]))
        os.read(fd, 65536)
        self.wait_for(self.exists)
        self.command("source-file", CONFIG)
        self.wait_for(
            lambda: (
                len(
                    [
                        line
                        for line in self.command("show-options", "-s").splitlines()
                        if line.startswith("@sysinit_client_")
                    ]
                )
                == len(self.clients)
            )
        )
        until = time.monotonic() + 0.3
        while time.monotonic() < until:
            if select.select([fd], [], [], 0.05)[0]:
                os.read(fd, 65536)
        return client

    def close_client(self, client):
        pid, fd = client
        os.close(fd)
        self.clients.remove(client)
        for _ in range(50):
            if os.waitpid(pid, os.WNOHANG)[0]:
                return
            time.sleep(0.05)
        os.kill(pid, signal.SIGTERM)
        os.waitpid(pid, 0)

    def test_last_local_close_ends_session(self):
        client = self.attach()
        self.close_client(client)
        self.wait_for(lambda: not self.exists())

    def test_locked_mode_forwards_application_keys_and_prefix(self):
        client = self.attach()
        output = Path(self.directory.name) / "keys"
        reader = (
            "import os,tty; tty.setraw(0); "
            f"f=open({str(output)!r},'ab',buffering=0); "
            "exec('while True: f.write(os.read(0,4096))')"
        )
        self.command("respawn-pane", "-k", shlex.join([sys.executable, "-c", reader]))
        self.wait_for(output.exists)
        os.write(client[1], b"\x07")
        self.wait_for(
            lambda: (
                self.command("list-clients", "-F", "#{client_key_table}")
                == "sysinit-locked"
            )
        )
        application_keys = b"\x02s\x08\x0cpi keys\x1b[13;2u"
        os.write(client[1], application_keys)
        try:
            self.wait_for(lambda: output.read_bytes() == application_keys)
        except AssertionError:
            self.fail(
                f"application received {output.read_bytes()!r}; expected {application_keys!r}"
            )
        self.assertEqual(
            self.command("list-clients", "-F", "#{client_key_table}"),
            "sysinit-locked",
        )
        os.write(client[1], b"\x07")
        self.wait_for(
            lambda: self.command("list-clients", "-F", "#{client_key_table}") == "root"
        )

    def test_explicit_detach_preserves_session(self):
        client = self.attach()
        self.command(
            "send-keys",
            "-K",
            "-c",
            self.command("list-clients", "-F", "#{client_name}"),
            "C-b",
            "d",
        )
        self.wait_for(lambda: not self.command("list-clients", "-F", "#{client_name}"))
        self.close_client(client)
        self.assertTrue(self.exists())

    def test_remote_client_keeps_session_alive(self):
        local = self.attach()
        remote = self.attach("xterm-256color")
        self.wait_for(
            lambda: (
                len(self.command("list-clients", "-F", "#{client_name}").splitlines())
                == 2
            )
        )
        self.close_client(local)
        self.assertTrue(self.exists())
        self.close_client(remote)
        self.assertTrue(self.exists())


unittest.main()
