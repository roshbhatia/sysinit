#!/usr/bin/env bash
set -euo pipefail

remote=${SYSINIT_REMOTE:-https://github.com/roshbhatia/sysinit.nvim.git}
branch=${SYSINIT_BRANCH:-main}
checkout=${SYSINIT_CHECKOUT:-$HOME/.local/share/sysinit.nvim}

if [ "$#" -gt 0 ]; then
  echo "usage: bootstrap.sh" >&2
  exit 2
fi
if [ ! -d "$checkout/.git" ]; then
  git clone --filter=blob:none --branch "$branch" "$remote" "$checkout"
else
  git -C "$checkout" pull --ff-only
fi
test -f "$checkout/init.lua"
mkdir -p "$HOME/.config"
if [ -e "$HOME/.config/nvim" ] || [ -L "$HOME/.config/nvim" ]; then
  if [ "$(readlink "$HOME/.config/nvim" || true)" = "$checkout" ]; then
    exit 0
  fi
  echo "bootstrap: $HOME/.config/nvim already exists; move it before installing" >&2
  exit 1
fi
ln -s "$checkout" "$HOME/.config/nvim"
