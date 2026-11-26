import asyncio
import json
import os
from pathlib import Path
import sys
import tempfile


def serve():
    supported = sys.argv[2] == "resources"
    for line in sys.stdin:
        request = json.loads(line)
        method = request.get("method")
        with open(sys.argv[3], "a") as log:
            log.write(method + "\n")
        if "id" not in request:
            continue
        error = None
        if method == "initialize":
            capabilities = {"tools": {}}
            if supported:
                capabilities["resources"] = {}
            result = {
                "protocolVersion": "2025-03-26",
                "capabilities": capabilities,
                "serverInfo": {"name": "fixture", "version": "1"},
            }
        elif method == "tools/list":
            result = {
                "tools": [
                    {
                        "name": "probe",
                        "description": "Fixture tool",
                        "inputSchema": {"type": "object", "properties": {}},
                    }
                ]
            }
        elif method == "resources/list" and supported:
            result = {"resources": [{"uri": "test://fixture", "name": "fixture"}]}
        elif method == "resources/templates/list" and supported:
            result = {"resourceTemplates": []}
        else:
            error = {"code": -32601, "message": "Method not supported"}
        response = {"jsonrpc": "2.0", "id": request["id"]}
        response["error" if error else "result"] = error if error else result
        print(json.dumps(response), flush=True)


async def check(binary, root):
    codex_home = root / ".codex"
    codex_home.mkdir()
    config = []
    for name in ("tools_only", "resources"):
        config.extend(
            [
                f"[mcp_servers.{name}]",
                "command = " + json.dumps(sys.executable),
                "args = "
                + json.dumps(
                    [str(Path(__file__).resolve()), "server", name, str(root / name)]
                ),
            ]
        )
    (codex_home / "config.toml").write_text("\n".join(config))
    log_path = root / "app-server.log"
    with log_path.open("w") as log:
        process = await asyncio.create_subprocess_exec(
            binary,
            "app-server",
            cwd=root,
            env=os.environ | {"HOME": str(root), "CODEX_HOME": str(codex_home)},
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=log,
        )

        async def rpc(identifier, method, params):
            process.stdin.write(
                (
                    json.dumps({"id": identifier, "method": method, "params": params})
                    + "\n"
                ).encode()
            )
            await process.stdin.drain()
            async with asyncio.timeout(45):
                while line := await process.stdout.readline():
                    message = json.loads(line)
                    if message.get("id") == identifier:
                        assert "error" not in message, message
                        return message["result"]
            raise AssertionError("app-server closed before responding")

        try:
            await rpc(
                1,
                "initialize",
                {
                    "clientInfo": {"name": "sysinit-test", "version": "1"},
                    "capabilities": {"experimentalApi": True},
                },
            )
            process.stdin.write(b'{"method":"initialized"}\n')
            await process.stdin.drain()
            result = await rpc(2, "mcpServerStatus/list", {"detail": "full"})
            servers = {item["name"]: item for item in result["data"]}
            assert set(servers) == {"tools_only", "resources"}, servers.keys()
            for name in servers:
                assert servers[name]["tools"], f"{name}: tool discovery failed"
                calls = (root / name).read_text().splitlines()
                resource_calls = {
                    call for call in calls if call.startswith("resources/")
                }
                if name == "tools_only":
                    assert not resource_calls, resource_calls
                    assert not servers[name]["resources"]
                else:
                    assert resource_calls == {
                        "resources/list",
                        "resources/templates/list",
                    }
                    assert servers[name]["resources"][0]["uri"] == "test://fixture"
        except BaseException:
            print(log_path.read_text()[-2000:], file=sys.stderr)
            raise
        finally:
            if process.returncode is None:
                process.terminate()
                try:
                    await asyncio.wait_for(process.wait(), 5)
                except TimeoutError:
                    process.kill()
                    await process.wait()


if sys.argv[1] == "server":
    serve()
else:
    with tempfile.TemporaryDirectory(prefix="codex-mcp-capabilities-") as directory:
        asyncio.run(check(str(Path(sys.argv[1]).resolve()), Path(directory)))
