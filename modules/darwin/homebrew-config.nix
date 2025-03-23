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
      lockfiles = true;
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
      "borders"
      "direnv"
      "libgit2"
      "eza"
      "fd"
      "yazi"
    ];
    
    casks = [
      "1password-cli"
      "discord"
      "firefox"
      "font-hack-nerd-font"
      "font-symbols-only-nerd-font"
      "jordanbaird-ice"
      "obsidian"
      "rectangle"
      "slack"
      "visual-studio-code@insiders"
      "wezterm"
    ];
  };
}
