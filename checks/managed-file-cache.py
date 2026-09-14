import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class CacheTest(unittest.TestCase):
    def test_reconcile(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / ".config/test.json"
            base = root / ".config/.test.json.nix-base"
            cache = Path(str(base) + ".cache")

            def run():
                return subprocess.run([sys.argv[1]], env=dict(os.environ, HOME=directory),
                                      capture_output=True).returncode

            self.assertEqual(run(), 0)
            self.assertTrue(cache.exists())
            other = root / ".config/other.json"
            other_stamp = other.stat().st_mtime_ns
            stamp = target.stat().st_mtime_ns
            self.assertEqual(run(), 0)
            self.assertEqual(target.stat().st_mtime_ns, stamp)
            target.write_text('{"owned": false, "custom": 7, "retired": true}')
            self.assertEqual(run(), 0)
            self.assertEqual(json.loads(target.read_text()), {"owned": True, "custom": 7})
            self.assertEqual(other.stat().st_mtime_ns, other_stamp)
            previous_cache = cache.read_bytes()
            target.write_text("invalid")
            self.assertNotEqual(run(), 0)
            self.assertEqual(target.read_text(), "invalid")
            self.assertEqual(cache.read_bytes(), previous_cache)
            target.unlink()
            self.assertEqual(run(), 0)
            target.unlink()
            foreign = root / "foreign"
            foreign.write_text('{"owned": false}')
            target.symlink_to(foreign)
            self.assertNotEqual(run(), 0)
            self.assertEqual(foreign.read_text(), '{"owned": false}')

    def test_cache_inputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            files = [root / name for name in ["target", "base", "declared", "schema"]]
            for path in files:
                path.write_text("initial")
            state = root / "cache"

            def run(operation, policy="v1"):
                return subprocess.run([sys.executable, sys.argv[2], operation, str(state),
                                       *map(str, files), policy], check=False).returncode

            self.assertEqual(run("record"), 0)
            self.assertEqual(run("check"), 0)
            self.assertEqual(run("check", "v2"), 1)
            for path in files:
                path.write_text("changed")
                self.assertEqual(run("check"), 1)
                path.write_text("initial")
            state.write_text("corrupt")
            self.assertEqual(run("check"), 1)


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
