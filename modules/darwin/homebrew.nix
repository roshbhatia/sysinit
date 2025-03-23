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
    
    # ZSH completions and plugins still managed by homebrew
    brews = [
      "jordanbaird-ice"
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
      "obsidian"
      "postman"
      "slack"
      "visual-studio-code-insiders"
      "wezterm"
    ];
  };
}