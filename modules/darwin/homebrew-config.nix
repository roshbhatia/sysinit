{ pkgs, lib, config, enableHomebrew ? true, username, ... }:

{
  # Homebrew packages configuration (standard nix-darwin module)
  homebrew = {
    enable = enableHomebrew;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
      # Explicitly run install on activation
      install = true;
    };
    global = {
      brewfile = true;
      # Auto-update Brewfile
      autoUpdate = true;
    };
    
    taps = [
      "homebrew/bundle"
      "homebrew/cask-fonts"
      "homebrew/cask"
      "homebrew/core"
      "homebrew/services"
      "noahgorstein/tap"
      "nikitabobko/tap"
      "FelixKratz/formulae"
    ];
    
    brews = [
      "jordanbaird-ice"
      "tfenv"
      "zsh"
      "borders"
    ];
    
    casks = [
      "1password-cli"
      "discord"
      "firefox"
      "font-hack-nerd-font"
      "font-symbols-only-nerd-font"
      "rectangle"
      "obsidian"
      "slack"
      "visual-studio-code@insiders"
      "wezterm"
    ];
    
    # Make Homebrew install packages directly in darwin-rebuild
    masApps = {};
  };
}