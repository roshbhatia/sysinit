import json
import fcntl
import os
from pathlib import Path
import pty
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time


def check(provider, queue):
    with tempfile.TemporaryDirectory(prefix="pq-picker-", dir="/tmp") as directory:
        root = Path(directory).resolve()
        config = root / "pueue.json"
        config.write_text(
            json.dumps(
                {
                    "shared": {
                        "pueue_directory": str(root / "data"),
                        "runtime_directory": str(root),
                        "unix_socket_path": str(root / "socket"),
                    }
                }
            )
        )
        socket = root / "mux.sock"
        mux_config = root / "mux.lua"
        mux_config.write_text(
            f'return {{ unix_domains = {{ {{ name = "unix", socket_path = "{socket}" }} }}, '
            "mux_server_spawn_initial_tab = false }\n"
        )
        env = os.environ | {
            "HOME": str(root),
            "PUEUE_CONFIG_PATH": str(config),
            "XDG_STATE_HOME": str(root / "state"),
            "TQ_WEZTERM_SOCKET": str(socket),
            "WEZTERM_UNIX_SOCKET": str(socket),
            "SHELL": "/bin/sh",
        }
        env.pop("WEZTERM_PANE", None)

        def run(*args, data=None):
            return subprocess.run(
                args,
                env=env,
                input=data,
                text=True,
                capture_output=True,
                timeout=15,
                check=True,
            ).stdout

        def wait(predicate):
            for _ in range(150):
                result = predicate()
                if result:
                    return result
                time.sleep(0.1)
            raise AssertionError("isolated task queue did not become ready")

        def mux(*args):
            return run("wezterm", "cli", "--prefer-mux", "--no-auto-start", *args)

        def panes():
            return {
                pane["workspace"]: str(pane["pane_id"])
                for pane in json.loads(mux("list", "--format", "json"))
            }

        def request(capability, identifier=None):
            payload = {
                "version": "provider/v1",
                "kind": "request",
                "requestId": "fixture",
                "capability": capability,
                "input": {"id": identifier},
            }
            lines = run(provider, data=json.dumps(payload)).splitlines()
            assert len(lines) == 1, "expected one JSON frame per line"
            result = json.loads(lines[0])
            assert result["requestId"] == "fixture", result
            return result

        def open_terminal(plan, marker, close):
            child, master = pty.fork()
            if child == 0:
                os.chdir(plan["cwd"])
                os.execvpe(
                    plan["command"][0],
                    plan["command"],
                    env | {"TERM": "xterm-256color"},
                )
            fcntl.ioctl(master, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))
            output = bytearray()
            try:
                deadline = time.monotonic() + 10
                while marker not in output and time.monotonic() < deadline:
                    if select.select([master], [], [], 0.1)[0]:
                        data = os.read(master, 65536)
                        output.extend(data)
                        if b"\x1b[6n" in data:
                            os.write(master, b"\x1b[1;1R")
                assert marker in output, repr(output[-2000:])
                os.write(master, close)
            finally:
                os.close(master)
                os.kill(child, signal.SIGTERM)
                deadline = time.monotonic() + 1
                while time.monotonic() < deadline:
                    if os.waitpid(child, os.WNOHANG)[0]:
                        break
                    time.sleep(0.05)
                else:
                    os.kill(child, signal.SIGKILL)
                    os.waitpid(child, 0)

        with (root / "daemon.log").open("w") as log:
            server = subprocess.Popen(
                ["wezterm-mux-server", "--config-file", str(mux_config)],
                env=env,
                stdout=log,
                stderr=log,
            )
            daemon = subprocess.Popen(["pueued"], env=env, stdout=log, stderr=log)
            try:
                wait(lambda: (root / "socket").exists() and socket.exists())
                assert json.loads(run(queue, "status")) == []
                state = Path(env["XDG_STATE_HOME"])
                assert (state / "tq").is_dir()

                state = root / "legacy-state"
                env["XDG_STATE_HOME"] = str(state)
                legacy = state / "task-queue"
                legacy.mkdir(parents=True)
                legacy_id = "d06232e1-2b5d-401a-853d-074b6f4137f1"
                (legacy / f"{legacy_id}.json").write_text(
                    json.dumps({"id": legacy_id, "session": "Legacy session"})
                )
                run(
                    "pueue",
                    "add",
                    "--label",
                    f"task-queue:{legacy_id}",
                    "--",
                    "printf LOG_FIXTURE",
                )
                wait(
                    lambda: all(
                        isinstance(job["status"], dict) and "Done" in job["status"]
                        for job in json.loads(run("pueue", "status", "--json"))[
                            "tasks"
                        ].values()
                    )
                )
                history = json.loads(run(queue, "status"))
                assert [
                    (attempt["id"], attempt["pueue_id"]) for attempt in history
                ] == [(legacy_id, 0)], history
                record = json.loads(
                    run(
                        queue,
                        "submit",
                        "--cwd",
                        str(root),
                        "--terminal",
                        "--",
                        "sh",
                        "-c",
                        "printf PICKER_FIXTURE; sleep 120",
                    )
                )
                terminal = record["terminal"]
                wait(lambda: terminal in panes())
                identifier = str(record["pueue_id"])
                jobs = json.loads(run("pueue", "status", "--json"))["tasks"]
                assert jobs[identifier]["label"] == f"tq:{record['id']}"
                result = request("picker.list")
                assert result["status"] == "ok", result
                items = result["output"]["items"]
                assert {item["id"] for item in items} == {"0", identifier}, items
                assert items[0]["id"] == identifier, items
                assert "Running" in items[0]["segments"][0]["text"], items
                assert "terminal/logs" in items[0]["segments"][1]["text"], items
                assert "Legacy session" in items[1]["segments"][0]["text"], items
                plan = request("picker.open", identifier)["output"]
                assert plan["label"] == terminal, plan
                assert plan["cwd"] == str(root), plan
                wait(
                    lambda: (
                        "PICKER_FIXTURE"
                        in mux("get-text", "--pane-id", panes()[terminal])
                    )
                )
                completed = request("picker.open", "0")["output"]
                assert completed["command"][-2:] == ["0", "log"], completed
                open_terminal(completed, b"LOG_FIXTURE", b"q")
                assert request("picker.open", "9999")["status"] == "error"
                assert request("picker.open", "../0")["status"] == "error"
                mux("kill-pane", "--pane-id", panes()[terminal])
                wait(lambda: terminal not in panes())
                fallback = request("picker.open", identifier)["output"]
                assert fallback["label"] != terminal, fallback
                assert fallback["command"][-1] in ("follow", "log"), fallback
                print(
                    "Pueue picker: live discovery, mux workspace attachment, completed logs, stale IDs, and lost-terminal fallback passed"
                )
            finally:
                subprocess.run(["pueue", "kill", "--all"], env=env, capture_output=True)
                daemon.terminate()
                daemon.wait(timeout=10)
                server.terminate()
                server.wait(timeout=10)


check(*sys.argv[1:])
