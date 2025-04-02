{ pkgs, lib, config, enableHomebrew ? true, username, inputs, userConfig ? {}, ... }:

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
    "ansible"
    "borders"
    "caddy"
    "colima"
    "direnv"
    "eza"
    "fd"
    "glow"
    "gum"
    "helm"
    "kubectl"
    "kubecolor"
    "libgit2"
    "nushell"
    "pipx"
    "python@3.11"
    "ripgrep"
    "socat"
    "sshpass"
    "tailscale"
    "yazi"
  ];
  
  baseCasks = [
    "1password-cli"
    "discord"
    "firefox"
    "font-hack-nerd-font"
    "font-symbols-only-nerd-font"
    "jordanbaird-ice"
    "nikitabobko/tap/aerospace"
    "obsidian"
    "slack"
    "visual-studio-code@insiders"
    "vnc-viewer"
    "wezterm"
  ];
  
  # Combine base and additional packages
  allTaps = baseTaps ++ additionalTaps;
  allBrews = baseBrews ++ additionalBrews;
  allCasks = baseCasks ++ additionalCasks;
in
{
  # nix-homebrew configuration to manage the Homebrew installation itself
  nix-homebrew = {
    enable = enableHomebrew;
    enableRosetta = true;
    user = username;
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = true;
  };

  # Homebrew packages configuration
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