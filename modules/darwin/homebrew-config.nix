{ pkgs, lib, config, enableHomebrew ? true, username, userConfig ? {}, ... }:

let
  # Get additional homebrew packages from userConfig or use empty lists if not defined
  additionalTaps = if userConfig ? homebrew && userConfig.homebrew ? additionalPackages && userConfig.homebrew.additionalPackages ? taps 
                  then userConfig.homebrew.additionalPackages.taps 
                  else [];
                  
  additionalBrews = if userConfig ? homebrew && userConfig.homebrew ? additionalPackages && userConfig.homebrew.additionalPackages ? brews 
                   then userConfig.homebrew.additionalPackages.brews 
                   else [];
                   
  additionalCasks = if userConfig ? homebrew && userConfig.homebrew ? additionalPackages && userConfig.homebrew.additionalPackages ? casks 
                   then userConfig.homebrew.additionalPackages.casks 
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
