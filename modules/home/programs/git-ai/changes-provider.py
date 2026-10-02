import hashlib
import json
import pathlib
import shlex
import subprocess
import sys


def command(directory, *args, data=None):
    return subprocess.run(
        args, cwd=directory, input=data, capture_output=True, check=True, timeout=30
    ).stdout


def authorship(directory, name, revision, target, note_ids):
    args = ["git", "-c", "core.quotePath=false", "blame", "--line-porcelain"]
    data = None
    if target == "commits":
        args.append(revision)
    else:
        if target == "index":
            data = command(directory, "git", "show", f":{name}")
        else:
            data = (pathlib.Path(directory) / name).read_bytes()
        args += ["--contents", "-"]
    output = command(directory, *args, "--", name, data=data).decode(errors="replace")
    documents = {}
    lines, prompts = {}, {}
    origin, source_line, destination, filename = None, None, None, name
    for line in output.splitlines():
        fields = line.split()
        if (
            len(fields) in (3, 4)
            and len(fields[0]) == 40
            and all(c in "0123456789abcdef" for c in fields[0])
        ):
            origin, source_line, destination = fields[0], int(fields[1]), int(fields[2])
        elif line.startswith("filename "):
            filename = line[9:]
            if filename.startswith('"'):
                filename = json.loads(filename)
        elif line.startswith("\t") and origin in note_ids:
            if origin not in documents:
                raw = command(
                    directory, "git", "cat-file", "blob", note_ids[origin]
                ).decode()
                records, separator, metadata = raw.partition("\n---\n")
                if not separator:
                    raise ValueError(f"invalid Git AI note on {origin}")
                meta = json.loads(metadata)
                if meta.get("schema_version") not in (
                    "authorship/3.0.0",
                    "authorship/2.0.0",
                ):
                    raise ValueError(f"unsupported Git AI note schema on {origin}")
                paths = {}
                current = None
                for record in records.splitlines():
                    if not record:
                        continue
                    if not record.startswith("  "):
                        current = (
                            json.loads(record) if record.startswith('"') else record
                        )
                        paths[current] = []
                    else:
                        key, spans = record.strip().split(maxsplit=1)
                        paths[current].append((key, spans))
                documents[origin] = paths, meta
            paths, meta = documents[origin]
            for key, spans in paths.get(filename, []):
                for span in spans.split(","):
                    bounds = [int(value) for value in span.split("-")]
                    if bounds[0] <= source_line <= bounds[-1] and not key.startswith(
                        "h_"
                    ):
                        record = (
                            meta.get("sessions", {}).get(key.split("::")[0])
                            if key.startswith("s_")
                            else meta.get("prompts", {}).get(key)
                        )
                        if record is None:
                            raise ValueError(f"missing Git AI metadata for {key}")
                        lines[str(destination)] = key
                        prompts[key] = record
    ranges = []
    for number, key in lines.items():
        number = int(number)
        if ranges and ranges[-1][2] == key and ranges[-1][1] + 1 == number:
            ranges[-1][1] = number
        else:
            ranges.append([number, number, key])
    return {
        "lines": {
            str(start) if start == end else f"{start}-{end}": key
            for start, end, key in ranges
        },
        "prompts": prompts,
    }


def notes(request):
    if (
        request.get("version") != "changes.provider/v1"
        or request.get("action") != "changes.notes"
    ):
        raise ValueError("expected a changes.provider/v1 changes.notes request")
    directory = request["directory"]
    if request.get("validation"):
        command(directory, "git-ai", "--version")
        return []
    note_ids = dict(
        reversed(line.split())
        for line in command(directory, "git", "notes", "--ref=ai", "list")
        .decode()
        .splitlines()
    )
    if not note_ids:
        return []
    target = (
        "commits"
        if request.get("to")
        else "index"
        if request.get("staged")
        else "working"
    )
    revision = (
        command(
            directory,
            "git",
            "rev-parse",
            "--verify",
            "--end-of-options",
            (request.get("head") or "HEAD") + "^{commit}",
        )
        .decode()
        .strip()
    )
    result = []
    for name in request["files"]:
        path = pathlib.PurePosixPath(name)
        if path.is_absolute() or ".." in path.parts or str(path) != name:
            raise ValueError(f"invalid repository path: {name}")
        if target == "working" and not (pathlib.Path(directory) / name).is_file():
            continue
        tree = revision if target == "commits" else ":"
        if target == "commits":
            exists = command(
                directory, "git", "ls-tree", "--name-only", tree, "--", name
            )
        else:
            exists = command(directory, "git", "ls-files", "--", name)
            if exists:
                exists = command(
                    directory, "git", "ls-tree", "--name-only", revision, "--", name
                )
        if not exists:
            continue
        blame = authorship(directory, name, revision, target, note_ids)
        for span, key in blame["lines"].items():
            agent = blame["prompts"][key]["agent_id"]
            bounds = [int(value) for value in span.split("-")]
            start, end = bounds[0], bounds[-1]
            identifier = hashlib.sha256(
                f"{revision}:{name}:{span}:{key}".encode()
            ).hexdigest()[:24]
            position = {
                "path": name,
                "side": "RIGHT",
                "startSide": "RIGHT",
                "startLine": start,
                "line": end,
                "head": revision if target == "commits" else request.get("head", ""),
                "base": request.get("base", ""),
                "fingerprint": request.get("fingerprint", ""),
                "target": target,
            }
            trace_command = shlex.join(["traces", "--all", "--session", agent["id"]])
            result.append(
                {
                    "id": f"git-ai:{identifier}",
                    "source": "git-ai",
                    "sourceId": identifier,
                    "summary": f"{agent['tool']} / {agent['model']}",
                    "rationale": f"Open the originating session: {trace_command}",
                    "author": agent["tool"],
                    "origin": "external",
                    "authority": "advisory",
                    "state": "open",
                    "session": agent["id"],
                    "provenance": {
                        "kind": "git-ai",
                        "tool": agent["tool"],
                        "sessionId": agent["id"],
                        "workingDirectory": directory,
                    },
                    "anchor": position,
                    "placement": {**position, "quality": "exact"},
                }
            )
    return result


def main():
    try:
        json.dump(
            {"version": "changes.provider/v1", "notes": notes(json.load(sys.stdin))},
            sys.stdout,
        )
        print()
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        if isinstance(error, subprocess.CalledProcessError):
            print(error.stderr.decode(errors="replace"), file=sys.stderr)
        print(f"changes-provider-git-ai: {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
