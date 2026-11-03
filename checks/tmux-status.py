import json
import subprocess
import sys
import tempfile
from pathlib import Path

lua, script, source, deck, agents = sys.argv[1:]
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    record = root / "%1.json"
    base = {"pane": "%1", "status": "done", "agent": "codex", "since": 1}
    record.write_text(json.dumps(base))

    def scan(executable, argv, text):
        snapshot = [
            {
                "pane": "%1",
                "session": "review",
                "cwd": "/repo",
                "title": "",
                "text": text,
                "process": {"pid": 123, "executable": executable, "argv": argv},
            }
        ]
        output = subprocess.check_output(
            [lua, script, source, deck, agents, str(root), str(root / "history.json")],
            input=json.dumps(snapshot),
            text=True,
        )
        return json.loads(output)

    assert scan("/bin/nu", ["nu"], "old agent output") == [], (
        "shell retained stale agent state"
    )
    working = scan("/bin/codex", ["codex"], "• Working (1s • esc to interrupt)")
    assert working[0]["status"] == "working", working
    base["status"] = "waiting"
    base["since"] = 2
    record.write_text(json.dumps(base))
    waiting = scan("/bin/codex", ["codex"], "• Working (1s • esc to interrupt)")
    assert waiting[0]["status"] == "waiting", waiting
    replacement = scan(
        "/bin/node", ["node", "/opt/@anthropic-ai/claude-code/cli.js"], "❯"
    )
    assert (
        replacement[0]["agent"] == "claude" and replacement[0]["status"] != "waiting"
    ), replacement
    print(
        "Shared native/tmux classification: stale state, active turn, approval precedence and process replacement pass"
    )
