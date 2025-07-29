#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/env.nu (begin)
$env.XDG_DATA_HOME   = ($env.XDG_DATA_HOME   | default $"($env.HOME)/.local/share")
$env.XDG_CONFIG_HOME = ($env.XDG_CONFIG_HOME | default $"($env.HOME)/.config")
$env.XDG_STATE_HOME  = ($env.XDG_STATE_HOME  | default $"($env.HOME)/.local/state")
$env.XDG_CACHE_HOME  = ($env.XDG_CACHE_HOME  | default $"($env.HOME)/.cache")

def path_add [dir: string] {
  if ($dir | path exists) {
    $env.PATH = ($env.PATH | split row (char esep) | prepend $dir | uniq | str join (char esep))
  }
}

let paths = [
  "/opt/homebrew/bin"
  "/opt/homebrew/opt/libgit2@1.8/bin"
  "/opt/homebrew/sbin"
  "/usr/bin"
  "/usr/local/opt/cython/bin"
  "/usr/sbin"
  $"($env.HOME)/.cargo/bin"
  $"($env.HOME)/.krew/bin"
  $"($env.HOME)/.local/bin"
  $"($env.HOME)/.npm-global/bin"
  $"($env.HOME)/.npm-global/bin/yarn"
  $"($env.HOME)/.rvm/bin"
  $"($env.HOME)/.uv/bin"
  $"($env.HOME)/.yarn/bin"
  $"($env.HOME)/.yarn/global/node_modules/.bin"
  $"($env.HOME)/bin"
  $"($env.HOME)/go/bin"
  $"($env.XDG_CONFIG_HOME)/.cargo/bin"
  $"($env.XDG_CONFIG_HOME)/yarn/global/node_modules/.bin"
  $"($env.XDG_CONFIG_HOME)/zsh/bin"
  $"($env.XDG_DATA_HOME)/.npm-packages/bin"
]

for path in $paths {
  path_add $path
}


$env.LANG = "en_US.UTF-8"
$env.LC_ALL = "en_US.UTF-8"
$env.SUDO_EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.EDITOR = "nvim"
$env.GIT_DISCOVERY_ACROSS_FILESYSTEM = "1"
$env.COLIMA_HOME = $"($env.XDG_CONFIG_HOME)/colima"

$env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules"
$env.FZF_DEFAULT_OPTS = [
  "--bind=resize:refresh-preview"
  "--cycle"
  "--height=30"
  "--highlight-line"
  "--ignore-case"
  "--info=inline"
  "--input-border=rounded"
  "--layout=reverse"
  "--list-border=rounded"
  "--no-scrollbar"
  "--pointer='>'"
  "--preview-border=rounded"
  "--prompt='>> '"
  "--scheme=history"
  "--style=minimal"
] | str join " "
# modules/darwin/home/nu/core/env.nu (end)

