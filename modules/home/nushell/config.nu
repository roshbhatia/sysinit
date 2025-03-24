# Nushell Config File
# version = 0.82.0

# Load environment config
source ~/.config/nushell/env.nu

# Load devenv pre-hook for direnv-like functionality
source ~/.config/nushell/devenv.pre.nu

# Set common aliases
alias ... = cd ../..
alias .. = cd ..
alias ~ = cd ~

# Define system command aliases
alias tf = terraform

# Set up aliases for common tools when they exist
if (which code-insiders | length) > 0 {
    alias code = code-insiders
}

if (which kubecolor | length) > 0 {
    alias kubectl = kubecolor
    alias k = kubectl
}

if (which eza | length) > 0 {
    alias l = eza --icons=always -1
    alias ll = eza --icons=always -1 -a
    alias lt = eza --icons=always -1 -a -T
}

if (which yazi | length) > 0 {
    alias y = yazi
}

# Use nushell functions to create command-line utilities
def nuopen [arg, --raw (-r)] { if $raw { open -r $arg } else { open $arg } }
def nuhelp [] { help commands | sort-by name | grid -c }

# Show macchina in main shell window (similar to the zsh config)
if "WEZTERM_PANE" in $env and $env.WEZTERM_PANE == "0" {
    if "MACCHINA_THEME" in $env {
        (macchina --theme $env.MACCHINA_THEME)
    } else {
        (macchina --theme nix)
    }
}