# Nushell Consolidated Config File
# version = 0.82.0

# ------------------------------
# Environment Configuration
# ------------------------------
# Set the default environment variables
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.SHELL = "nu"
$env.HOME = $nu.home-path

# Path adjustments
$env.PATH = (
    $env.PATH 
    | split row (char esep) 
    | prepend [
        $"($env.HOME)/.cargo/bin"
        $"($env.HOME)/.yarn/bin"
        $"($env.HOME)/.config/yarn/global/node_modules/.bin"
        "/usr/local/opt/cython/bin"
        $"($env.HOME)/.local/bin"
        $"($env.HOME)/.rvm/bin"
        $"($env.HOME)/.govm/shim"
        $"($env.HOME)/.krew/bin"
        $"($env.HOME)/bin"
    ]
)

# Homebrew
if (which brew | length) > 0 {
    let brew_path = (brew --prefix | str trim)
    # Add Homebrew paths
    $env.PATH = (
        $env.PATH 
        | split row (char esep) 
        | prepend [
            $"($brew_path)/bin" 
            $"($brew_path)/sbin"
        ]
    )
}

$env.config = {
    show_banner: false
}

$env.FZF_DEFAULT_OPTS = "--height 8 --layout=reverse --border --inline-info"

# ------------------------------
# Shell Configuration
# ------------------------------

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

# ------------------------------
# Devenv Integration
# ------------------------------

# Store our active environment info
$env.DEVENV_ACTIVE_PATH = ""
$env.DEVENV_NIX_SHELL = false

# Define the hook to run when changing directories
def create_left_prompt [] {
    # Get environment variables like PWD and DEVENV_ACTIVE_PATH
    let pwd = ($env.PWD | str replace $env.HOME "~")
    
    # Call our devenv check hook
    check_devenv_shell $pwd
    
    # Generate prompt display
    if ($env.DEVENV_NIX_SHELL) {
        # Show special prompt when in a devenv environment
        $"(ansi green)nix-shell(ansi reset):(ansi cyan)($pwd)(ansi reset)> "
    } else {
        # Regular prompt
        $"(ansi cyan)($pwd)(ansi reset)> "
    }
}

# Function to check for devenv.shell.nix files
def check_devenv_shell [pwd: string] {
    # Check if we already have an active environment
    let active_path = ($env | get -i DEVENV_ACTIVE_PATH | default "")
    
    # If active_path is set, check if current path is a subfolder
    if ($active_path != "") and ($pwd | str starts-with $active_path) {
        # We're in a subfolder of an active environment, keep it active
        return
    }
    
    # Check if we moved to a parent directory of an active environment
    if ($active_path != "") and ($active_path | str starts-with $pwd) {
        # We moved up out of an active environment
        print $"(ansi yellow)Exiting devenv.nix.shell environment from ($active_path)(ansi reset)"
        $env.DEVENV_ACTIVE_PATH = ""
        $env.DEVENV_NIX_SHELL = false
        return
    }
    
    # Check if the current directory has a devenv.shell.nix file
    if (ls | where name == "devenv.shell.nix" | length) > 0 {
        # If we're not already in a devenv shell, activate it
        # If DEVENV_NIX_SHELL is true, we're already in a shell and should do nothing
    } else {
        # No devenv.shell.nix in current directory, and not a parent of active environment
        # (parent case is handled above)
        if ($active_path != "") {
            # We had an active path but moved to an unrelated directory
            print $"(ansi yellow)Exiting devenv.nix.shell environment from ($active_path)(ansi reset)"
            $env.DEVENV_ACTIVE_PATH = ""
            $env.DEVENV_NIX_SHELL = false
        }
    }
}

# Set up the hook to activate on directory change
$env.config = ($env.config | upsert hooks {
    env_change: {
        PWD: {
            let pwd = $env.PWD
            check_devenv_shell $pwd
        }
    }
})

# Set up the prompt to show active status
$env.PROMPT_COMMAND = {|| create_left_prompt }

print "✅ Loaded nushell configuration with devenv.nix.shell integration"