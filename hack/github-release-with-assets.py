#!/usr/bin/env python3
import argparse
import json
import subprocess


def select_release(releases, assets):
    required = set(assets)
    for release in releases:
        if release["draft"] or release["prerelease"]:
            continue
        available = {asset["name"] for asset in release["assets"]}
        if required <= available:
            return release["tag_name"]
    raise ValueError(
        f"No stable release contains all required assets: {sorted(required)}"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("repository")
    parser.add_argument("assets", nargs="+")
    args = parser.parse_args()
    releases = json.loads(
        subprocess.check_output(
            ["gh", "api", f"repos/{args.repository}/releases?per_page=100"], text=True
        )
    )
    print(select_release(releases, args.assets))


if __name__ == "__main__":
    main()
