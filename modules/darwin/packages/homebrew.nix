{
  username,
  inputs,
  userConfig ? { },
  ...
}:

let
  additionalTaps = (userConfig.homebrew.additionalPackages.taps or [ ]);
  additionalBrews = (userConfig.homebrew.additionalPackages.brews or [ ]);
  additionalCasks = (userConfig.homebrew.additionalPackages.casks or [ ]);

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
    "block-goose-cli"
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
    "sad"
    "sshpass"
    "tlrc"
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
  # This actually installs homebrew
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    autoMigrate = true;
    mutableTaps = true;
  };

  # This installs packages via homebrew
  homebrew = {
    enable = true;
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
