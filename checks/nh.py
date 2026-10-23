import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

nh = str(Path(sys.argv[1]).resolve())
with tempfile.TemporaryDirectory(prefix="nh-output-path-") as temporary:
    root = Path(temporary).resolve()
    (root / "flake.nix").write_text("{}")
    binaries = root / "bin"
    binaries.mkdir()
    target = root / "built-system"
    (target / "sw/bin").mkdir(parents=True)
    log = root / "commands.jsonl"
    shim = (
        f"#!{sys.executable}\n"
        + """
import json
import os
from pathlib import Path
import sys

args = sys.argv[1:]
if Path(sys.argv[0]).name == "elevate":
    os.execvp(args[0], args)
with open(os.environ["NH_TEST_LOG"], "a") as log:
    log.write(json.dumps([Path(sys.argv[0]).name, *args]) + "\\n")
if Path(sys.argv[0]).name == "darwin-rebuild":
    assert args == ["activate"], args
    assert os.environ["HOME"] == "/var/root", os.environ["HOME"]
elif "--version" in args:
    print("nix (Nix) 2.34.0")
elif "experimental-features" in args:
    print("nix-command flakes")
elif "build" in args:
    if "--profile" in args:
        assert args[args.index("--profile") + 1] == "/nix/var/nix/profiles/system", args
        assert args[-1] == os.environ["NH_TEST_TARGET"], args
        assert os.environ["HOME"] == "/var/root", os.environ["HOME"]
    else:
        if os.environ.get("NH_TEST_FAIL"):
            sys.exit(23)
        output = Path(args[args.index("--out-link") + 1])
        output.symlink_to(os.environ["NH_TEST_TARGET"])
else:
    raise AssertionError(args)
"""
    )
    for executable in [
        binaries / "nix",
        binaries / "elevate",
        target / "sw/bin/darwin-rebuild",
    ]:
        executable.write_text(shim)
        executable.chmod(0o755)
    environment = os.environ | {
        "PATH": f"{binaries}:{os.environ['PATH']}",
        "NH_TEST_LOG": str(log),
        "NH_TEST_TARGET": str(target),
    }
    for name, output, fail in [
        ("relative", "result-system", False),
        ("absolute", str(root / "absolute-result"), False),
        ("temporary", None, False),
        ("failed-build", "failed-result", True),
    ]:
        log.write_text("")
        arguments = [
            nh,
            "darwin",
            "switch",
            ".#fixture",
            "--hostname",
            "fixture",
            "--no-nom",
            "--diff",
            "never",
            "--elevation-strategy",
            str(binaries / "elevate"),
        ]
        if output is not None:
            arguments.extend(["--out-link", output])
        result = subprocess.run(
            arguments,
            cwd=root,
            env=environment | ({"NH_TEST_FAIL": "1"} if fail else {}),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        commands = [json.loads(line) for line in log.read_text().splitlines()]
        profiles = [
            command
            for command in commands
            if command[0] == "nix" and "--profile" in command
        ]
        activations = [
            command for command in commands if command[0] == "darwin-rebuild"
        ]
        if fail:
            assert result.returncode != 0, (name, result.stdout)
            assert not profiles and not activations, (name, commands)
        else:
            assert result.returncode == 0, (name, result.stdout, commands)
            assert len(profiles) == 1 and len(activations) == 1, (name, commands)
        print(f"{name}: passed")
