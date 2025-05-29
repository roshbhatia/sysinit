{
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
    "jandedobbeleer/oh-my-posh"
    "mediosz/tap"
    "nikitabobko/tap"
    "noahgorstein/tap"
    "sandreas/tap"
  ];

  baseBrews = [
    "borders"
    "bcrypt"
    "block-goose-cli"
    "direnv"
    "font-fira-code"
    "font-hack-nerd-font"
    "helm"
    "imagemagick"
    "jandedobbeleer/oh-my-posh/oh-my-posh"
    "krew"
    "libgit2@1.8"
    "luarocks"
    "peterldowns/tap/nix-search-cli"
    "pipx"
    "python"
    "python@3.11"
    "pngpaste"
    "rust"
    "sshpass"
  ];

  baseCasks = [
    "1password-cli"
    "alt-tab"
    "firefox"
    "hammerspoon"
    "keycastr"
    "loop"
    "obsidian"
    "raycast"
    "slack"
    "visual-studio-code@insiders"
    "wezterm@nightly"
  ];

  allTaps = baseTaps ++ additionalTaps;
  allBrews = baseBrews ++ additionalBrews;
  allCasks = baseCasks ++ additionalCasks;
in
{
  nix-homebrew = {
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
