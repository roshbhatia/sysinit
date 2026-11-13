import json
import os
from pathlib import Path
import subprocess
import sys
from uuid import UUID

ZMX = sys.argv[1] if len(sys.argv) > 1 else "zmx"
VIEWER = sys.argv[2] if len(sys.argv) > 2 else "pueue-task-view"
ENV = sys.argv[3] if len(sys.argv) > 3 else "env"


def run(*args):
    return subprocess.run(
        args, text=True, capture_output=True, timeout=4, check=True
    ).stdout


def attempt(job):
    label = job.get("label") or ""
    if not label.startswith("task-queue:"):
        return {}
    identifier = str(UUID(label.removeprefix("task-queue:")))
    state = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    try:
        return json.loads((state / "task-queue" / f"{identifier}.json").read_text())
    except FileNotFoundError:
        return {}


def status(job):
    value = job["status"]
    if isinstance(value, str):
        return value
    name = next(iter(value))
    if name == "Done":
        result = value[name]["result"]
        return result if isinstance(result, str) else next(iter(result))
    return name


def jobs():
    return json.loads(run("pueue", "status", "--json"))["tasks"]


def respond(request):
    if request.get("version") != "provider/v1" or request.get("kind") != "request":
        raise ValueError("expected a provider/v1 request")
    capability = request["capability"]
    if capability == "picker.describe":
        return {"title": "Task queue · terminals and logs", "icon": "md_checklist"}
    if capability == "provider.validate":
        jobs()
        return {"ok": True}
    snapshot = jobs()
    if capability == "picker.list":
        items = []
        for identifier, job in sorted(
            snapshot.items(),
            key=lambda item: (
                status(item[1]) not in ("Running", "Paused", "Queued", "Stashed"),
                -int(item[0]),
            ),
        ):
            record = attempt(job)
            command = " ".join(record.get("argv", [])) or job["original_command"]
            name = record.get("session") or job["group"]
            folder = Path(job["path"]).name
            linked = (
                " · thread " + record["thread"][-8:] if record.get("thread") else ""
            )
            target = "terminal/logs" if record.get("terminal") else "logs"
            detail = f"{folder} · {target}{linked} · {' '.join(command.split())[:160]}"
            items.append(
                {
                    "id": identifier,
                    "search": " ".join(
                        [
                            name,
                            detail,
                            job["path"],
                            record.get("task", ""),
                            record.get("thread", ""),
                            command,
                        ]
                    ),
                    "segments": [
                        {"text": f"#{identifier} {status(job)} {name}", "role": "name"},
                        {"text": detail, "role": "detail"},
                    ],
                }
            )
        return {"items": items}
    if capability == "picker.open":
        identifier = request["input"]["id"]
        if not isinstance(identifier, str) or identifier not in snapshot:
            raise ValueError("Pueue task no longer exists")
        job = snapshot[identifier]
        record = attempt(job)
        terminal = record.get("terminal")
        if terminal and terminal in run(ZMX, "list", "--short").splitlines():
            command = [
                ENV,
                "-u",
                "ZMX_SESSION",
                "-u",
                "ZMX_SESSION_PREFIX",
                ZMX,
                "attach",
                terminal,
            ]
        else:
            command = [
                VIEWER,
                identifier,
                "follow" if status(job) == "Running" else "log",
            ]
        cwd = Path(job["path"])
        return {
            "kind": "spawn",
            "label": f"Pueue #{identifier}",
            "cwd": str(cwd if cwd.is_dir() else Path.home()),
            "command": command,
            "environment": {},
        }
    raise ValueError("unsupported capability: " + capability)


def main():
    request = {}
    try:
        request = json.load(sys.stdin)
        output = respond(request)
        result = {"status": "ok", "output": output}
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        result = {"status": "error", "message": str(error)}
    result.update(
        version="provider/v1",
        kind="result",
        requestId=request.get("requestId", "invalid"),
    )
    print(json.dumps(result))


if __name__ == "__main__":
    main()
