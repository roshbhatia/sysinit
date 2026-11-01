import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("diff", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary).resolve()
    panes = [{"pane_id": "%7", "session_name": "main", "window_id": "@2"}]
    calls = []
    sockets = []

    def run(argv, **kwargs):
        calls.append(argv)
        if argv[0] == "tmux":
            args = argv[1:]
            if args[0] == "display-message":
                return subprocess.CompletedProcess(argv, 0, "main\t@2\t123\n", "")
            if args[0] == "list-panes":
                return subprocess.CompletedProcess(
                    argv,
                    0,
                    "".join(
                        f"{p['pane_id']}\t{p['session_name']}\t{p['window_id']}\n"
                        for p in panes
                    ),
                    "",
                )
            return subprocess.CompletedProcess(argv, 0, "", "")
        if argv[0] == "ty":
            socket = Path(argv[argv.index("--listen") + 1])
            socket.touch()
            sockets.append(socket)
            panes.append({"pane_id": "%8", "session_name": "main", "window_id": "@2"})
            assert argv[-1] == "DiffviewOpen"
            return subprocess.CompletedProcess(argv, 0, '{"pane_id":"%8"}', "")
        if argv[0] == "git":
            return subprocess.CompletedProcess(
                argv, 1 if "HEAD" in argv else 0, str(root), ""
            )
        assert argv[:4] == ["nvim", "--headless", "--clean", "--server"]
        value = str(root) if argv[-1] == "getcwd()" else "2"
        return subprocess.CompletedProcess(argv, 0, value, "")

    try:
        with (
            patch.dict(os.environ, {"TMUX_PANE": "%7", "XDG_STATE_HOME": temporary}),
            patch.object(module, "run", side_effect=run),
        ):
            assert module.open_diff(temporary).startswith("Opened")
            assert module.open_diff(temporary).startswith("Reused")
            assert sum(call[0] == "ty" for call in calls) == 1
            panes[1]["window_id"] = "@3"
            try:
                module.open_diff(temporary)
                raise AssertionError("Reused an editor in another tab")
            except RuntimeError as error:
                assert "outside this tab" in str(error)
    finally:
        for socket in sockets:
            socket.unlink(missing_ok=True)
print("Diff creation, headless RPC, reuse, unborn HEAD and tab isolation passed")
