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
  };
  
  # Add activation script to force Homebrew to install packages
  system.activationScripts.extraActivation.text = ''
    echo "Running additional homebrew installations..."
    if [ -f /opt/homebrew/bin/brew ]; then
      PATH=$PATH:/opt/homebrew/bin
      # Force brew to install packages listed above
      brew bundle --file=/dev/stdin <<EOF
      ${lib.concatStrings (map (tap: "tap \"${tap}\"\n") config.homebrew.taps)}
      ${lib.concatStrings (map (brew: "brew \"${brew}\"\n") config.homebrew.brews)}
      ${lib.concatStrings (map (cask: "cask \"${cask}\"\n") config.homebrew.casks)}
      EOF
    fi
  '';
}