{ pkgs, lib, ... }: {
  # Global packages that should be installed everywhere
  homebrew.brews = [
    # CLI Tools
    "atuin"
    "awscli"
    "bat"
    "colima"
    "coreutils"
    "direnv"
    "eza"
    "ffmpeg"
    "fzf"
    "gh"
    "go"
    "grep"
    "helm"
    "htop"
    "jq"
    "k9s"
    "kind"
    "kubernetes-cli"
    "kustomize"
    "neovim"
    "starship"
    "terraform"
    "tfenv"
    "tmux"
    "tree"
    "watch"
    "wget"
    "yq"
    "zsh"
    "zsh-autosuggestions"
    "zsh-history-substring-search"
    "zsh-syntax-highlighting"
  ];

  homebrew.casks = [
    # Terminal and fonts
    "wezterm"
    "font-hack-nerd-font"
    
    # Development tools
    "visual-studio-code-insiders"
    "docker"
    "orbstack"
    "postman"
    "lens"
    
    # Browsers
    "firefox"
    
    # Communication (work-appropriate)
    "slack"
    
    # Utilities (work-appropriate)
    "rectangle"
    "alfred"
    "1password-cli"
  ];
}