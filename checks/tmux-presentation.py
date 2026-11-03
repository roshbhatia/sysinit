import json
import subprocess
import sys
import tempfile
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text())
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    pane = {
        "id": "%1",
        "session_id": "$1",
        "session": "default",
        "window": "@1",
        "index": 0,
        "window_name": "codex",
        "window_active": True,
        "pane_active": True,
        "cwd": "/github/roshbhatia/sysinit",
        "title": "codex",
        "process_name": "codex",
        "zoomed": False,
        "floating": False,
        "parent": "",
        "parent_name": "",
        "activity": 1,
    }
    payload = {
        "panes": [pane],
        "panes_dir": str(root),
        "history_file": str(root / "history.json"),
        "snapshot": [
            {
                "pane": "%1",
                "session": "default",
                "cwd": pane["cwd"],
                "title": "",
                "process": {"pid": 123, "executable": "/bin/codex", "argv": ["codex"]},
                "text": "• Working (1s • esc to interrupt)",
            }
        ],
    }
    data = json.loads(
        subprocess.check_output(
            config["presentation"], input=json.dumps(payload), text=True
        )
    )
    tab = data["windows"][0]
    session = data["sessions"][0]
    assert "[1]" in tab["text"] and "roshbhatia/sysinit" in tab["text"], tab
    assert "[1] default" in session["text"], session
    assert tab["tail_text"].strip() and session["tail_text"].strip(), (tab, session)
    assert tab["tail_text"].strip() == session["tail_text"].strip(), (tab, session)
    assert "[1]" in tab["host_text"] and "local" in tab["host_text"], tab
    assert data["mode"]["bg"] == data["host"]["bg"], data
    assert data["icons"]["locked"] != data["icons"]["unlocked"], data["icons"]
    print(
        "Native tmux presentation: indexed tabs/sessions/hosts, mode colors, lock glyphs and both working indicators pass"
    )
