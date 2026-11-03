import base64
import fcntl
import os
import pty
import re
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
            timeout=10,
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

    def test_floating_terminal_persists_until_parent_closes(self):
        client = self.attach()
        self.command("set-option", "-g", "default-command", "/bin/sh")
        self.command("set-option", "-g", "default-shell", "/bin/sh")
        os.write(client[1], b"\x02 ")
        menu = bytearray()

        def menu_shown():
            if select.select([client[1]], [], [], 0)[0]:
                menu.extend(os.read(client[1], 65536))
            return b"Floating terminal" in menu

        self.wait_for(menu_shown)
        os.write(client[1], b"f")
        floating = "_sysinit_float_0"
        pane = ""

        def visible():
            nonlocal pane
            while select.select([client[1]], [], [], 0)[0]:
                os.read(client[1], 65536)
            pane = self.command(
                "show-option", "-qv", "-t", "test", "@sysinit_float_pane"
            )
            return (
                bool(pane)
                and self.command(
                    "display-message",
                    "-p",
                    "-t",
                    pane,
                    "#{session_name}:#{pane_floating_flag}",
                )
                == "test:1"
            )

        self.wait_for(visible)
        pid = self.command("display-message", "-p", "-t", pane, "#{pane_pid}")
        os.write(client[1], b"\x02f")
        self.wait_for(
            lambda: (
                self.command("display-message", "-p", "-t", pane, "#{session_name}")
                == floating
            )
        )
        desktop = self.command("list-clients", "-F", "#{client_name}")
        self.command("switch-client", "-c", desktop, "-t", "=" + floating)
        self.wait_for(visible)
        self.assertEqual(
            self.command("display-message", "-p", "-t", pane, "#{pane_pid}"), pid
        )
        self.assertEqual(
            self.command("list-clients", "-F", "#{client_termname}\t#{session_name}"),
            "wezterm\ttest",
        )
        previous = pane
        self.command("kill-pane", "-t", pane)
        os.write(client[1], b"\x02f")
        self.wait_for(visible)
        self.assertNotEqual(pane, previous)
        os.write(client[1], b"\x02f")
        self.wait_for(
            lambda: (
                self.command("display-message", "-p", "-t", pane, "#{session_name}")
                == floating
            )
        )
        self.close_client(client)
        self.wait_for(lambda: not self.exists())

    def test_mouse_selects_panes_and_scrolls_native_history(self):
        client = self.attach()
        self.assertEqual(self.command("show-options", "-gv", "mouse"), "on")
        self.assertEqual(self.command("show-options", "-gv", "allow-passthrough"), "on")
        left = self.command("display-message", "-p", "#{pane_id}")
        right = self.command("split-window", "-h", "-P", "-F", "#{pane_id}", "/bin/sh")
        self.assertEqual(self.command("display-message", "-p", "#{pane_id}"), right)
        os.write(client[1], b"\x1b[<0;2;2M\x1b[<0;2;2m")
        self.wait_for(
            lambda: self.command("display-message", "-p", "#{pane_id}") == left
        )
        writer = "import os,time; os.write(1,('\\n'.join(map(str,range(1,201)))+'\\n').encode()); time.sleep(30)"
        self.command(
            "respawn-pane", "-k", "-t", left, shlex.join([sys.executable, "-c", writer])
        )
        self.wait_for(lambda: "200" in self.command("capture-pane", "-p", "-t", left))
        os.write(client[1], b"\x1b[<64;2;2M")
        self.wait_for(
            lambda: (
                self.command("display-message", "-p", "-t", left, "#{pane_in_mode}")
                == "1"
            )
        )
        self.wait_for(
            lambda: (
                int(
                    self.command(
                        "display-message", "-p", "-t", left, "#{scroll_position}"
                    )
                )
                > 0
            )
        )

    def test_native_scroll_moves_and_exits_copy_mode_at_bottom(self):
        client = self.attach()
        writer = "import os,time; os.write(1,('\\n'.join(map(str,range(1,201)))+'\\n').encode()); time.sleep(30)"
        self.command("respawn-pane", "-k", shlex.join([sys.executable, "-c", writer]))
        until = time.monotonic() + 0.5
        while time.monotonic() < until:
            if select.select([client[1]], [], [], 0.05)[0]:
                os.read(client[1], 65536)
        self.wait_for(lambda: "200" in self.command("capture-pane", "-p"))
        self.command("copy-mode")
        os.write(client[1], b"\x15")
        halfpage = int(self.command("display-message", "-p", "#{pane_height}")) // 2
        self.wait_for(
            lambda: (
                self.command("display-message", "-p", "#{scroll_position}")
                == str(halfpage)
            )
        )
        os.write(client[1], b"\x04")
        self.wait_for(
            lambda: self.command("display-message", "-p", "#{pane_in_mode}") == "0"
        )

    def test_yank_sends_selection_to_client_clipboard(self):
        client = self.attach()
        writer = "import os,time; os.write(1,b'\\x1b[2J\\x1b[HTMUX_YANK_CHECK\\n'); time.sleep(30)"
        self.command("respawn-pane", "-k", shlex.join([sys.executable, "-c", writer]))
        self.wait_for(
            lambda: self.command("capture-pane", "-p").startswith("TMUX_YANK_CHECK")
        )
        self.command("clear-history")
        self.command("copy-mode")
        self.command("send-keys", "-X", "history-top")
        self.command("send-keys", "-X", "select-line")
        until = time.monotonic() + 0.2
        while time.monotonic() < until:
            if select.select([client[1]], [], [], 0.05)[0]:
                os.read(client[1], 65536)
        os.write(client[1], b"y")
        output = b""
        until = time.monotonic() + 2
        while time.monotonic() < until:
            if select.select([client[1]], [], [], 0.05)[0]:
                output += os.read(client[1], 65536)
            values = re.findall(
                rb"\x1b\]52;[^;]*;([A-Za-z0-9+/=]+)(?:\x07|\x1b\\)", output
            )
            if any(
                base64.b64decode(value).strip() == b"TMUX_YANK_CHECK"
                for value in values
            ):
                os.write(client[1], b"\x02Y")
                self.wait_for(
                    lambda: (
                        self.command("show-buffer")
                        == self.command("display-message", "-p", "#{pane_current_path}")
                    )
                )
                return
        selected = self.command("show-buffer", check=False)
        caps = [line for line in self.command("info").splitlines() if "Ms:" in line]
        flag = self.command("show-options", "-s", "set-clipboard")
        candidates = [
            output[max(0, m.start() - 8) : m.start() + 100]
            for m in re.finditer(b"52", output)
        ]
        self.fail(
            f"clipboard buffer={selected!r}, capabilities={caps!r}, flag={flag}, candidates={candidates!r}"
        )

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
        self.assertEqual(self.command("show-options", "-v", "@sysinit_locked"), "1")
        application_keys = b"\x02s\x08\x0cpi keys\x1b[13;2u"
        self.command("source-file", CONFIG)
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

    def test_logging_capture_history_and_resurrect_save(self):
        client = self.attach()
        root = Path(self.directory.name)
        for option, directory in [
            ("@logging-path", "logs"),
            ("@screen-capture-path", "captures"),
            ("@save-complete-history-path", "history"),
            ("@resurrect-dir", "resurrect"),
        ]:
            self.command("set-option", "-g", option, str(root / directory))
        name = self.command("list-clients", "-F", "#{client_name}")

        def key(value):
            self.command("send-keys", "-K", "-c", name, "C-b")
            self.command("send-keys", "-K", "-c", name, value)

        key("P")
        self.wait_for(
            lambda: self.command("display-message", "-p", "#{pane_pipe}") == "1"
        )
        self.command("send-keys", "printf 'terminal-plugin-check\\n'", "Enter")
        self.wait_for(
            lambda: "terminal-plugin-check" in self.command("capture-pane", "-p")
        )
        key("P")
        self.wait_for(
            lambda: self.command("display-message", "-p", "#{pane_pipe}") == "0"
        )
        self.wait_for(
            lambda: any(
                "terminal-plugin-check" in path.read_text(errors="replace")
                for path in (root / "logs").glob("*")
            )
        )
        key("M-p")
        self.wait_for(lambda: any((root / "captures").glob("*")))
        key("M-P")
        self.wait_for(lambda: any((root / "history").glob("*")))
        key("C-s")
        self.wait_for(lambda: (root / "resurrect/last").exists())
        self.assertIn("test", (root / "resurrect/last").read_text())
        self.assertIn(
            "copy-pipe-and-cancel", self.command("list-keys", "-T", "copy-mode-vi", "o")
        )
        self.close_client(client)

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

    def test_manual_detach_does_not_preserve_another_clients_close(self):
        first = self.attach()
        second = self.attach()
        clients = self.command(
            "list-clients", "-F", "#{client_pid}\t#{client_name}"
        ).splitlines()
        name = next(
            line.split("\t")[1]
            for line in clients
            if line.split("\t")[0] == str(first[0])
        )
        self.command("send-keys", "-K", "-c", name, "C-b", "d")
        self.wait_for(
            lambda: (
                len(self.command("list-clients", "-F", "#{client_name}").splitlines())
                == 1
            )
        )
        self.close_client(first)
        self.close_client(second)
        self.wait_for(lambda: not self.exists())

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
