#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/env.nu (begin)

# XDG Base Directory Specification
$env.XDG_DATA_HOME   = ($env.XDG_DATA_HOME?   | default $"($env.HOME)/.local/share")
$env.XDG_CONFIG_HOME = ($env.XDG_CONFIG_HOME? | default $"($env.HOME)/.config")
$env.XDG_STATE_HOME  = ($env.XDG_STATE_HOME?  | default $"($env.HOME)/.local/state")
$env.XDG_CACHE_HOME  = ($env.XDG_CACHE_HOME?  | default $"($env.HOME)/.cache")

# Locale and encoding
$env.LANG = "en_US.UTF-8"
$env.LC_ALL = "en_US.UTF-8"

# Editors - primary environment variable source
$env.SUDO_EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.EDITOR = "nvim"

# Git configuration
$env.GIT_DISCOVERY_ACROSS_FILESYSTEM = "1"

# Application-specific environment
$env.COLIMA_HOME = $"($env.XDG_CONFIG_HOME)/colima"

# Tool configuration
$env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules"

# System paths - comprehensive list for all applications
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

# Set PATH using Nu's elegant list format
$env.PATH = (
    ($env.PATH | default [] | split row (char esep)) ++ $system_paths
    | uniq
    | where { |path| ($path | path exists) }
)

# Environment variable conversions for external tools
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

# modules/darwin/home/nu/core/env.nu (end)

