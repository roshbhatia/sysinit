import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

spec = importlib.util.spec_from_file_location(
    "health", Path(sys.argv.pop(1)) / "modules/darwin/sketchybar-health.py"
)
health = importlib.util.module_from_spec(spec)
spec.loader.exec_module(health)


class HealthTests(unittest.TestCase):
    def test_cli_recovery_and_cooldown(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binary = root / "bar"
            marker = root / "reloaded"
            binary.write_text(
                f"#!{sys.executable}\n"
                "import json, pathlib, sys\n"
                "if sys.argv[-1] == 'bar':\n"
                " print(json.dumps({'items': ['logo', 'front_app', 'clock', 'battery', 'sysinit_health']}))\n"
                "elif sys.argv[-1] == 'sysinit_health':\n"
                " print(json.dumps({'label': {'value': '0'}}))\n"
                "elif sys.argv[-1] == 'monitor-information':\n"
                " print('1 | Display')\n"
                "elif sys.argv[-1] == '--reload':\n"
                f" pathlib.Path({str(marker)!r}).write_text('reload')\n"
            )
            binary.chmod(0o755)
            state = root / "sketchybar/health.json"
            state.parent.mkdir()
            health.save(
                state,
                {"ready_at": 0, "last_check": int(time.time()), "failures": 1},
            )
            args = [
                sys.executable,
                spec.origin,
                "--sketchybar",
                str(binary),
                "--komorebic",
                str(binary),
            ]
            env = {**os.environ, "XDG_CACHE_HOME": directory}
            first = subprocess.run(
                args, env=env, check=True, capture_output=True, text=True
            )
            self.assertIn("reload: Lua heartbeat is stale", first.stdout)
            self.assertEqual(marker.read_text(), "reload")
            second = subprocess.run(
                args, env=env, check=True, capture_output=True, text=True
            )
            self.assertEqual(second.stdout, "")
            state.write_text("")
            subprocess.run(args, env=env, check=True, capture_output=True)
            self.assertGreater(json.loads(state.read_text())["ready_at"], time.time())

    def test_probe(self):
        bar = {"items": ["logo", "front_app", "clock", "battery", "sysinit_health"]}
        heartbeat = {"label": {"value": "1000"}}

        def command(*args):
            return json.dumps(bar if args[-1] == "bar" else heartbeat)

        self.assertEqual(health.probe("sbar", 1050, command), (True, ""))
        self.assertIn("stale", health.probe("sbar", 1100, command)[1])
        bar["items"].remove("clock")
        self.assertIn("missing", health.probe("sbar", 1050, command)[1])
        self.assertFalse(health.probe("sbar", 1050, lambda *args: "invalid")[0])

    def test_timeout_and_bad_heartbeat(self):
        def timeout(*args):
            raise subprocess.TimeoutExpired(args, 5)

        self.assertFalse(health.probe("sbar", 1050, timeout)[0])

    def test_grace_failure_threshold_and_cooldown(self):
        state = {}
        self.assertEqual(health.decide(state, 1000, "bad", ["display"]), "")
        self.assertEqual(health.decide(state, 1030, "", ["display"]), "")
        self.assertEqual(health.decide(state, 1060, "bad", ["display"]), "")
        self.assertEqual(health.decide(state, 1090, "bad", ["display"]), "bad")
        state["last_recovery"] = 1090
        self.assertEqual(health.decide(state, 1120, "bad", ["display"]), "")
        self.assertEqual(health.decide(state, 1150, "", ["display"]), "")
        self.assertEqual(state["failures"], 0)

    def test_wake_and_monitor_failure(self):
        state = {"last_check": 1000, "monitors": ["display"], "ready_at": 0}
        self.assertEqual(health.decide(state, 2000, "stale", None), "")
        self.assertEqual(state["monitors"], ["display"])
        self.assertEqual(health.decide(state, 2030, "", None), "")
        self.assertEqual(health.decide(state, 2060, "", ["display"]), "")
        self.assertEqual(
            health.decide(state, 2090, "", ["new display"]),
            "monitor configuration changed",
        )

    def test_reload_restart_and_escalation(self):
        calls = []

        def command(*args):
            calls.append(args)

        self.assertEqual(health.recover("sbar", True, 0, 1000, command), "reload")
        self.assertEqual(calls[-1], ("sbar", "--reload"))
        self.assertEqual(health.recover("sbar", True, 1000, 1200, command), "restart")
        self.assertIn("kickstart", calls[-1])
        self.assertEqual(health.recover("sbar", False, 0, 2000, command), "restart")

        def failed_reload(*args):
            calls.append(args)
            if args[0] == "sbar":
                raise subprocess.TimeoutExpired(args, 5)

        self.assertEqual(
            health.recover("sbar", True, 0, 2000, failed_reload), "restart"
        )
        self.assertIn("kickstart", calls[-1])


unittest.main()
