{
  values,
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
    "sst/tap"
  ];

  baseBrews = [
    "bashdb"
    "bcrypt"
    "block-goose-cli"
    "charmbracelet/tap/crush"
    "claude-squad"
    "cursor-cli"
    "eza"
    "hashicorp/tap/terraform"
    "libgit2@1.8"
    "luarocks"
    "opencode"
  ];

  baseCasks = [
    "firefox"
    "font-symbols-only-nerd-font"
    "hammerspoon"
    "keycastr"
    "mediosz/tap/swipeaerospace"
    "raycast"
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
