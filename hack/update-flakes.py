#!/usr/bin/env python3
import json
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]


def api(path):
    return json.loads(subprocess.check_output(["gh", "api", path], text=True))


def update():
    tracked = subprocess.check_output(["git", "ls-files", "--", "flake.nix", "*/flake.nix"], cwd=ROOT, text=True).splitlines()
    cache = {}

    def advance(match):
        owner, repo, ref, query = match.groups()
        if not (re.fullmatch(r"[0-9a-f]{40}", ref) or re.fullmatch(r"v?\d+\.\d+\.\d+", ref)):
            return match.group(0)
        key = (owner, repo, "sha" if len(ref) == 40 else "tag")
        if key not in cache:
            if key[2] == "sha":
                branch = "nixpkgs-unstable" if (owner, repo) == ("NixOS", "nixpkgs") else api(f"repos/{owner}/{repo}")["default_branch"]
                cache[key] = api(f"repos/{owner}/{repo}/commits/{branch}")["sha"]
            else:
                releases = api(f"repos/{owner}/{repo}/releases?per_page=100")
                stable = [release["tag_name"] for release in releases if not release["draft"] and not release["prerelease"]]
                stable = [tag for tag in stable if re.fullmatch(r"v?\d+\.\d+\.\d+", tag)]
                if not stable:
                    stable = [tag["name"] for tag in api(f"repos/{owner}/{repo}/tags?per_page=100") if re.fullmatch(r"v?\d+\.\d+\.\d+", tag["name"])]
                cache[key] = max([ref, *stable], key=lambda tag: tuple(map(int, tag.lstrip("v").split("."))))
        return f'github:{owner}/{repo}/{cache[key]}{query or ""}'

    for relative in sorted(tracked, key=lambda path: (path.count("/"), path)):
        path = ROOT / relative
        text = path.read_text()
        updated = re.sub(r'github:([^/"?]+)/([^/"?]+)/([^"?]+)(\?[^"\s]*)?', advance, text)
        path.write_text(updated)
        subprocess.run(["nix", "flake", "update"], cwd=path.parent, check=True)


if __name__ == "__main__":
    update()
