$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.SHELL = "nu"
$env.HOME = $nu.home-path

$env.PATH = (
    $env.PATH
    | split row (char esep)
    | prepend [
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
)

if (which brew | length) > 0 {
    let brew_path = (brew --prefix | str trim)
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

alias ... = cd ../..
alias .. = cd ..
alias ~ = cd ~

alias tf = terraform

if (which code-insiders | length) > 0 {
    alias code = code-insiders
}

if (which kubecolor | length) > 0 {
    alias kubectl = kubecolor
    alias k = kubectl
}

if (which eza | length) > 0 {
    alias ls = eza
    alias l = eza --icons=always -1
    alias ll = eza --icons=always -1 -a
    alias lt = eza --icons=always -1 -a -T
}

if (which yazi | length) > 0 {
    alias y = yazi
}

def nuopen [arg, --raw (-r)] { if $raw { open -r $arg } else { open $arg } }
def nuhelp [] { help commands | sort-by name | grid -c }

macchina --theme nix


$env.DEVENV_ACTIVE_PATH = ""
$env.DEVENV_NIX_SHELL = false

def create_left_prompt [] {
    let pwd = ($env.PWD | str replace $env.HOME "~")

    check_devenv_shell $pwd

    if ($env.DEVENV_NIX_SHELL) {
        $"(ansi green)nix-shell(ansi reset):(ansi cyan)($pwd)(ansi reset)> "
    } else {
        $"(ansi cyan)($pwd)(ansi reset)> "
    }
}

def check_devenv_shell [pwd: string] {
    let active_path = ($env | get -i DEVENV_ACTIVE_PATH | default "")

    if ($active_path != "") and ($pwd | str starts-with $active_path) {
        return
    }

    if ($active_path != "") and ($active_path | str starts-with $pwd) {
        print $"(ansi yellow)Exiting devenv.nix.shell environment from ($active_path)(ansi reset)"
        $env.DEVENV_ACTIVE_PATH = ""
        $env.DEVENV_NIX_SHELL = false
        return
    }

    if (ls | where name == "devenv.shell.nix" | length) > 0 {
    } else {
        if ($active_path != "") {
            print $"(ansi yellow)Exiting devenv.nix.shell environment from ($active_path)(ansi reset)"
            $env.DEVENV_ACTIVE_PATH = ""
            $env.DEVENV_NIX_SHELL = false
        }
    }
}

$env.config = ($env.config | upsert hooks {
    env_change: {
        PWD: [
            "let pwd = $env.PWD; check_devenv_shell $pwd"
        ]
    }
})

$env.PROMPT_COMMAND = {|| create_left_prompt }

print "✅ Loaded nushell configuration with devenv.nix.shell integration"

