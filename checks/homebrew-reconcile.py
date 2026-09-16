import os
import shutil
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class ReconcileTest(unittest.TestCase):
    def test_checks_overlap_and_finish_before_reconcile(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            programs = {
                "snapshot": "Path('snapshot-started').touch()\n"
                "wait_for('check-started')\n"
                "print('inventory')\n",
                "check": "if Path('fixed').exists(): sys.exit(0)\n"
                "Path('check-started').touch()\n"
                "wait_for('snapshot-started')\n"
                "time.sleep(0.1)\nPath('check-finished').touch()\nsys.exit(1)\n",
                "reconcile": "assert Path('check-finished').exists()\nPath('fixed').touch()\n",
            }
            for name, program in programs.items():
                script = root / name
                script.write_text(
                    "#!"
                    + sys.executable
                    + "\nfrom pathlib import Path\nimport sys,time\n"
                    "def wait_for(name):\n"
                    " deadline = time.monotonic() + 3\n"
                    " while not Path(name).exists():\n"
                    "  assert time.monotonic() < deadline, name\n"
                    "  time.sleep(0.01)\n" + program
                )
                script.chmod(0o755)
            result = subprocess.run(
                [
                    "bash",
                    sys.argv[1],
                    str(root / "state"),
                    *[str(root / name) for name in programs],
                ],
                cwd=root,
                timeout=10,
                check=False,
            )
            self.assertEqual(result.returncode, 0)
            self.assertEqual((root / "state").read_text(), "inventory\n")

    def test_drift_and_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            state = root / "state"
            inventory = root / "inventory"
            inventory.write_text("v1\n")
            count = root / "count"
            missing = root / "missing"
            failure = root / "failure"
            commands = {
                "snapshot": 'cat "$INVENTORY"',
                "check": 'test ! -f "$MISSING"',
                "reconcile": 'test ! -f "$FAILURE"; echo run >> "$COUNT"; rm -f "$MISSING"',
            }
            for name, body in commands.items():
                script = root / name
                script.write_text(
                    "#!" + shutil.which("bash") + "\nset -euo pipefail\n" + body + "\n"
                )
                script.chmod(0o755)
            env = dict(
                os.environ,
                INVENTORY=str(inventory),
                COUNT=str(count),
                MISSING=str(missing),
                FAILURE=str(failure),
            )

            def run():
                return subprocess.run(
                    [
                        "bash",
                        sys.argv[1],
                        str(state),
                        *[str(root / name) for name in commands],
                    ],
                    env=env,
                    check=False,
                ).returncode

            self.assertEqual(run(), 0)
            self.assertEqual(run(), 0)
            self.assertEqual(count.read_text().splitlines(), ["run"])
            missing.touch()
            self.assertEqual(run(), 0)
            self.assertFalse(missing.exists())
            inventory.write_text("v2\n")
            self.assertEqual(run(), 0)
            self.assertEqual(len(count.read_text().splitlines()), 3)
            previous = state.read_bytes()
            inventory.write_text("v3\n")
            failure.touch()
            self.assertNotEqual(run(), 0)
            self.assertEqual(state.read_bytes(), previous)
            failure.unlink()
            self.assertEqual(run(), 0)
            self.assertEqual(state.stat().st_mode & 0o777, 0o600)


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
