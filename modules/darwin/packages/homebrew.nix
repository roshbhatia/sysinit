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
    "FelixKratz/formulae"
    "hashicorp/tap"
    "jakehilborn/jakehilborn"
    "nikitabobko/tap"
    "noahgorstein/tap"
    "sandreas/tap"
    "vet-run/vet"
  ];

  baseBrews = [
    "borders"
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
    "raycast"
    "nikitabobko/tap/aerospace"
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

