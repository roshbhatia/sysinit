{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Helper to write a file from a string
  writeText = pkgs.writeText;
  # Modular Nushell config pieces
  envNu = ''
    # Environment variables and path setup
    $env.PATH = ($env.PATH | split row ":" | prepend ["/usr/local/bin" "/opt/homebrew/bin"]) | uniq | str join ":"
    $env.EDITOR = "nvim"
    $env.LANG = "en_US.UTF-8"
    $env.LC_ALL = "en_US.UTF-8"
    $env.TERM = "xterm-256color"
    $env.COLORTERM = "truecolor"
    $env.PAGER = "less"
    $env.BAT_THEME = "Catppuccin-Macchiato"
    $env.ATUIN_NOBIND = "true"
    $env.ATUIN_SESSION = (random uuid)
    $env.ATUIN_LOG = "/tmp/atuin.log"
    $env.ATUIN_HISTORY = "/Users/rosh/.local/share/atuin/history.db"
    $env.ATUIN_KEY = "/Users/rosh/.local/share/atuin/key"
    $env.ATUIN_CONFIG = "/Users/rosh/.config/atuin/config.toml"
    $env.BAT_CONFIG_PATH = "/Users/rosh/.config/bat/config"
    $env.BAT_THEME = "Catppuccin-Macchiato"
    $env.MACCHINA_CONFIG = "/Users/rosh/.config/macchina/macchina.toml"
    $env.K9S_SKIN = "catppuccin"
    $env.K9S_CONFIG = "/Users/rosh/.config/k9s/config.yaml"
    $env.K9S_SKINS_DIR = "/Users/rosh/.config/k9s/skins"
    $env.FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
    $env.FZF_DEFAULT_COMMAND = "fd --type f"
    $env.FZF_CTRL_T_COMMAND = "fd --type f"
    $env.FZF_ALT_C_COMMAND = "fd --type d"
    $env.FZF_COMPLETION_TRIGGER = ":"
    $env.FZF_TMUX = "1"
    $env.FZF_TMUX_OPTS = "-p 80%,60%"
    $env.FZF_PREVIEW_OPTS = "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
    $env.FZF_DEFAULT_OPTS = "--color=16 --preview-window=right:60%:wrap"
    $env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"
    $env.FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git"
    $env.FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git"
    $env.FZF_COMPLETION_TRIGGER = ":"
    $env.FZF_TMUX = "1"
    $env.FZF_TMUX_OPTS = "-p 80%,60%"
    $env.FZF_PREVIEW_OPTS = "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
    $env.FZF_DEFAULT_OPTS = "--color=16 --preview-window=right:60%:wrap"
    $env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"
    $env.FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git"
    $env.FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git"
    $env.FZF_COMPLETION_TRIGGER = ":"
    $env.FZF_TMUX = "1"
    $env.FZF_TMUX_OPTS = "-p 80%,60%"
    $env.FZF_PREVIEW_OPTS = "--preview 'bat --style=numbers --color=always --line-range :500 {}'"
  '';

  aliasesNu = ''
    alias ll = ls -l
    alias la = ls -a
    alias lla = ls -la
    alias g = git
    alias v = nvim
    alias k = kubectl
    alias tf = terraform
    alias cat = bat
    alias grep = rg
    alias f = fzf
    alias d = docker
    alias dc = docker compose
    alias h = helm
    alias t = task
    alias .. = cd ..
    alias ... = cd ../..
    alias .... = cd ../../..
    alias ..... = cd ../../../..
  '';

  pluginsNu = ''
    # Example: load a plugin from the Nix store
    # Use Nix to install plugins and point to them here
    # plugin add /nix/store/xxxx-nushell_plugin_xxx.so
  '';

  promptNu = ''
    # Minimal prompt example
    let-env PROMPT_INDICATOR = "❯ "
    let-env PROMPT_MULTILINE_INDICATOR = "⋮ "
    let-env PROMPT_COMMAND = { || $env.PROMPT_INDICATOR }
  '';

  configNu = ''
    # Nushell config.nu - sources modular files
    source ~/.config/nushell/env.nu
    source ~/.config/nushell/aliases.nu
    source ~/.config/nushell/plugins.nu
    source ~/.config/nushell/prompt.nu
    # Add more config here as needed
  '';

in
{
  home.file = {
    ".config/nushell/env.nu".text = envNu;
    ".config/nushell/aliases.nu".text = aliasesNu;
    ".config/nushell/plugins.nu".text = pluginsNu;
    ".config/nushell/prompt.nu".text = promptNu;
    ".config/nushell/config.nu".text = configNu;
  };
}
