{ pkgs, lib, config, ... }:

let
  # Check for no-homebrew argument
  homebrewArg = builtins.getEnv "SYSINIT_NO_HOMEBREW";
  skipHomebrew = homebrewArg == "1";
in
{
  # If SYSINIT_NO_HOMEBREW is set to 1, disable Homebrew to skip installation
  homebrew = {
    enable = !skipHomebrew;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    global = {
      brewfile = true;
    };
    
    taps = [
      "homebrew/core"
      "homebrew/bundle"
      "homebrew/cask"
      "homebrew/services"
      "homebrew/cask-fonts"
      "noahgorstein/tap"
    ];
    
    brews = [
      "jordanbaird-ice"
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
      "zsh"
      "zsh-autocomplete"
      "zsh-autosuggestions"
      "zsh-history-substring-search"
      "zsh-syntax-highlighting"
    ];
    
    casks = [
      "wezterm"
      "font-hack-nerd-font"
      "font-symbols-only-nerd-font"
      "docker"
      "postman"
      "firefox"
      "slack"
      "rectangle"
      "1password-cli"
      "visual-studio-code-insiders"
      "obsidian"
      "notion"
      "tailscale"
      "the-unarchiver"
      "transmission"
      "soulseek"
      "discord"
    ];
  };
}