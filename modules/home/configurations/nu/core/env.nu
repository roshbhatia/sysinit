#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/env.nu (begin)
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

