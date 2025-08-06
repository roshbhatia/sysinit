{
  values,
  ...
}:

let
  additionalTaps = (values.homebrew.additionalPackages.taps or [ ]);
  additionalBrews = (values.homebrew.additionalPackages.brews or [ ]);
  additionalCasks = (values.homebrew.additionalPackages.casks or [ ]);

  baseTaps = [

    "charmbracelet/tap"
    "hashicorp/tap"
    "jakehilborn/jakehilborn"
    "noahgorstein/tap"
    "sandreas/tap"
    "vet-run/vet"
  ];

  baseBrews = [
    "bcrypt"
    "charmbracelet/tap/crush"
    "displayplacer"
    "hashicorp/tap/terraform"
    "libgit2@1.8"
    "luarocks"
    "vet-run"
  ];

  baseCasks = [
    "alt-tab"
    "firefox"
    "font-symbols-only-nerd-font"
    "jordanbaird-ice"
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
    };

    taps = allTaps;
    brews = allBrews;
    casks = allCasks;
  };
}
