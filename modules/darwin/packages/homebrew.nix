{
  username,
  overlay,
  ...
}:

let
  additionalTaps = (overlay.homebrew.additionalPackages.taps or [ ]);
  additionalBrews = (overlay.homebrew.additionalPackages.brews or [ ]);
  additionalCasks = (overlay.homebrew.additionalPackages.casks or [ ]);

  baseTaps = [
    "FelixKratz/formulae"
    "hashicorp/tap"
    "mediosz/tap"
    "nikitabobko/tap"
    "noahgorstein/tap"
    "sandreas/tap"
  ];

  baseBrews = [
    "borders"
    "bcrypt"
    "block-goose-cli"
    "libgit2@1.8"
    "luarocks"
  ];

  baseCasks = [
    "firefox"
    "hammerspoon"
    "keycastr"
    "loop"
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
