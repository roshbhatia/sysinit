#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Claude Code SessionEnd hook — append one JSON line (schema v2) to the worklog.

The worklog is a durable, append-only index of every Claude Code session across
every repo. This hook reads the SessionEnd event JSON on stdin and appends one
compact JSON object; `summary` is deliberately left null for the `worklog` skill
to fill in on demand (the hook records cheap facts and pointers, never prose).

Why Python instead of the old bash+jq: the record is structured data with nested
arrays (per-repo commits and changed files), and assembling that in shell meant a
fragile dance of `jq -R -s` reparsing and manual quoting. A real data model makes
the schema legible and the diffs reviewable.

Best-effort by design: every field is guarded so a single failure (not a git
repo, no transcript, git missing) degrades that field to null/empty and never
aborts the append.

Identity lives in `repos[]` — always a list, never a scalar:
  - a plain git cwd        -> one entry
  - a seshy session        -> one entry per nested git worktree under the session
    (~/.local/state/seshy/sessions/<name>/*, the session root itself is not a repo)

Each repo entry carries the real "did work" signal vs a comparison ref — commit
subjects, the changed-file list, line churn, and the human diffstat — enough to
see WHAT happened without storing the raw diff (git holds it; `url` links to it,
and this line is also mirrored to a size-bounded secret gist).

Append-only and lock-free: a single small `>>` write is one O_APPEND write(),
which the kernel serializes per-inode, so concurrent session-ends never tear a
line. The `worklog` skill is the only rewriter and merges via a temp file.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = 2
MAX_COMMITS = 30
MAX_FILES = 50
PROMPT_CHARS = 200


def run(args: list[str]) -> str | None:
    """Run a command, returning stripped stdout, or None on any failure."""
    try:
        proc = subprocess.run(args, capture_output=True, text=True, timeout=15)
    except Exception:
        return None
    if proc.returncode != 0:
        return None
    return proc.stdout.strip()


def git(repo: str, *args: str) -> str | None:
    return run(["git", "-C", repo, *args])


def is_git(path: str) -> bool:
    try:
        proc = subprocess.run(
            ["git", "-C", path, "rev-parse", "--is-inside-work-tree"],
            capture_output=True,
            text=True,
            timeout=15,
        )
    except Exception:
        return False
    return proc.returncode == 0 and proc.stdout.strip() == "true"


def normalize_remote(url: str) -> str:
    """Normalize a git remote to a browseable https web URL.

    git@github.com:org/repo.git    -> https://github.com/org/repo
    ssh://git@github.com/org/repo   -> https://github.com/org/repo
    https://github.com/org/repo.git -> https://github.com/org/repo
    """
    u = url.removesuffix(".git")
    if u.startswith("git@"):
        host, _, path = u[len("git@") :].partition(":")
        return f"https://{host}/{path}"
    if u.startswith("ssh://"):
        rest = u[len("ssh://") :]
        rest = rest.split("@", 1)[-1]
        return f"https://{rest}"
    return u


def comparison_ref(repo: str, branch: str, base: str) -> str | None:
    """The ref the working branch's commits are measured against.

    Feature branch -> origin/<base> (everything the branch adds). On the base
    branch itself -> origin/<branch> (local commits not yet pushed), which is
    what keeps work done directly on main from vanishing from the log. Returns
    None when no such remote ref exists.
    """
    if not branch or not base:
        return None
    ref = f"origin/{base}" if branch != base else f"origin/{branch}"
    if git(repo, "rev-parse", "--verify", ref) is None:
        return None
    return ref


def git_repo(path: str) -> dict | None:
    """Describe the git worktree at `path`, or None if it is not one."""
    toplevel = git(path, "rev-parse", "--show-toplevel")
    if not toplevel:
        return None
    name = os.path.basename(toplevel)
    branch = git(path, "branch", "--show-current") or ""
    head = git(path, "rev-parse", "--short", "HEAD") or ""
    dirty = (git(path, "diff", "--shortstat") or "").strip()

    remote_raw = git(path, "remote", "get-url", "origin")
    if not remote_raw:
        first_remote = (git(path, "remote") or "").splitlines()
        if first_remote:
            remote_raw = git(path, "remote", "get-url", first_remote[0])
    url = ""
    if remote_raw:
        url = normalize_remote(remote_raw)
        if branch:
            url = f"{url}/tree/{branch}"

    base = ""
    origin_head = git(path, "symbolic-ref", "refs/remotes/origin/HEAD")
    if origin_head:
        base = origin_head.rsplit("/", 1)[-1]

    ref = comparison_ref(path, branch, base)
    commits_ahead = 0
    diffstat = ""
    commits: list[dict] = []
    files: list[dict] = []
    insertions = 0
    deletions = 0

    if ref:
        count = git(path, "rev-list", "--count", f"{ref}..HEAD")
        commits_ahead = int(count) if count and count.isdigit() else 0
        diffstat = (git(path, "diff", "--shortstat", f"{ref}...HEAD") or "").strip()

        # Commit subjects, newest first — the "what was done" in words.
        log = git(path, "log", "--format=%h%x09%s", f"{ref}..HEAD") or ""
        for raw in log.splitlines()[:MAX_COMMITS]:
            if not raw:
                continue
            sha, _, subject = raw.partition("\t")
            commits.append({"sha": sha, "subject": subject})

        # Changed files vs base (name-status) — which files the work touched.
        names = git(path, "diff", "--name-status", f"{ref}...HEAD") or ""
        for raw in names.splitlines()[:MAX_FILES]:
            if not raw:
                continue
            parts = raw.split("\t")
            files.append({"status": parts[0], "path": " -> ".join(parts[1:])})

        # Total line churn vs base.
        numstat = git(path, "diff", "--numstat", f"{ref}...HEAD") or ""
        for raw in numstat.splitlines():
            cols = raw.split("\t")
            if len(cols) >= 2:
                if cols[0].isdigit():
                    insertions += int(cols[0])
                if cols[1].isdigit():
                    deletions += int(cols[1])

    return {
        "name": name,
        "branch": branch,
        "head": head,
        "base": base,
        "url": url,
        "commits_ahead": commits_ahead,
        "commits": commits,
        "files": files,
        "insertions": insertions,
        "deletions": deletions,
        "diffstat": diffstat,
        "dirty": dirty,
    }


def resolve_transcript(hint: str, session_id: str) -> str | None:
    """The stdin path is only a hint (on resume it can name a file that was
    never written), so prefer it when present, else find the session by id under
    the projects dir, else give up."""
    if hint and Path(hint).is_file():
        return hint
    matches = sorted(
        Path.home().glob(f".claude/projects/*/{session_id}.jsonl"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    return str(matches[0]) if matches else None


def extract_text(content) -> str:
    """Collapse a message `content` (string or block array) to its plain text."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(
            block.get("text", "")
            for block in content
            if isinstance(block, dict) and block.get("type") == "text"
        )
    return ""


def parse_iso(value: str) -> datetime | None:
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except Exception:
        return None


def transcript_context(path: str) -> dict:
    """Session intent + scale from the transcript: human prompts (first/last),
    turn count, model, and start time — in one pass over the JSONL."""
    ts_start = ""
    model = ""
    prompts: list[str] = []

    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for raw in fh:
                raw = raw.strip()
                if not raw:
                    continue
                try:
                    obj = json.loads(raw)
                except json.JSONDecodeError:
                    continue
                if not isinstance(obj, dict):
                    continue

                if not ts_start:
                    stamp = obj.get("timestamp")
                    if isinstance(stamp, str) and stamp:
                        ts_start = stamp

                kind = obj.get("type")
                if kind == "assistant":
                    m = (obj.get("message") or {}).get("model")
                    if isinstance(m, str) and m.strip():
                        model = m
                elif kind == "user":
                    text = extract_text((obj.get("message") or {}).get("content"))
                    cleaned = " ".join(text.split())
                    if cleaned:
                        prompts.append(cleaned)
    except OSError:
        pass

    return {
        "ts_start": ts_start,
        "model": model,
        "first_prompt": prompts[0][:PROMPT_CHARS] if prompts else "",
        "last_prompt": prompts[-1][:PROMPT_CHARS] if prompts else "",
        "user_turns": len(prompts),
    }


def main() -> None:
    try:
        event = json.loads(sys.stdin.read() or "{}")
    except json.JSONDecodeError:
        return
    if not isinstance(event, dict):
        return

    session_id = event.get("session_id") or ""
    if not session_id:
        return
    # `resume` is a session *start*, not a completion — recording it produces a
    # junk line with no work behind it.
    reason = event.get("reason") or ""
    if reason == "resume":
        return

    cwd = event.get("cwd") or ""
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    kind = "dir"
    session_name = ""
    repos: list[dict] = []

    seshy_root = Path.home() / ".local/state/seshy/sessions"
    cwd_path = Path(cwd) if cwd else None
    in_seshy = False
    if cwd_path is not None:
        try:
            rel = cwd_path.relative_to(seshy_root)
            in_seshy = bool(rel.parts)
        except ValueError:
            in_seshy = False

    if in_seshy:
        # The unit of work is the seshy session, spanning every nested git child.
        kind = "seshy-session"
        session_name = cwd_path.relative_to(seshy_root).parts[0]
        session_dir = seshy_root / session_name
        for child in sorted(session_dir.iterdir()) if session_dir.is_dir() else []:
            if child.is_dir() and is_git(str(child)):
                obj = git_repo(str(child))
                if obj:
                    repos.append(obj)
    elif cwd and is_git(cwd):
        kind = "repo"
        obj = git_repo(cwd)
        if obj:
            repos.append(obj)

    transcript = resolve_transcript(event.get("transcript_path") or "", session_id)
    ctx = (
        transcript_context(transcript)
        if transcript
        else {"ts_start": "", "model": "", "first_prompt": "", "last_prompt": "", "user_turns": 0}
    )

    duration_min = None
    if ctx["ts_start"]:
        start = parse_iso(ctx["ts_start"])
        end = parse_iso(ts)
        if start and end and end >= start:
            duration_min = int((end - start).total_seconds() // 60)

    # Zero-signal guard: no repos and no prompt means nothing worth indexing.
    if not repos and not ctx["first_prompt"]:
        return

    record = {
        "v": SCHEMA_VERSION,
        "ts": ts,
        "ts_start": ctx["ts_start"] or None,
        "duration_min": duration_min,
        "session_id": session_id,
        "kind": kind,
        "session_name": session_name,
        "model": ctx["model"] or None,
        "user_turns": ctx["user_turns"],
        "repos": repos,
        "cwd": cwd,
        "first_prompt": ctx["first_prompt"],
        "last_prompt": ctx["last_prompt"],
        "transcript_path": transcript or "",
        "end_reason": reason,
        "summary": None,
    }

    log = Path(
        os.environ.get("CLAUDE_WORKLOG_FILE", str(Path.home() / "Documents/worklog.jsonl"))
    )
    log.parent.mkdir(parents=True, exist_ok=True)
    with open(log, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(record, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
