"""Exercise mail selection and bulk actions through NeoMutt's real terminal UI."""

import fcntl
import os
from pathlib import Path
import pty
import select
import subprocess
import sys
import tempfile
import termios
import time


def terminal_session():
    os.setsid()
    fcntl.ioctl(0, termios.TIOCSCTTY, 0)


def mailbox(path):
    for name in ("cur", "new", "tmp"):
        (path / name).mkdir(parents=True)
    return path


def messages(path):
    return {
        item.name.split(":2,")[0]: item.name.partition(":2,")[2]
        for directory in ("cur", "new")
        for item in (path / directory).iterdir()
    }


def exercise(binary, keys, action, initial_read=False, source_name="INBOX"):
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        source = mailbox(root / source_name)
        archive = mailbox(root / "[Gmail]" / "All Mail")
        trash = mailbox(root / "[Gmail]" / "Trash")
        unsubscribe = mailbox(root / "Unsubscribe")
        for number, subject in (("1", "keep one"), ("2", "keep two"), ("3", "exclude")):
            target = source / ("cur" if initial_read else "new")
            target /= number + (":2,S" if initial_read else "")
            target.write_text(
                f"From: sender@example.com\nTo: test@example.com\nSubject: {subject}\n"
                f"Message-ID: <{number}@example.com>\n"
                "Date: Wed, 7 Oct 2026 12:00:00 +0000\n\nTest message.\n"
            )
        rc = root / "rc"
        rc.write_text(
            f'set mbox_type=Maildir\nset folder="{root}"\n'
            f'set trash="{trash}"\n'
            "set mark_old=no\nset move=no\nset quit=yes\nset delete=yes\n"
            "set confirmappend=no\nbind index,pager g noop\n"
            f'source "{keys}"\n'
        )
        master, slave = pty.openpty()
        termios.tcsetwinsize(slave, (40, 160))
        proc = subprocess.Popen(
            [
                binary,
                "-d",
                "5",
                "-l",
                str(root / "debug"),
                "-n",
                "-F",
                str(rc),
                "-f",
                str(source),
            ],
            stdin=slave,
            stdout=slave,
            stderr=slave,
            preexec_fn=terminal_session,
            env=dict(os.environ, TERM="xterm-256color"),
        )
        os.close(slave)
        output = b""
        sent = False
        deadline = time.monotonic() + 15
        try:
            while proc.poll() is None and time.monotonic() < deadline:
                if select.select([master], [], [], 0.1)[0]:
                    try:
                        output += os.read(master, 65536)
                        if not sent and b"exclude" in output:
                            os.write(master, b"l~s keep\rV" + action.encode() + b"$q")
                            sent = True
                    except OSError:
                        break
            try:
                returncode = proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
                logs = "\n".join(p.read_text() for p in root.glob("debug*"))
                raise AssertionError(output.decode(errors="replace") + logs)
            assert returncode == 0, output.decode(errors="replace")
        finally:
            if proc.poll() is None:
                proc.kill()
                proc.wait()
            os.close(master)
        return (
            messages(source),
            messages(archive),
            messages(trash),
            messages(unsubscribe),
        )


def main():
    binary, keys = sys.argv[1:]
    keys = str(Path(keys).resolve())
    source, _, trash, _ = exercise(binary, keys, ",r")
    assert source == {"1": "S", "2": "S", "3": ""}, source
    assert not trash
    source, _, _, _ = exercise(binary, keys, ",u", initial_read=True)
    assert source == {"1": "", "2": "", "3": "S"}, source
    source, archive, trash, _ = exercise(binary, keys, ",a")
    assert len(source) == 1 and "3" in source, source
    assert len(archive) == 2, archive
    assert not trash, trash
    source, archive, trash, _ = exercise(binary, keys, ",a", source_name="Other")
    assert len(source) == 3 and not archive and not trash
    source, _, trash, unsubscribe = exercise(binary, keys, ",U")
    assert len(source) == 3 and len(unsubscribe) == 2 and not trash
    print(
        "NeoMutt bulk read, unread, archive, label copy, and selection boundaries passed"
    )


if __name__ == "__main__":
    main()
