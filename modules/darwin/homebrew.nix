{ pkgs, lib, config, enableHomebrew ? true, ... }:

{
  # Homebrew configuration with optional enabling
  homebrew = {
    enable = enableHomebrew;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    global = {
      brewfile = true;
    };
    
    taps = [
      "homebrew/bundle"
      "homebrew/cask-fonts"
      "homebrew/cask"
      "homebrew/core"
      "homebrew/services"
      "noahgorstein/tap"
      "nikitabobko/tap"
    ];
    
    brews = [
      "atuin"
      "awscli"
      "bat"
      "colima"
      "coreutils"
      "direnv"
      "eza"
      "fd"
      "ffmpeg"
      "fzf"
      "gh"
      "go"
      "grep"
      "helm"
      "htop"
      "imagemagick"
      "jordanbaird-ice"
      "jq"
      "jqp"
      "k9s"
      "kind"
      "kubecolor"
      "kustomize"
      "neovim"
      "poppler"
      "ripgrep"
      "sevenzip"
      "starship"
      "stern"
      "tfenv"
      "tmux"
      "tree"
      "watch"
      "wget"
      "yazi"
      "yq"
      "zoxide"
      "zsh-autocomplete"
      "zsh-autosuggestions"
      "zsh-history-substring-search"
      "zsh-syntax-highlighting"
      "zsh"
    ];
    
    casks = [
      "1password-cli"
      "discord"
      "docker"
      "firefox"
      "font-hack-nerd-font"
      "font-symbols-only-nerd-font"
      "aerospace"
      "obsidian"
      "postman"
      "slack"
      "visual-studio-code-insiders"
      "wezterm"
    ];
  };
}