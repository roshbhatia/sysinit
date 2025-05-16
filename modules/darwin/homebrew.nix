{
  pkgs,
  lib,
  config,
  enableHomebrew ? true,
  username,
  inputs,
  userConfig ? { },
  ...
}:

let
  additionalTaps =
    if
      userConfig ? homebrew
      && userConfig.homebrew ? additionalPackages
      && userConfig.homebrew.additionalPackages ? taps
    then
      userConfig.homebrew.additionalPackages.taps
    else
      [ ];

  additionalBrews =
    if
      userConfig ? homebrew
      && userConfig.homebrew ? additionalPackages
      && userConfig.homebrew.additionalPackages ? brews
    then
      userConfig.homebrew.additionalPackages.brews
    else
      [ ];

  additionalCasks =
    if
      userConfig ? homebrew
      && userConfig.homebrew ? additionalPackages
      && userConfig.homebrew.additionalPackages ? casks
    then
      userConfig.homebrew.additionalPackages.casks
    else
      [ ];

  baseTaps = [
    "FelixKratz/formulae"
    "homebrew/cask"
    "homebrew/core"
    "jandedobbeleer/oh-my-posh"
    "mediosz/tap"
    "nikitabobko/tap"
    "noahgorstein/tap"
    "sandreas/tap"
  ];

  baseBrews = [
    "borders"
    "bcrypt"
    "direnv"
    "helm"
    "imagemagick"
    "jandedobbeleer/oh-my-posh/oh-my-posh"
    "krew"
    "luarocks"
    "peterldowns/tap/nix-search-cli"
    "pipx"
    "python"
    "python@3.11"
    "pngpaste"
    "rust"
    "screenresolution"
    "sshpass"
    "tailscale"
  ];

  baseCasks = [
    "1password-cli"
    "alt-tab"
    "discord"
    "firefox"
    "font-hack-nerd-font"
    "font-symbols-only-nerd-font"
    "jordanbaird-ice"
    "keycastr"
    "libgit2@1.8"
    "loop"
    "libgit2@1.8"
    "obsidian"
    "raycast"
    "slack"
    "visual-studio-code@insiders"
    "vnc-viewer"
    "wezterm"
  ];

  allTaps = baseTaps ++ additionalTaps;
  allBrews = baseBrews ++ additionalBrews;
  allCasks = baseCasks ++ additionalCasks;
in
{
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
