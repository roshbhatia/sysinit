from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class AppCopyStateTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / "source"
        self.target = self.root / "target"
        self.source.mkdir()
        self.target.mkdir()
        self.original = self.root / "original.app"
        self.original.mkdir()
        (self.source / "Test App.app").symlink_to(self.original)
        self.app = self.target / "Test App.app"
        self.app.mkdir()
        (self.app / "payload").write_text("signed")
        self.state = self.root / "state.json"
        self.codesign = self.root / "codesign"
        self.codesign.write_text(
            "#!"
            + sys.executable
            + "\n"
            + "import pathlib,sys\n"
            + "app=pathlib.Path(sys.argv[-1])\n"
            + "if '--verify' in sys.argv: sys.exit(0 if (app/'payload').read_text() == 'signed' else 1)\n"
            + "print('designated => certificate leaf = test')\n"
        )
        self.codesign.chmod(0o755)

    def run_state(self, operation):
        return subprocess.run(
            [
                sys.executable,
                sys.argv[1],
                operation,
                str(self.source),
                str(self.target),
                str(self.state),
                "--codesign",
                str(self.codesign),
            ],
            check=False,
        ).returncode

    def record(self):
        self.assertEqual(self.run_state("record"), 0)
        self.assertEqual(self.state.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.run_state("check"), 0)

    def test_unchanged(self):
        self.assertEqual(self.run_state("check"), 1)
        self.record()

    def test_tampered_bundle(self):
        self.record()
        (self.app / "payload").write_text("tampered")
        self.assertEqual(self.run_state("check"), 1)
        previous = self.state.read_bytes()
        self.assertEqual(self.run_state("record"), 1)
        self.assertEqual(self.state.read_bytes(), previous)

    def test_source_change(self):
        self.record()
        updated = self.root / "updated.app"
        updated.mkdir()
        (self.source / "Test App.app").unlink()
        (self.source / "Test App.app").symlink_to(updated)
        self.assertEqual(self.run_state("check"), 1)

    def test_missing_app(self):
        self.record()
        shutil.rmtree(self.app)
        self.assertEqual(self.run_state("check"), 1)

    def test_extra_app(self):
        self.record()
        (self.target / "Extra.app").mkdir()
        self.assertEqual(self.run_state("check"), 1)

    def test_corrupt_state(self):
        self.record()
        self.state.write_text("invalid")
        self.assertEqual(self.run_state("check"), 1)

    def test_store_symlink(self):
        self.record()
        shutil.rmtree(self.app)
        self.app.symlink_to(self.original)
        self.assertEqual(self.run_state("check"), 1)


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
