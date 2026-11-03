import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

SCRIPT = Path(sys.argv.pop(1)).resolve()
REDUCER = Path(sys.argv.pop(1)).resolve()


class SessionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.panes = self.root / "panes"
        self.panes.mkdir()
        bins = self.root / "bin"
        bins.mkdir()
        for name, code in {
            "wezterm": "assert sys.argv[1:] == ['cli','--no-auto-start','list','--format','json']\nprint(os.environ['LIVE'])\nsys.exit(int(os.environ.get('PROBE_EXIT','0')))\n",
            "tmux": "print(os.environ.get('TMUX_LIVE',''))\nsys.exit(int(os.environ.get('TMUX_PROBE_EXIT','1')))\n",
            "sy": "assert sys.argv[1:] == ['list','--names']\nprint('session with spaces\\nidle session')\n",
        }.items():
            path = bins / name
            path.write_text(f"#!{sys.executable}\nimport os,sys\n" + code)
            path.chmod(0o755)
        self.env = dict(
            os.environ,
            PATH=f"{bins}:{os.environ['PATH']}",
            FIXTURE=str(self.root),
            LIVE="[]",
        )
        self.script = self.root / "run.sh"
        self.script.write_text(
            'sysinit_path() { if [ "$1" = agentPanes ]; then echo "$FIXTURE/panes"; else echo "$FIXTURE"; fi; }\n'
            + SCRIPT.read_text().replace("@agentSessionsReducer@", str(REDUCER))
        )
        (self.root / "selected.json").write_text(
            json.dumps(
                {"selected": "session with spaces", "heartbeat": int(time.time())}
            )
        )

    def run_status(self):
        output = subprocess.check_output(
            ["bash", str(self.script)], env=self.env, text=True
        )
        return json.loads(output)

    def seed(self, statuses):
        live = []
        for index, status in enumerate(statuses):
            pane = str(index)
            (self.panes / f"{pane}.json").write_text(
                json.dumps(
                    {
                        "pane": pane,
                        "status": status,
                        "repo": "/repo with spaces",
                        "since": 1,
                    }
                )
                + "\n"
            )
            live.append(
                {
                    "pane_id": index,
                    "workspace": "session with spaces",
                    "is_active": index == 0,
                }
            )
        self.env["LIVE"] = json.dumps(live)

    def test_mixed_status(self):
        self.seed(["working", "done"])
        session = self.run_status()["sessions"][0]
        self.assertEqual(
            (session["status"], session["blocked"], session["attention"]),
            ("working", 0, 1),
        )
        self.assertEqual(session["repo"], "/repo with spaces")
        self.seed(["working", "waiting"])
        session = self.run_status()["sessions"][0]
        self.assertEqual(
            (session["status"], session["blocked"], session["attention"]),
            ("waiting", 1, 1),
        )

    def test_empty_and_failed_discovery(self):
        self.seed(["working"])
        self.run_status()
        self.env["PROBE_EXIT"] = "1"
        payload = self.run_status()
        self.assertEqual(payload["discovery_state"], "unavailable")
        self.assertEqual(payload["selection_state"], "stale")
        self.env["PROBE_EXIT"] = "0"
        self.env["LIVE"] = "[]"
        self.assertTrue(all(row["panes"] == 0 for row in self.run_status()["sessions"]))

    def test_tmux_and_native_panes_share_the_bus(self):
        self.seed(["working"])
        (self.panes / "%2.json").write_text(
            json.dumps(
                {
                    "pane": "%2",
                    "session": "tmux-session",
                    "status": "waiting",
                    "since": 2,
                }
            )
        )
        self.env["TMUX_LIVE"] = "%2\ttmux-session\t1"
        self.env["TMUX_PROBE_EXIT"] = "0"
        rows = self.run_status()["sessions"]
        self.assertEqual(
            {row["name"]: row["status"] for row in rows if row["panes"]},
            {"session with spaces": "working", "tmux-session": "waiting"},
        )

    def test_focused_heartbeat_wins_over_background_active_pane(self):
        self.seed(["working"])
        self.env["LIVE"] = json.dumps(
            [
                {"pane_id": 0, "workspace": "background", "is_active": True},
                {"pane_id": 1, "workspace": "session with spaces", "is_active": True},
            ]
        )
        self.assertEqual(self.run_status()["selected"], "session with spaces")

    def test_malformed_records(self):
        self.seed(["working"])
        valid = self.panes / "0.json"
        valid.write_text(json.dumps(json.loads(valid.read_text()), indent=2))
        (self.panes / "bad.json").write_text("interrupted write\n")
        self.assertEqual(self.run_status()["sessions"][0]["panes"], 1)
        self.env["LIVE"] = "invalid"
        self.assertEqual(self.run_status()["discovery_state"], "unavailable")


if __name__ == "__main__":
    unittest.main()
