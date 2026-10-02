import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

module, nu = sys.argv[1:]
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    mock = root / "op"
    mock.write_text(
        "#!"
        + sys.executable
        + "\n"
        + """import json, os, sys
from pathlib import Path
args = sys.argv[1:]
with open(os.environ['OP_TEST_LOG'], 'a') as log:
    log.write(json.dumps(args) + '\\n')
if args[:2] == ['item', 'list']:
    print(json.dumps([{'id':'item123','title':'Example Login','vault':{'id':'vault123','name':'Test'},'category':'LOGIN'}]))
elif args[0] == 'read':
    if os.environ.get('OP_TEST_FAIL'):
        print('sensitive diagnostic', file=sys.stderr)
        sys.exit(1)
    sys.stdout.write('  synthetic-password\\n')
elif args[0] == 'run':
    sys.exit(int(os.environ.get('OP_TEST_EXIT', '0')))
else:
    sys.exit(2)
"""
    )
    mock.chmod(0o700)
    clipboard = root / "pbcopy"
    clipboard.write_text(
        "#!"
        + sys.executable
        + "\n"
        + """import os, sys
from pathlib import Path
Path(os.environ['OP_TEST_CLIPBOARD']).write_bytes(sys.stdin.buffer.read())
"""
    )
    clipboard.chmod(0o700)
    env = os.environ | {
        "PATH": directory + os.pathsep + os.environ["PATH"],
        "OP_TEST_LOG": str(root / "calls.jsonl"),
        "OP_TEST_CLIPBOARD": str(root / "clipboard"),
    }

    def run(command, extra=None):
        return subprocess.run(
            [nu, "--no-config-file", "-c", f"use {module} *; {command}"],
            env=env | (extra or {}),
            capture_output=True,
            text=True,
            check=False,
        )

    found = run("op-find EXAMPLE --account test --vault Test | to json")
    assert found.returncode == 0, found.stderr
    assert json.loads(found.stdout)[0]["id"] == "item123"
    ref = run("op-ref Example --field username")
    assert ref.stdout.strip() == "op://vault123/item123/username", ref.stderr
    copied = run("op-copy Example --account test")
    assert copied.returncode == 0, copied.stderr
    assert "synthetic-password" not in copied.stdout + copied.stderr
    assert (root / "clipboard").read_bytes() == b"  synthetic-password\n"
    otp = run("op-copy Example --otp")
    assert otp.returncode == 0, otp.stderr
    calls = [
        json.loads(line) for line in (root / "calls.jsonl").read_text().splitlines()
    ]
    assert [
        "item",
        "list",
        "--format",
        "json",
        "--account",
        "test",
        "--vault",
        "Test",
    ] in calls
    assert [
        "read",
        "op://vault123/item123/password",
        "--no-newline",
        "--account",
        "test",
    ] in calls
    assert [
        "read",
        "op://vault123/item123/one-time password?attribute=otp",
        "--no-newline",
    ] in calls
    previous = (root / "clipboard").read_bytes()
    failed = run("op-copy Example", {"OP_TEST_FAIL": "1"})
    assert failed.returncode != 0
    assert "sensitive diagnostic" not in failed.stdout + failed.stderr
    assert (root / "clipboard").read_bytes() == previous
    missing = run("op-copy absent")
    assert missing.returncode != 0
    assert (root / "clipboard").read_bytes() == previous
    child = run(
        'op-with refs.env echo "two words"; exit $env.LAST_EXIT_CODE',
        {"OP_TEST_EXIT": "7"},
    )
    assert child.returncode == 7, child.stderr
    calls = [
        json.loads(line) for line in (root / "calls.jsonl").read_text().splitlines()
    ]
    assert ["run", "--env-file", "refs.env", "--", "echo", "two words"] in calls
    print(
        "1Password helpers: metadata, references, clipboard, OTP, errors, and child exit status passed"
    )
