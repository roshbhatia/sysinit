from pathlib import Path
import subprocess
import tempfile

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    log = root / "service.log"
    policy = root / "logrotate.conf"
    policy.write_text(
        f"{log} {{\n size 1k\n rotate 3\n missingok\n notifempty\n copytruncate\n}}\n"
    )
    with log.open("ab", buffering=0) as writer:
        inode = log.stat().st_ino
        for _ in range(5):
            writer.write(b"fixture\n" * 1000)
            subprocess.run(
                ["logrotate", "--state", str(root / "state"), str(policy)], check=True
            )
            assert log.stat().st_ino == inode
            assert log.stat().st_size == 0
        writer.write(b"still logging\n")
        assert log.read_bytes() == b"still logging\n"
    assert len(list(root.glob("service.log.*"))) == 3
print("Log rotation preserves open writers and retains three archives")
