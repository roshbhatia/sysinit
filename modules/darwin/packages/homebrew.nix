{
  values,
  lib,
  config,
  ...
}:

let
  additionalTaps = (values.darwin.homebrew.additionalPackages.taps or [ ]);
  additionalBrews = (values.darwin.homebrew.additionalPackages.brews or [ ]);
  additionalCasks = (values.darwin.homebrew.additionalPackages.casks or [ ]);

  baseTaps = [
    "charmbracelet/tap"
    "hashicorp/tap"
    "jakehilborn/jakehilborn"
    "mediosz/tap"
    "noahgorstein/tap"
    "sandreas/tap"
  ];

  baseBrews = [
    "bcrypt"
    "charmbracelet/tap/crush"
    "eza"
    "hashicorp/tap/terraform"
    "libgit2@1.8"
    "luarocks"
  ];

  baseCasks = [
    "firefox"
    "font-symbols-only-nerd-font"
    "hammerspoon"
    "jordanbaird-ice"
    "keycastr"
    "mediosz/tap/swipeaerospace"
    "slack"
    "visual-studio-code@insiders"
    "wezterm"
  ];

  allTaps = baseTaps ++ additionalTaps;
  allBrews = baseBrews ++ additionalBrews;
  allCasks = baseCasks ++ additionalCasks;
in
{
  environment.variables = {
    HOMEBREW_NO_ENV_HINTS = "1";
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = values.user.username;
    autoMigrate = true;
    mutableTaps = true;
  };

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
      autoUpdate = true;
    };

    taps = allTaps;
    brews = allBrews;
    casks = allCasks;
  };
}
