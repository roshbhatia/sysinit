"""Review PR revisions in an isolated repository, preserving local Changes notes."""

import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import sys


def read_json(endpoint):
    return json.loads(subprocess.check_output(["gh", "api", endpoint], text=True))


def revision(value):
    if not isinstance(value, str) or not re.fullmatch(r"[0-9a-f]{40}", value):
        raise ValueError("GitHub returned an invalid commit ID")
    return value


def review(directory, repository, merge_base, head, tool, history):
    def git(*args):
        return subprocess.run(["git", "-C", str(directory), *args], check=True)

    git("init", "--quiet", "--template=")
    shallow = (directory / ".git/shallow").exists()
    depth = (["--unshallow"] if shallow else []) if history else ["--depth=1"]
    git("fetch", "--quiet", "--no-tags", *depth, repository, merge_base, head)
    git("update-ref", "HEAD", merge_base)
    git("update-ref", "refs/pr/head", head)
    # Changes' staged view compares the whole PR without touching a user's checkout.
    git("read-tree", head)
    if tool == "changes":
        command = ["changes", "interactive", "--staged"]
    else:
        comparison = f"{merge_base}..{head}"
        action = (
            f"DiffviewFileHistory --range={comparison}"
            if history
            else f"DiffviewOpen {comparison}"
        )
        command = ["nvim", "-n", "-c", action]
    return subprocess.run(command, cwd=directory).returncode


def main(url, tool="nvim", history=False):
    match = re.fullmatch(
        r"https://github\.com/([A-Za-z0-9-]+)/([A-Za-z0-9_.-]+)/pull/([1-9][0-9]*)", url
    )
    if not match or match[2] in (".", ".."):
        raise ValueError("Expected https://github.com/owner/repo/pull/number")
    owner, repo, number = match.groups()
    api = f"repos/{owner}/{repo}"
    pr = read_json(f"{api}/pulls/{number}")
    base, head = revision(pr["base"]["sha"]), revision(pr["head"]["sha"])
    comparison = read_json(f"{api}/compare/{base}...{head}")
    merge_base = revision(comparison["merge_base_commit"]["sha"])
    state = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    directory = state / "gh-dash/reviews" / owner.lower() / repo.lower() / number
    directory.mkdir(parents=True, exist_ok=True)
    with directory.with_suffix(".lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise ValueError("This PR already has an open diff viewer") from error
        return review(
            directory,
            f"https://github.com/{owner}/{repo}.git",
            merge_base,
            head,
            tool,
            history,
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url")
    parser.add_argument("--tool", choices=["nvim", "changes"], default="nvim")
    parser.add_argument("--history", action="store_true")
    args = parser.parse_args()
    if args.history and args.tool != "nvim":
        parser.error("--history uses Neovim")
    try:
        sys.exit(main(args.url, args.tool, args.history))
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print(f"gh-pr-diff: {error}", file=sys.stderr)
        sys.exit(1)
