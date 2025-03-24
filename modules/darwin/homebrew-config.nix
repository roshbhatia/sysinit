{ pkgs, lib, enableHomebrew ? true, username, config ? {}, ... }:

let
  # Get additional homebrew packages from config or use empty lists if not defined
  additionalTaps = if config ? homebrew && config.homebrew ? additionalPackages && config.homebrew.additionalPackages ? taps 
                  then config.homebrew.additionalPackages.taps 
                  else [];
                  
  additionalBrews = if config ? homebrew && config.homebrew ? additionalPackages && config.homebrew.additionalPackages ? brews 
                   then config.homebrew.additionalPackages.brews 
                   else [];
                   
  additionalCasks = if config ? homebrew && config.homebrew ? additionalPackages && config.homebrew.additionalPackages ? casks 
                   then config.homebrew.additionalPackages.casks 
                   else [];
                   
  # Base packages
  baseTaps = [
    "homebrew/bundle"
    "homebrew/cask"
    "homebrew/core"
    "homebrew/services"
    "noahgorstein/tap"
    "nikitabobko/tap"
    "FelixKratz/formulae"
  ];
  
  baseBrews = [
    "borders"
    "direnv"
    "eza"
    "fd"
    "libgit2"
    "nushell"
    "yazi"
  ];
  
  baseCasks = [
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
  
  # Combine base and additional packages
  allTaps = baseTaps ++ additionalTaps;
  allBrews = baseBrews ++ additionalBrews;
  allCasks = baseCasks ++ additionalCasks;
in
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
    
    taps = allTaps;
    brews = allBrews;
    casks = allCasks;
  };
}
