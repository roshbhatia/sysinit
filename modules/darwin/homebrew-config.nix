{ pkgs, lib, config, enableHomebrew ? true, username, ... }:

{
  # Homebrew packages configuration (standard nix-darwin module)
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
      # No jordanbaird-ice formula available
      "tfenv"
      "zsh"
    ];
    
    casks = [
      "1password-cli"
      "discord"
      # Docker conflicts with rancher
      "firefox"
      "font-hack-nerd-font"
      "font-symbols-only-nerd-font"
      "aerospace"
      "obsidian"
      "slack"
      "visual-studio-code@insiders"
      "wezterm"
    ];
  };
}