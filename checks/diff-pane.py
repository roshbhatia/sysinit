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
    panes = [{"pane_id": 7, "tab_id": 2}]
    calls = []
    sockets = []

    def wez(*args):
        calls.append(args)
        if args[0] == "list-clients":
            return '[{"client_id":1}]'
        if args[0] == "list":
            return json.dumps(panes)
        if args[0] == "split-pane":
            socket = Path(args[args.index("--listen") + 1])
            socket.touch()
            sockets.append(socket)
            panes.append({"pane_id": 8, "tab_id": 2})
            assert args[-1] == "DiffviewOpen"
            return "8"
        return ""

    def run(argv, **kwargs):
        if argv[0] == "git":
            return subprocess.CompletedProcess(
                argv, 1 if "HEAD" in argv else 0, str(root), ""
            )
        assert argv[:4] == ["nvim", "--headless", "--clean", "--server"]
        value = str(root) if argv[-1] == "getcwd()" else "2"
        return subprocess.CompletedProcess(argv, 0, value, "")

    try:
        with (
            patch.dict(os.environ, {"WEZTERM_PANE": "7", "XDG_STATE_HOME": temporary}),
            patch.object(module, "wez", side_effect=wez),
            patch.object(module, "run", side_effect=run),
        ):
            assert module.open_diff(temporary).startswith("Opened")
            assert module.open_diff(temporary).startswith("Reused")
            assert sum(call[0] == "split-pane" for call in calls) == 1
            panes[1]["tab_id"] = 3
            try:
                module.open_diff(temporary)
                raise AssertionError("Reused an editor in another tab")
            except RuntimeError as error:
                assert "outside this tab" in str(error)
    finally:
        for socket in sockets:
            socket.unlink(missing_ok=True)
print("Diff creation, headless RPC, reuse, unborn HEAD and tab isolation passed")
