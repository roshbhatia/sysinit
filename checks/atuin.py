import datetime
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import selectors
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
import uuid

import tomlkit


def verify_search_input(environment, root):
    child, terminal = pty.fork()
    if child == 0:
        os.execvpe(
            "atuin",
            [
                "atuin",
                "search",
                "--interactive",
                "--result-file",
                str(root / "selection"),
                "--",
                "atuin-visible-query",
            ],
            dict(environment, TERM="xterm-256color"),
        )
    fcntl.ioctl(terminal, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
    output = bytearray()
    try:
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if select.select([terminal], [], [], 0.05)[0]:
                data = os.read(terminal, 65536)
                output.extend(data)
                if b"\x1b[6n" in data:
                    os.write(terminal, b"\x1b[10;1R")
                visible = re.sub(rb"\x1b\[[0-?]*[ -/]*[@-~]", b"", output)
                if (
                    re.search(rb"\[\s*GLOBAL\s*\]\s*atuin-visible-query", visible)
                    and b"\x1b[?25h" in output
                ):
                    break
        else:
            raise AssertionError(
                f"Eight-row picker did not render its search field and cursor: {bytes(output[-2000:])!r}"
            )
        assert b"\x1b[?1049h" not in output, (
            "Inline picker entered the alternate screen"
        )
        os.write(terminal, b"\x03")
    finally:
        os.close(terminal)
        for _ in range(20):
            if os.waitpid(child, os.WNOHANG)[0]:
                break
            time.sleep(0.05)
        else:
            os.kill(child, signal.SIGKILL)
            os.waitpid(child, 0)


with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    configuration = root / "config"
    configuration.mkdir()
    settings = json.loads(Path(sys.argv[1]).read_text())
    assert settings["auto_sync"] is False
    assert settings["update_check"] is False
    assert settings["enter_accept"] is False
    assert settings["threads"]["capture"] is True
    assert settings["threads"]["capture_tools"] is True
    assert settings["output"]["enabled"] is False
    assert settings["pty_proxy"]["enabled"] is False
    settings["data_dir"] = str(root / "data")
    settings["daemon"].update(
        socket_path=str(root / "daemon.sock"),
        pidfile_path=str(root / "daemon.pid"),
        systemd_socket=False,
    )
    (configuration / "config.toml").write_text(tomlkit.dumps(settings))
    environment = dict(
        os.environ,
        HOME=str(root),
        ATUIN_CONFIG_DIR=str(configuration),
        XDG_CONFIG_HOME=str(root / "xdg-config"),
        XDG_DATA_HOME=str(root / "xdg-data"),
        XDG_RUNTIME_DIR=str(root),
        CODEX_HOME=str(root / ".codex"),
        ATUIN_SESSION=uuid.uuid4().hex,
    )

    def run(*arguments):
        return subprocess.check_output(
            ["atuin", *arguments], env=environment, text=True, timeout=20
        ).strip()

    assert run("config", "get", "--resolved", "auto_sync") == "false"
    assert run("config", "get", "--resolved", "threads.capture_tools") == "true"
    with (root / "daemon.log").open("w+") as log:
        daemon = subprocess.Popen(
            ["atuin", "daemon", "start"],
            env=environment,
            stdout=log,
            stderr=log,
        )
        mcp = None
        try:
            for _ in range(100):
                if (root / "daemon.sock").exists():
                    break
                if daemon.poll() is not None:
                    log.seek(0)
                    raise AssertionError(log.read())
                time.sleep(0.05)
            else:
                raise TimeoutError("Atuin daemon socket")

            identifier = run("history", "start", "--", "printf atuin-history-fixture")
            run("history", "end", "--exit", "0", "--", identifier)
            assert "printf atuin-history-fixture" in run(
                "search", "--cmd-only", "atuin-history-fixture"
            )
            verify_search_input(environment, root)

            session = str(uuid.uuid4())
            timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
            sessions = root / ".codex/sessions/2026/10/28"
            sessions.mkdir(parents=True)
            transcript = sessions / f"rollout-2026-10-28T00-00-00-{session}.jsonl"
            payloads = [
                (
                    "session_meta",
                    {
                        "id": session,
                        "timestamp": timestamp,
                        "cwd": str(root),
                        "originator": "codex_cli_rs",
                        "cli_version": "0.164.0",
                    },
                ),
                (
                    "response_item",
                    {
                        "type": "message",
                        "role": "user",
                        "content": [
                            {
                                "type": "input_text",
                                "text": "Investigate atuin-thread-fixture",
                            }
                        ],
                    },
                ),
                (
                    "response_item",
                    {
                        "type": "function_call",
                        "name": "exec_command",
                        "call_id": "fixture-call",
                        "arguments": '{"cmd":"printf atuin-tool-input-fixture"}',
                    },
                ),
                (
                    "response_item",
                    {
                        "type": "function_call_output",
                        "call_id": "fixture-call",
                        "output": "atuin-tool-output-fixture",
                    },
                ),
                (
                    "response_item",
                    {
                        "type": "message",
                        "role": "assistant",
                        "content": [
                            {
                                "type": "output_text",
                                "text": "Verified atuin-thread-fixture",
                            }
                        ],
                    },
                ),
            ]
            transcript.write_text(
                "".join(
                    json.dumps(
                        {"timestamp": timestamp, "type": kind, "payload": payload}
                    )
                    + "\n"
                    for kind, payload in payloads
                )
            )
            run("threads", "import", "--harness", "codex", "--style", "json")
            captured = run("threads", "show", session, "--style", "json")
            for value in [
                "atuin-thread-fixture",
                "atuin-tool-input-fixture",
                "atuin-tool-output-fixture",
            ]:
                assert value in captured, captured
            assert "codex" in run("resume", session, "--print")

            mcp = subprocess.Popen(
                ["atuin", "mcp"],
                env=environment,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=log,
                text=True,
                bufsize=1,
            )
            selector = selectors.DefaultSelector()
            selector.register(mcp.stdout, selectors.EVENT_READ)

            def request(identifier, method, params):
                mcp.stdin.write(
                    json.dumps(
                        {
                            "jsonrpc": "2.0",
                            "id": identifier,
                            "method": method,
                            "params": params,
                        }
                    )
                    + "\n"
                )
                mcp.stdin.flush()
                deadline = time.monotonic() + 10
                while selector.select(max(0, deadline - time.monotonic())):
                    response = json.loads(mcp.stdout.readline())
                    if response.get("id") == identifier:
                        assert "error" not in response, response
                        return response["result"]
                raise TimeoutError(method)

            request(
                1,
                "initialize",
                {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {},
                    "clientInfo": {"name": "sysinit-atuin-check", "version": "1"},
                },
            )
            mcp.stdin.write(
                json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"})
                + "\n"
            )
            mcp.stdin.flush()
            tools = request(2, "tools/list", {})["tools"]
            names = {tool["name"] for tool in tools}
            assert {
                "atuin_history",
                "atuin_threads_search",
                "atuin_threads_list",
                "atuin_threads_read",
            } <= names, names
            result = request(
                3,
                "tools/call",
                {
                    "name": "atuin_threads_search",
                    "arguments": {"terms": "atuin-thread-fixture"},
                },
            )
            assert "atuin-thread-fixture" in json.dumps(result), result
            print(
                "Native local history, full thread capture, resume planning, and MCP search passed"
            )
        finally:
            if mcp is not None:
                mcp.terminate()
                mcp.wait(timeout=10)
            daemon.terminate()
            daemon.wait(timeout=10)
