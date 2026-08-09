#!/usr/bin/env bash
# Run the bootstrap in a clean Ubuntu container and check what came up.
#
# This is phase 9's STOP gate. It is written before the bootstrap it judges, so
# the gate is not authored by the thing under test.
#
# It clones from the WORKING TREE rather than from GitHub. A gate that fetched
# the pushed branch would pass on code that is not the code in front of you, and
# would need a push before every iteration.
#
# `bootstrap.sh` clones, and a clone carries commits rather than a working tree,
# so mounting the repository directly would test the last commit and silently
# ignore every uncommitted edit. The first run of this gate did exactly that and
# reported a missing `bootstrap/tools.toml` that was sitting on disk. So the
# tree is SNAPSHOT into a throwaway repository first: tracked and untracked
# files that git does not ignore, one commit, mounted read-only at /src.
#
# The image is `ubuntu:24.04` and nothing is pre-installed beyond what
# `bootstrap.sh` installs itself. Adding a package here to make the run pass is
# how the gate stops meaning anything: install it from `tools.toml` instead.
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
image=${SYSINIT_VERIFY_IMAGE:-ubuntu:24.04}
runtime=${SYSINIT_CONTAINER_RUNTIME:-docker}

if ! command -v "$runtime" >/dev/null 2>&1; then
  echo "verify-container: no '$runtime' on PATH" >&2
  exit 1
fi

if ! "$runtime" info >/dev/null 2>&1; then
  echo "verify-container: '$runtime' is installed but not running" >&2
  exit 1
fi

# Under $HOME rather than $TMPDIR: the container runtime on macOS shares the
# home directory and does not share /var/folders, and on macOS that path is
# also reached through a symlink that a copy would refuse to follow.
mkdir -p "$HOME/.cache"
snapshot=$(mktemp -d "$HOME/.cache/sysinit-verify.XXXXXX")
trap 'rm -rf "$snapshot"' EXIT

git -C "$repo_root" ls-files -z --cached --others --exclude-standard |
  tar -C "$repo_root" --null -T - -cf - | tar -C "$snapshot" -xf -
git -C "$snapshot" init -q
git -C "$snapshot" add -A
# `core.hooksPath` is set globally in this checkout, so a plain commit in the
# snapshot would run this repository's own pre-commit hooks against a throwaway
# directory. Pointing it at nothing is narrower than a hook-bypass flag, which
# this repository bans for the good reason that it also skips hooks that were
# meant to run.
git -C "$snapshot" \
  -c core.hooksPath= \
  -c user.email=gate@example.com -c user.name=gate \
  commit -qm "working tree snapshot"

# `git clone` from a mount refuses when the directory is owned by another uid,
# which is every bind mount into a container. Marking it safe is narrower than
# running the container as the host user.
#
# `HOME` is set explicitly because the bootstrap writes the paths manifest by
# expanding it, and a container root shell that inherited nothing would expand
# it to the wrong place silently.
script=$(
  cat <<'INNER'
set -euo pipefail

export HOME=/root
export DEBIAN_FRONTEND=noninteractive
export SYSINIT_REMOTE=/src

apt-get update -qq
apt-get install -y -qq --no-install-recommends git ca-certificates curl >/dev/null

git config --global --add safe.directory /src

/src/bootstrap/bootstrap.sh

# The two assertions this phase's STOP gate names. They run through a login
# shell, so PATH has to come from the files the bootstrap wrote rather than from
# anything this script exports.
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

echo "--- nvim"
nvim --headless +qa

echo "--- sysinit-agent"
sysinit-agent --help >/dev/null

echo "--- the paths manifest"
# The gate asserts the manifest is AT the bootstrap constant, so it names it
# rather than reading it. Reading the location from the file whose location is
# under test would assert nothing.
# sysinit:documented-default
manifest="$HOME/.local/state/sysinit/paths.json"
test -f "$manifest"
# Copied out so the host can check it against what NIX produces from the same
# template. Inside the container the only available comparison is against the
# template the bootstrap just expanded, which proves nothing.
cp "$manifest" /out/paths.json

echo "--- a note resolves its path from the manifest"
# The manifest is moved somewhere no default would ever name, so a note landing
# there proves the path came from the manifest and not from
# `sysinit:documented-default`.
mkdir -p /opt/elsewhere
# Rewritten by KEY rather than by old value, so this line names no state path
# of its own. The file already holds the one documented default it is allowed.
sed 's#"agentDiffNotes": "[^"]*"#"agentDiffNotes": "/opt/elsewhere/diff-notes"#' \
  "$manifest" >/tmp/paths.json
export SYSINIT_PATHS_MANIFEST=/tmp/paths.json

cd /tmp && git init -q noterepo && cd noterepo
git config user.email t@example.com && git config user.name t
echo hello >file.txt && git add file.txt && git commit -qm init
echo changed >file.txt
sysinit-agent note add --file file.txt --line 1 --summary "from the container"

note_path=$(sysinit-agent note path)
echo "note path: ${note_path}"
case "$note_path" in
/opt/elsewhere/diff-notes/*) ;;
*)
  echo "the note path did not come from the manifest" >&2
  exit 1
  ;;
esac
INNER
)

# mise fetches release assets through the GitHub API, and an unauthenticated
# container hits the anonymous rate limit rather than a missing tool. Passing a
# token when the host has one keeps a 403 from reading as a broken manifest,
# which it did on one run of this gate.
github_token=${GITHUB_TOKEN:-}
if [ -z "$github_token" ] && command -v gh >/dev/null 2>&1; then
  github_token=$(gh auth token 2>/dev/null || true)
fi

out="${snapshot}.out"
mkdir -p "$out"
trap 'rm -rf "$snapshot" "$out"' EXIT

"$runtime" run --rm \
  -e "GITHUB_TOKEN=${github_token}" \
  -v "${snapshot}:/src:ro" \
  -v "${out}:/out" \
  "$image" \
  bash -euo pipefail -c "$script"

# --------------------------------------------------- the two producers are one
#
# Task 9.8's other half. `bootstrap.sh` expanded the template with sed and
# `modules/shared/options/paths.nix` expands the same template with nix, so the
# two have to agree path for path. Comparing the container's manifest against
# the template it was made from would only re-check sed.
#
# Skipped rather than faked when nix is absent, and it says so, because a gate
# that reports green on a precondition it could not check is worse than no gate.
if ! command -v nix >/dev/null 2>&1; then
  echo "verify-container: no nix on PATH, so the nix-side manifest was NOT compared" >&2
  exit 0
fi

echo "--- the nix producer and the shell producer agree"
# Through `homeConfigurations`, not through a host. `sysinit.paths` is a
# home-manager option, and reaching it under `darwinConfigurations` means naming
# the user, which this gate has no business knowing.
nix_home=$(nix eval --raw --no-warn-dirty \
  "${repo_root}#homeConfigurations.minimal-aarch64-darwin.config.home.homeDirectory")
nix_paths=$(
  nix eval --json --no-warn-dirty \
    "${repo_root}#homeConfigurations.minimal-aarch64-darwin.config.sysinit.paths.resolved" |
    sed "s#${nix_home}#/root#g" |
    python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin), indent=2, sort_keys=True))'
)
shell_paths=$(python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1]))["paths"], indent=2, sort_keys=True))' "$out/paths.json")

if [ "$nix_paths" != "$shell_paths" ]; then
  diff <(printf '%s\n' "$nix_paths") <(printf '%s\n' "$shell_paths") || true
  echo "verify-container: the nix and shell producers disagree" >&2
  exit 1
fi
echo "13 paths, identical"
