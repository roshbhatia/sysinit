import os
import subprocess
import sys
import tempfile

zsh, fragment = sys.argv[1:]
environment = dict(os.environ)
for name in ("CLAUDECODE", "CODEX_THREAD_ID", "SYSINIT_AGENT_SHELL"):
    environment.pop(name, None)

cases = [
    ("plain", {}, False, False),
    ("codex", {"CODEX_THREAD_ID": "sysinit-check"}, True, False),
    ("claude", {"CLAUDECODE": "1"}, True, False),
    ("opt-in", {"SYSINIT_AGENT_SHELL": "1"}, True, False),
    ("opt-out", {"SYSINIT_AGENT_SHELL": "0"}, False, False),
    ("interactive", {"CODEX_THREAD_ID": "sysinit-check"}, False, True),
]

with tempfile.TemporaryDirectory() as directory:
    for name, variables, compatible, interactive in cases:

        def run(command):
            return subprocess.run(
                [
                    zsh,
                    "-fic" if interactive else "-fc",
                    'source "$1"; ' + command,
                    "sysinit-check",
                    fragment,
                ],
                cwd=directory,
                env=environment | variables,
                capture_output=True,
                text=True,
                timeout=10,
            )

        result = run('value="one two"; set -- $value; print -r -- "$#"')
        assert result.returncode == 0, (name, result.stderr)
        assert result.stdout.strip() == ("2" if compatible else "1"), name
        result = run('value="one two"; set -- "$value"; print -r -- "$#"')
        assert result.returncode == 0 and result.stdout.strip() == "1", name
        result = run("print -r -- =zsh")
        assert result.returncode == 0, (name, result.stderr)
        if compatible:
            assert result.stdout.strip() == "=zsh", name
        else:
            assert result.stdout.strip().startswith("/"), name
        result = run("print -r -- __sysinit_missing_*.pattern")
        if interactive:
            assert result.returncode != 0, name
        else:
            assert result.returncode == 0, (name, result.stderr)
            assert result.stdout.strip() == "__sysinit_missing_*.pattern", name

print("Zsh agent-shell behavior passed for all six contexts")
