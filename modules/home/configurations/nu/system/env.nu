#!/usr/bin/env nu
# shellcheck disable=all
$env.XDG_DATA_HOME   = ($env.XDG_DATA_HOME?   | default $"($env.HOME)/.local/share")
$env.XDG_CONFIG_HOME = ($env.XDG_CONFIG_HOME? | default $"($env.HOME)/.config")
$env.XDG_STATE_HOME  = ($env.XDG_STATE_HOME?  | default $"($env.HOME)/.local/state")
$env.XDG_CACHE_HOME  = ($env.XDG_CACHE_HOME?  | default $"($env.HOME)/.cache")

$env.LANG = "en_US.UTF-8"
$env.LC_ALL = "en_US.UTF-8"

$env.SUDO_EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.EDITOR = "nvim"

$env.GIT_DISCOVERY_ACROSS_FILESYSTEM = "1"

$env.COLIMA_HOME = $"($env.XDG_CONFIG_HOME)/colima"

$env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules"

let system_paths = [
    # Nix paths
    "/nix/var/nix/profiles/default/bin"
    $"/etc/profiles/per-user/($env.USER)/bin"
    "/run/current-system/sw/bin"

    # Homebrew paths
    "/opt/homebrew/bin"
    "/opt/homebrew/opt/libgit2@1.8/bin"
    "/opt/homebrew/sbin"

    # System paths
    "/usr/bin"
    "/usr/local/opt/cython/bin"
    "/usr/sbin"

    # User paths
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

    # XDG paths
    $"($env.XDG_CONFIG_HOME)/.cargo/bin"
    $"($env.XDG_CONFIG_HOME)/yarn/global/node_modules/.bin"
    $"($env.XDG_CONFIG_HOME)/zsh/bin"
    $"($env.HOME)/.local/share/.npm-packages/bin"

    # Carapace
    $"($env.XDG_CONFIG_HOME)/carapace/bin"
]

$env.PATH = (
    ($env.PATH | default [] | split row (char esep)) ++ $system_paths
    | uniq
    | where { |path| ($path | path exists) }
)

$env.ENV_CONVERSIONS = {
    PATH: {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    Path: {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

