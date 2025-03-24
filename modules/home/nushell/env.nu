# Nushell Environment Config File
# version = 0.82.0

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

# Set starship for nushell if available
if (which starship | length) > 0 {
    $env.config = {
        # Use starship prompt if available
        prompt = { starship prompt | str trim }
    }
} else {
    # Fallback to our own custom prompt
    $env.config = {
        prompt = "create_left_prompt"
    }
}

# Set up FZF default options
$env.FZF_DEFAULT_OPTS = "--height 8 --layout=reverse --border --inline-info"