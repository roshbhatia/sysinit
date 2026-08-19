#!/usr/bin/env bash
set -euo pipefail

remote=${SYSINIT_REMOTE:-https://github.com/roshbhatia/sysinit.git}
branch=${SYSINIT_BRANCH:-main}
checkout=${SYSINIT_CHECKOUT:-$HOME/.local/share/sysinit}

if [ $# -gt 0 ]; then
  echo "usage: bootstrap.sh" >&2
  exit 2
fi

log() { printf '\033[1msysinit:\033[0m %s\n' "$*"; }

if [ ! -d "$checkout/.git" ]; then
  log "sparse checkout of ${remote} into ${checkout}"
  mkdir -p "$(dirname "$checkout")"
  git clone --filter=blob:none --no-checkout --depth 1 --branch "$branch" \
    "$remote" "$checkout"
else
  log "updating ${checkout}"
  git -C "$checkout" fetch --depth 1 origin "$branch"
  git -C "$checkout" reset --hard "origin/${branch}" > /dev/null 2>&1 ||
    git -C "$checkout" reset --hard FETCH_HEAD > /dev/null
fi

git -C "$checkout" sparse-checkout set --cone modules/home/programs/neovim/config
git -C "$checkout" read-tree -mu HEAD

config="$checkout/modules/home/programs/neovim/config"
test -f "$config/init.lua" || {
  echo "bootstrap: the sparse checkout produced no init.lua" >&2
  exit 1
}

log "linking the neovim config"
mkdir -p "$HOME/.config"
rm -rf "$HOME/.config/nvim"
ln -sfn "$config" "$HOME/.config/nvim"

log "done. The config expects neovim, git, and a C compiler already on PATH."
