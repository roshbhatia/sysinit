import json
import os
import pathlib
import stat
import subprocess
import sys
import tempfile
import time

from websockets.sync.client import unix_connect

binary = sys.argv[1]
with tempfile.TemporaryDirectory(prefix="cxd-", dir="/tmp") as directory:
    root = pathlib.Path(directory)
    home = root / "home"
    home.mkdir()
    (home / "config.toml").write_text(
        "[features]\ndaemon_auto_start = false\n[analytics]\nenabled = false\n"
    )
    env = {
        **os.environ,
        "CODEX_HOME": str(home),
        "XDG_CONFIG_HOME": str(root / "config"),
        "XDG_DATA_HOME": str(root / "data"),
        "XDG_CACHE_HOME": str(root / "cache"),
    }
    with (root / "server.log").open("w") as log:
        server = subprocess.Popen(
            [binary, "app-server", "--listen", "unix://", "--managed-daemon"],
            cwd=root,
            env=env,
            stdin=subprocess.DEVNULL,
            stdout=log,
            stderr=log,
        )
        connection = None
        try:
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline:
                probe = subprocess.run(
                    [binary, "app-server", "daemon", "version"],
                    env=env,
                    capture_output=True,
                    text=True,
                    timeout=5,
                )
                if probe.returncode == 0:
                    versions = json.loads(probe.stdout)
                    break
                if server.poll() is not None:
                    raise RuntimeError((root / "server.log").read_text())
                time.sleep(0.1)
            else:
                raise RuntimeError(
                    "daemon readiness timed out: " + (root / "server.log").read_text()
                )
            assert versions["cliVersion"] == versions["appServerVersion"], versions
            socket = home / "app-server-control/app-server-control.sock"
            assert stat.S_IMODE(socket.stat().st_mode) == 0o600
            started = subprocess.run(
                [binary, "app-server", "daemon", "start"],
                env=env,
                capture_output=True,
                text=True,
                check=True,
                timeout=10,
            )
            state = json.loads(started.stdout)
            assert (
                state["status"] == "alreadyRunning" and state.get("backend") is None
            ), state
            assert not (home / "packages").exists(), (
                "native start installed another package"
            )
            connection = unix_connect(str(socket), open_timeout=5)

            def request(identifier, method, params):
                payload = {"method": method, "params": params}
                if identifier is not None:
                    payload["id"] = identifier
                connection.send(json.dumps(payload))
                if identifier is None:
                    return
                deadline = time.monotonic() + 15
                while time.monotonic() < deadline:
                    response = json.loads(
                        connection.recv(timeout=max(0, deadline - time.monotonic()))
                    )
                    if response.get("id") == identifier:
                        assert "error" not in response, response
                        return response["result"]
                raise RuntimeError("RPC timed out: " + method)

            request(
                1,
                "initialize",
                {
                    "clientInfo": {"name": "sysinit_daemon_check", "version": "1"},
                    "capabilities": {"experimentalApi": True},
                },
            )
            request(None, "initialized", {})
            assert request(2, "thread/loaded/list", {})["data"] == []
        except Exception:
            print((root / "server.log").read_text()[-4096:], file=sys.stderr)
            raise
        finally:
            if connection is not None:
                connection.close()
            server.terminate()
            server.wait(timeout=15)

print(
    "Codex daemon accepts native version and Unix WebSocket RPC clients without installing another package"
)
