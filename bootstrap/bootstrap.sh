#!/usr/bin/env bash
# Bring this configuration up on a box with no Nix.
#
#   curl -fsSL https://raw.githubusercontent.com/roshbhatia/sysinit/main/bootstrap/bootstrap.sh | bash
#
# What it installs is `bootstrap/tools.toml`, which is the `minimal` profile's
# own manifest rather than a second list. design.md section 6 has the reasoning.
#
# SPARSE CHECKOUT, NOT A FULL CLONE. design.md section 7 kept the neovim config
# in this repository and chose the sparse checkout over splitting it out, so an
# ephemeral box fetches the four directories it needs and not the whole tree.
#
# It is re-runnable. Every step either skips or overwrites, so a second run on a
# half-finished box finishes it rather than failing.
set -euo pipefail

remote=${SYSINIT_REMOTE:-https://github.com/roshbhatia/sysinit.git}
branch=${SYSINIT_BRANCH:-main}
checkout=${SYSINIT_CHECKOUT:-$HOME/.local/share/sysinit}

log() { printf '\033[1msysinit:\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- 1. the tree

# `--no-checkout` first, so the working tree is never fully materialized. The
# cone list is the four paths this bootstrap reads, and nothing else lands.
if [ ! -d "$checkout/.git" ]; then
  log "sparse checkout of ${remote} into ${checkout}"
  mkdir -p "$(dirname "$checkout")"
  git clone --filter=blob:none --no-checkout --depth 1 --branch "$branch" \
    "$remote" "$checkout"
else
  log "updating ${checkout}"
  git -C "$checkout" fetch --depth 1 origin "$branch"
  git -C "$checkout" reset --hard "origin/${branch}" >/dev/null 2>&1 ||
    git -C "$checkout" reset --hard FETCH_HEAD >/dev/null
fi

git -C "$checkout" sparse-checkout set --cone \
  bootstrap \
  modules/home/programs/neovim/config \
  modules/home/programs/zsh \
  modules/shared/options \
  pkgs/sysinit-agent
# `read-tree -mu HEAD` rather than `checkout "$branch"`. After `--no-checkout`
# git has already set HEAD to that branch, so checking it out is a no-op that
# leaves the working tree empty; the first run of this script hit exactly that
# and reached `awk` with nothing on disk.
git -C "$checkout" read-tree -mu HEAD

test -f "$checkout/bootstrap/tools.toml" || {
  echo "bootstrap: the sparse checkout produced no tools.toml" >&2
  exit 1
}

# ------------------------------------------------------- 2. the paths manifest

# Written from `modules/shared/options/paths-layout.json` by substituting $HOME
# and nothing else, which is the whole reason that template spells every path in
# full. Nix reads the same file through `modules/shared/options/paths.nix`, so
# there is one producer of these paths and two expanders of it.
#
# Deliberately NOT authored here. A second list of paths in a second language is
# the defect phase 4 removed, and `hack/check-state-paths.sh` fails on one.
layout="$checkout/modules/shared/options/paths-layout.json"
# The one path no consumer can learn from the manifest, because it IS the
# manifest. Every reader hardcodes this same constant; `paths.nix` calls it the
# bootstrap constant and derives it from the same template.
# sysinit:documented-default
manifest="$HOME/.local/state/sysinit/paths.json"

log "writing ${manifest}"
mkdir -p "$(dirname "$manifest")"
sed "s#\$HOME#${HOME}#g" "$layout" >"$manifest.tmp"
mv "$manifest.tmp" "$manifest"

# --------------------------------------------------------- 3. system packages

# The `system` entries in the manifest. Read out of the TOML by shell rather
# than by python, because python is not guaranteed on the box this runs on and
# the shape here is two fixed keys.
if command -v apt-get >/dev/null 2>&1; then
  packages=$(
    awk '
      /^\[\[tool\]\]|^\[\[program\]\]/ { pkg = "" }
      /^system = / { gsub(/^system = "|"$/, "", $0); print $0 }
    ' "$checkout/bootstrap/tools.toml"
  )
  log "apt-get install: $(echo "$packages" | tr '\n' ' ')"
  # shellcheck disable=SC2086
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends $packages >/dev/null
else
  log "no apt-get; skipping the distribution packages"
fi

# ------------------------------------------------------------------- 4. mise

if ! command -v mise >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/mise" ]; then
  log "installing mise"
  curl -fsSL https://mise.run | sh
fi
export PATH="$HOME/.local/bin:$PATH"

# The generated file becomes mise's GLOBAL config, by symlink, rather than
# being passed through MISE_CONFIG_FILE. Two reasons: a shim resolves its
# version from the config mise finds on its own, so an env var set only during
# install leaves `go` unresolvable afterwards, which one run of the gate hit by
# name; and a symlink means `git pull` in the checkout updates the tool list.
log "mise install"
mkdir -p "$HOME/.config/mise"
ln -sfn "$checkout/bootstrap/mise.toml" "$HOME/.config/mise/config.toml"
mise trust --yes "$HOME/.config/mise/config.toml" >/dev/null 2>&1 || true
mise install --yes
mise reshim >/dev/null 2>&1 || true

export PATH="$HOME/.local/share/mise/shims:$PATH"

# ---------------------------------------------------------------- 5. the config

# neovim is a symlink to the checkout, which is what the Nix side does too
# through `mkOutOfStoreSymlink`. So `git pull` in the checkout updates the
# editor on both kinds of box.
log "linking the neovim config"
mkdir -p "$HOME/.config"
rm -rf "$HOME/.config/nvim"
ln -sfn "$checkout/modules/home/programs/neovim/config" "$HOME/.config/nvim"

# zsh cannot be a symlink: the Nix side assembles `initContent` from fragments
# rather than shipping a directory. So the fragments are SOURCED in the order
# `modules/home/programs/zsh/default.nix` concatenates them. That order is
# written twice, here and there, and it is the one duplication this bootstrap
# has not removed.
log "writing the zsh config"
zsh_dir="$checkout/modules/home/programs/zsh"
{
  echo "# GENERATED by bootstrap/bootstrap.sh. Edit the fragments in"
  echo "# ${zsh_dir} and re-run it."
  echo "export SYSINIT_CHECKOUT=${checkout}"
  # shellcheck disable=SC2016  # written literally into .zshrc, expanded there
  echo 'export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$HOME/go/bin:$PATH"'
  for fragment in \
    core/zshenv.zsh \
    core/init.zsh \
    core/path.zsh \
    core/compinit.zsh \
    core/path-apply.zsh \
    system/env.zsh \
    lib/cache.zsh \
    integrations/completions.zsh \
    integrations/extras.zsh; do
    echo ". ${zsh_dir}/${fragment}"
  done
} >"$HOME/.zshrc"

# --------------------------------------------------------- 6. sysinit-agent

# `go install` rather than a release binary: this is the repository's own tool
# and it has no release channel. `tools.toml` says the same about `go-grip`,
# which is why that one is dropped instead.
# GOBIN explicitly, rather than trusting the default. `go install` writes to
# `$(go env GOPATH)/bin`, and GOPATH under a mise-managed go is not necessarily
# `$HOME/go`; one run of the gate installed the binary somewhere PATH did not
# reach and reported `command not found`. `$HOME/.local/bin` is already on PATH
# because mise installs itself there.
log "go install ./pkgs/sysinit-agent"
mkdir -p "$HOME/.local/bin"
(cd "$checkout/pkgs/sysinit-agent" && GOBIN="$HOME/.local/bin" go install .)

log "done. Open a new shell, or: exec zsh"
