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
        env = os.environ | {
            "PUEUE_CONFIG_PATH": str(config),
            "XDG_STATE_HOME": str(root / "state"),
            "ZMX_DIR": str(root / "zmx"),
            "ZMX_SESSION_PREFIX": "",
            "SHELL": "/bin/sh",
        }
        env.pop("ZMX_SESSION", None)

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

        def request(capability, identifier=None):
            payload = {
                "version": "provider/v1",
                "kind": "request",
                "requestId": "fixture",
                "capability": capability,
                "input": {"id": identifier},
            }
            result = json.loads(run(provider, data=json.dumps(payload)))
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
            daemon = subprocess.Popen(["pueued"], env=env, stdout=log, stderr=log)
            terminal = None
            try:
                wait(lambda: (root / "socket").exists())
                run(
                    "pueue",
                    "add",
                    "--label",
                    "finished-picker-fixture",
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
                wait(lambda: terminal in run("zmx", "list", "--short").splitlines())
                identifier = str(record["pueue_id"])
                result = request("picker.list")
                assert result["status"] == "ok", result
                items = result["output"]["items"]
                assert {item["id"] for item in items} == {"0", identifier}, items
                assert items[0]["id"] == identifier, items
                assert "Running" in items[0]["segments"][1]["text"], items
                plan = request("picker.open", identifier)["output"]
                assert plan["command"][-2:] == ["attach", terminal], plan
                assert plan["cwd"] == str(root), plan
                assert "ZMX_SESSION" in plan["command"], plan
                open_terminal(plan, b"PICKER_FIXTURE", b"\x1c")
                completed = request("picker.open", "0")["output"]
                assert completed["command"][-2:] == ["0", "log"], completed
                open_terminal(completed, b"LOG_FIXTURE", b"q")
                assert request("picker.open", "9999")["status"] == "error"
                assert request("picker.open", "../0")["status"] == "error"
                run("zmx", "kill", terminal, "--force")
                terminal = None
                fallback = request("picker.open", identifier)["output"]
                assert "attach" not in fallback["command"], fallback
                assert fallback["command"][-1] in ("follow", "log"), fallback
                print(
                    "Pueue picker: live discovery, native terminal attachment, completed logs, stale IDs, and lost-terminal fallback passed"
                )
            finally:
                if terminal:
                    subprocess.run(
                        ["zmx", "kill", terminal, "--force"],
                        env=env,
                        capture_output=True,
                    )
                subprocess.run(["pueue", "kill", "--all"], env=env, capture_output=True)
                daemon.terminate()
                daemon.wait(timeout=10)


check(*sys.argv[1:])
