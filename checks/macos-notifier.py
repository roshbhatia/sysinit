import json
import os
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

source = Path(sys.argv[1]).read_text()
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    output = root / "arguments.json"
    context = root / "focus.json"
    backend = root / "backend"
    backend.write_text(
        "#!"
        + sys.executable
        + "\n"
        + """import json,os,subprocess,sys
from pathlib import Path
args=sys.argv[1:]
Path(os.environ['NOTIFIER_ARGUMENTS']).write_text(json.dumps(args))
if '-execute' in args:
    command=args[args.index('-execute')+1]
    subprocess.run(['/bin/sh','-c',command[1:]],check=True)
if '-action' in args: print('Open session')
"""
    )
    backend.chmod(0o700)
    focus = root / "focus handler"
    focus.write_text(
        "#!"
        + sys.executable
        + "\n"
        + """import json,os,sys
from pathlib import Path
Path(os.environ['NOTIFIER_CONTEXT']).write_text(json.dumps({'args':sys.argv[1:],'socket':os.environ.get('WEZTERM_UNIX_SOCKET')}))
"""
    )
    focus.chmod(0o700)
    script = root / "notify.sh"
    script.write_text("NOTIFICATION_EXE=" + shlex.quote(str(backend)) + "\n" + source)
    env = os.environ | {
        "NOTIFIER_ARGUMENTS": str(output),
        "NOTIFIER_CONTEXT": str(context),
    }
    for key in ("AGENT_NOTIFY_FOCUS_EXE", "AGENT_NOTIFY_PANE", "AGENT_NOTIFY_SESSION"):
        env.pop(key, None)

    def run(args, extra=None):
        result = subprocess.run(
            ["bash", "-euo", "pipefail", str(script), *args],
            env=env | (extra or {}),
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip(), json.loads(output.read_text())

    result, args = run(
        [
            "--title",
            "[Codex]",
            "--message",
            "Tests passed",
            "--app-icon",
            "/icons/codex.png",
            "--timeout",
            "5",
        ]
    )
    assert result == "@ACTIONCLICKED"
    assert args[args.index("-title") + 1] == "\\[Codex]"
    assert args[args.index("-contentImage") + 1] == "\\/icons/codex.png"
    session = "project's task\nnext line"
    result, args = run(
        ["--title", "Codex", "--message", "Done", "--timeout", "5"],
        {
            "AGENT_NOTIFY_FOCUS_EXE": str(focus),
            "AGENT_NOTIFY_PANE": "42",
            "AGENT_NOTIFY_SESSION": session,
            "WEZTERM_UNIX_SOCKET": "/tmp/mux socket",
        },
    )
    assert "-action" not in args and "-execute" in args
    assert json.loads(context.read_text()) == {
        "args": ["42", session],
        "socket": "/tmp/mux socket",
    }
    _, args = run(["--remove", "agent:42"])
    assert args == ["-remove", "\\agent:42"]
    print(
        "Notification images, argument encoding, persistent click context and removal passed"
    )
