import importlib.util
import plistlib
import subprocess
import sys
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("defaults", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DefaultsTest(unittest.TestCase):
    def test_drift_and_restart(self):
        inventory = {"com.apple.dock": {"size": 40, "unmanaged": True}}
        writes, restarts, reads = [], [], []

        def run(args, **kwargs):
            if args[0] == "restart":
                restarts.append(args)
                return subprocess.CompletedProcess(args, 0)
            _, operation, domain, *rest = args
            if operation == "export":
                reads.append(domain)
                if domain not in inventory:
                    return subprocess.CompletedProcess(args, 1, b"", b"Domain does not exist")
                return subprocess.CompletedProcess(args, 0, plistlib.dumps(inventory[domain]), b"")
            key, value = rest
            inventory.setdefault(domain, {})[key] = plistlib.loads(value.encode())
            writes.append((domain, key))
            return subprocess.CompletedProcess(args, 0)

        desired = [["com.apple.dock", {"size": 40}], ["new", {"enabled": False}],
                   ["new", {"list": [1, "two"]}]]
        with patch.object(module.subprocess, "run", side_effect=run):
            self.assertEqual(module.apply(desired, "defaults", "restart"), 2)
            self.assertEqual(reads, ["com.apple.dock", "new"])
            self.assertEqual(restarts, [])
            self.assertEqual(module.apply(desired, "defaults", "restart"), 0)
            inventory["com.apple.dock"]["size"] = 10
            self.assertEqual(module.apply(desired, "defaults", "restart"), 1)
            self.assertEqual(len(restarts), 1)
            self.assertTrue(inventory["com.apple.dock"]["unmanaged"])

    def test_read_error_does_not_write(self):
        with patch.object(module.subprocess, "run", return_value=
                          subprocess.CompletedProcess([], 1, b"", b"permission denied")) as run:
            with self.assertRaises(RuntimeError):
                module.apply([["domain", {"key": 1}]])
            self.assertEqual(run.call_count, 1)


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
