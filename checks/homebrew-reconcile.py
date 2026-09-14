import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class ReconcileTest(unittest.TestCase):
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
                script.write_text("#!/usr/bin/env bash\nset -euo pipefail\n" + body + "\n")
                script.chmod(0o755)
            env = dict(os.environ, INVENTORY=str(inventory), COUNT=str(count),
                       MISSING=str(missing), FAILURE=str(failure))

            def run():
                return subprocess.run(["bash", sys.argv[1], str(state),
                                       *[str(root / name) for name in commands]],
                                      env=env, check=False).returncode

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
