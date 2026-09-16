import os
from pathlib import Path
import subprocess
import sys
import tempfile

source = Path(sys.argv[1]).read_text()
with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    for name in ("first", "second"):
        folder = root / name
        folder.mkdir()
        os.utime(folder, (1, 1))
    profile = root / "profile"
    profile.symlink_to(root / "first", target_is_directory=True)
    script = root / "test.zsh"
    script.write_text(
        "autoload() { :; }\n"
        "compinit() { print -r -- $1; touch $ZSH_CACHE_DIR/zcompdump/.zcompdump; }\n"
        + source.replace("/etc/profiles/per-user/$USERNAME", str(profile))
    )
    env = dict(os.environ, HOME=str(root), ZSH_CACHE_DIR=str(root / "cache"))

    def run():
        return subprocess.check_output(
            ["zsh", "-f", str(script)], env=env, text=True
        ).strip()

    assert run() == "-d"
    assert run() == "-C"
    profile.unlink()
    profile.symlink_to(root / "second", target_is_directory=True)
    assert run() == "-d"
    assert run() == "-C"
    print("completion cache follows profile generations, including fixed timestamps")
