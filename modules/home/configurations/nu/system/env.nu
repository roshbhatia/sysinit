#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/env.nu (begin)
$env.XDG_DATA_HOME   = ($env.XDG_DATA_HOME?   | default $"($env.HOME)/.local/share")
$env.XDG_CONFIG_HOME = ($env.XDG_CONFIG_HOME? | default $"($env.HOME)/.config")
$env.XDG_STATE_HOME  = ($env.XDG_STATE_HOME?  | default $"($env.HOME)/.local/state")
$env.XDG_CACHE_HOME  = ($env.XDG_CACHE_HOME?  | default $"($env.HOME)/.cache")

def path_add [dir: string] {
  if ($dir | path exists) {
    $env.PATH = ($env.PATH | split row (char esep) | prepend $dir | uniq | str join (char esep))
  }
}

$env.LANG = "en_US.UTF-8"
$env.LC_ALL = "en_US.UTF-8"
$env.SUDO_EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.EDITOR = "nvim"
$env.GIT_DISCOVERY_ACROSS_FILESYSTEM = "1"
$env.COLIMA_HOME = $"($env.XDG_CONFIG_HOME)/colima"

$env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules"
# modules/darwin/home/nu/core/env.nu (end)

