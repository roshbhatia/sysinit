import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def run(argv, **kwargs):
    return subprocess.run(argv, text=True, capture_output=True, timeout=8, **kwargs)


def wez(*args):
    result = run(["wezterm", "cli", "--no-auto-start", *args])
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "WezTerm command failed")
    return result.stdout.strip()


def open_diff(cwd):
    parent = os.environ.get("WEZTERM_PANE", "")
    if not parent.isdecimal():
        raise RuntimeError("No WezTerm pane. Run agent-diff from a WezTerm session.")
    root = run(["git", "-C", cwd, "rev-parse", "--show-toplevel"])
    if root.returncode:
        raise RuntimeError("The current directory is not a Git worktree.")
    root = str(Path(root.stdout.strip()).resolve())
    if not json.loads(wez("list-clients", "--format", "json")):
        raise RuntimeError("No attached WezTerm client.")
    panes = json.loads(wez("list", "--format", "json"))
    owner = next((pane for pane in panes if str(pane["pane_id"]) == parent), None)
    if owner is None:
        raise RuntimeError("The invoking pane is no longer live.")
    state = (
        Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
        / "agent-diff"
    )
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    key = hashlib.sha256(
        f"{root}|{parent}|{os.environ.get('WEZTERM_UNIX_SOCKET', '')}".encode()
    ).hexdigest()[:20]
    record = state / f"{key}.json"
    # Keep the socket below the Unix-domain path limit, even with a long XDG path.
    socket_dir = Path("/tmp") / f"sysinit-diff-{os.getuid()}"
    socket_dir.mkdir(mode=0o700, exist_ok=True)
    if (
        socket_dir.is_symlink()
        or socket_dir.stat().st_uid != os.getuid()
        or socket_dir.stat().st_mode & 0o077
    ):
        raise RuntimeError("The diff socket directory is not private.")
    socket = socket_dir / f"{key}.sock"
    with (state / f"{key}.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            saved = json.loads(record.read_text())
        except (OSError, ValueError):
            saved = {}
        live = next(
            (
                pane
                for pane in json.loads(wez("list", "--format", "json"))
                if pane["pane_id"] == saved.get("pane")
                and pane["tab_id"] == owner["tab_id"]
            ),
            None,
        )
        if live and socket.exists():
            probe = run(
                [
                    "nvim",
                    "--headless",
                    "--clean",
                    "--server",
                    str(socket),
                    "--remote-expr",
                    "getcwd()",
                ]
            )
            if (
                probe.returncode == 0
                and str(Path(probe.stdout.strip()).resolve()) == root
            ):
                refresh = run(
                    [
                        "nvim",
                        "--headless",
                        "--clean",
                        "--server",
                        str(socket),
                        "--remote-expr",
                        "execute('checktime | Review refresh')",
                    ]
                )
                if refresh.returncode == 0:
                    wez("activate-pane", "--pane-id", str(live["pane_id"]))
                    return "Reused the Neovim diff pane."
                raise RuntimeError(
                    refresh.stderr.strip()
                    or "The diff editor could not refresh yet. Run /diff again."
                )
        # A live socket from an unrelated editor must never be replaced.
        if socket.exists():
            probe = run(
                [
                    "nvim",
                    "--headless",
                    "--clean",
                    "--server",
                    str(socket),
                    "--remote-expr",
                    "getpid()",
                ]
            )
            if probe.returncode == 0:
                raise RuntimeError(
                    "A live diff editor exists outside this tab; close it before opening another."
                )
            socket.unlink()
        has_head = (
            run(["git", "-C", root, "rev-parse", "--verify", "HEAD"]).returncode == 0
        )
        pane = wez(
            "split-pane",
            "--pane-id",
            parent,
            "--right",
            "--percent",
            "45",
            "--cwd",
            root,
            "--",
            "nvim",
            "--listen",
            str(socket),
            "--cmd",
            f"let g:harness_pane = '{parent}'",
            "-c",
            "DiffviewOpen HEAD" if has_head else "DiffviewOpen",
        )
        record.write_text(json.dumps({"pane": int(pane), "root": root}))
        deadline = time.monotonic() + 4
        while time.monotonic() < deadline:
            if socket.exists():
                ready = run(
                    [
                        "nvim",
                        "--headless",
                        "--clean",
                        "--server",
                        str(socket),
                        "--remote-expr",
                        "exists(':Review')",
                    ]
                )
                if ready.returncode == 0 and ready.stdout.strip() == "2":
                    return "Opened the Neovim diff pane."
            time.sleep(0.05)
        raise RuntimeError(
            "The split opened, but Neovim did not expose its socket yet. Run /diff again."
        )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cwd", default=os.getcwd())
    args = parser.parse_args()
    try:
        print(open_diff(args.cwd))
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"agent-diff: {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
