#!/usr/bin/env bash
# Run the bootstrap in a clean Ubuntu container and check what came up.
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
image=${SYSINIT_VERIFY_IMAGE:-ubuntu:24.04}
runtime=${SYSINIT_CONTAINER_RUNTIME:-docker}

if ! command -v "$runtime" > /dev/null 2>&1; then
  echo "verify-container: no '$runtime' on PATH" >&2
  exit 1
fi

if ! "$runtime" info > /dev/null 2>&1; then
  echo "verify-container: '$runtime' is installed but not running" >&2
  exit 1
fi

# Under $HOME rather than $TMPDIR: the container runtime on macOS shares the
mkdir -p "$HOME/.cache"
snapshot=$(mktemp -d "$HOME/.cache/sysinit-verify.XXXXXX")
trap 'rm -rf "$snapshot"' EXIT

git -C "$repo_root" ls-files -z --cached --others --exclude-standard |
  tar -C "$repo_root" --null -T - -cf - | tar -C "$snapshot" -xf -
git -C "$snapshot" init -q
git -C "$snapshot" add -A
# `core.hooksPath` is set globally in this checkout, so a plain commit in the
git -C "$snapshot" \
  -c core.hooksPath= \
  -c user.email=gate@example.com -c user.name=gate \
  commit -qm "working tree snapshot"

# `git clone` from a mount refuses when the directory is owned by another uid,
script=$(
  cat << 'INNER'
set -euo pipefail

export HOME=/root
export DEBIAN_FRONTEND=noninteractive
export SYSINIT_REMOTE=/src

apt-get update -qq
apt-get install -y -qq --no-install-recommends git ca-certificates curl >/dev/null

git config --global --add safe.directory /src

# Editor mode first, in its own checkout, so the full run below cannot mask a
# missing dependency it happens to install.
echo "--- bootstrap --editor"
SYSINIT_CHECKOUT=/root/.local/share/sysinit-editor /src/bootstrap/bootstrap.sh --editor
PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH" nvim --headless +qa
test -L /root/.config/nvim
test ! -e /root/.local/share/sysinit-editor/pkgs/sysinit-agent
test ! -e /root/.local/share/sysinit-editor/modules/home/programs/zsh
test ! -f /root/.zshrc
rm -rf /root/.config/nvim /root/.config/mise /root/.local/share/sysinit-editor

/src/bootstrap/bootstrap.sh

# The two assertions this phase's STOP gate names.
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

echo "--- nvim"
nvim --headless +qa

echo "--- sysinit-agent"
sysinit-agent --help >/dev/null

echo "--- the paths manifest"
# The gate asserts the manifest is AT the bootstrap constant, so it names it
# sysinit:documented-default
manifest="$HOME/.local/state/sysinit/paths.json"
test -f "$manifest"
# Copied out so the host can check it against what NIX produces from the same
cp "$manifest" /out/paths.json

echo "--- a note resolves its path from the manifest"
# The manifest is moved somewhere no default would ever name, so a note landing there
# proves the path came from the manifest and not from
# `sysinit:documented-default`.
mkdir -p /opt/elsewhere
# Rewritten by KEY rather than by old value, so this line names no state path of its
# own.
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
github_token=${GITHUB_TOKEN:-}
if [ -z "$github_token" ] && command -v gh > /dev/null 2>&1; then
  github_token=$(gh auth token 2> /dev/null || true)
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
if ! command -v nix > /dev/null 2>&1; then
  echo "verify-container: no nix on PATH, so the nix-side manifest was NOT compared" >&2
  exit 0
fi

echo "--- the nix producer and the shell producer agree"
# Through `homeConfigurations`, not through a host.
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
