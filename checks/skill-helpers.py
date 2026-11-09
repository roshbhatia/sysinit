"""Exercise the production read-only inspection helpers against real fixtures."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


def load(path):
    spec = importlib.util.spec_from_file_location(Path(path).stem, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


HOST = load(sys.argv.pop(1))
CATALOG = load(sys.argv.pop(1))


class Helpers(unittest.TestCase):
    def test_host_pins_and_active_system_mismatch(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            repo = root / "host"
            repo.mkdir()
            env = {
                **os.environ,
                "HOME": tmp,
                "GIT_CONFIG_GLOBAL": os.devnull,
                "GIT_CONFIG_NOSYSTEM": "1",
            }
            subprocess.run(["git", "init", "-q", str(repo)], check=True, env=env)
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(repo),
                    "-c",
                    "user.name=Fixture",
                    "-c",
                    "user.email=fixture@example.invalid",
                    "commit",
                    "--allow-empty",
                    "-qm",
                    "Initial fixture",
                ],
                check=True,
                env=env,
            )
            (repo / "flake.lock").write_text(
                json.dumps(
                    {"nodes": {"sysinit": {"locked": {"rev": "source-revision"}}}}
                )
            )
            prepared = root / "system"
            prepared.mkdir()
            active = root / "active"
            active.symlink_to(prepared)
            state = HOST.inspect(repo, prepared, active)
            self.assertEqual(state["pins"]["sysinit"], "source-revision")
            self.assertTrue(state["matches"])
            other = root / "other"
            other.mkdir()
            self.assertFalse(HOST.inspect(repo, other, active)["matches"])

    def test_inventory_reports_missing_and_differing_copies(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            catalog = home / "catalog.json"
            catalog.write_text(
                json.dumps(
                    {
                        "roots": ["managed"],
                        "descriptions": {"example": "test", "missing": "test"},
                    }
                )
            )
            for root, body in [("managed", "canonical"), ("other", "different")]:
                folder = home / root / "example"
                folder.mkdir(parents=True)
                (folder / "SKILL.md").write_text(body)
            result = CATALOG.inventory(catalog, home, [home / "other"])
            self.assertEqual(result["missing"][str(home / "managed")], ["missing"])
            self.assertEqual(result["different_copies"], ["example"])
            self.assertEqual(
                [copy["managed"] for copy in result["copies"]["example"]], [True, False]
            )


if __name__ == "__main__":
    unittest.main()
