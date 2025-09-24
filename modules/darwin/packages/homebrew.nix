{
  values,
  ...
}:

let
  additionalTaps = values.darwin.homebrew.additionalPackages.taps;
  additionalBrews = values.darwin.homebrew.additionalPackages.brews;
  additionalCasks = values.darwin.homebrew.additionalPackages.casks;

  baseTaps = [
    "charmbracelet/tap"
    "hashicorp/tap"
    "jakehilborn/jakehilborn"
    "mediosz/tap"
    "noahgorstein/tap"
    "sandreas/tap"
    "sst/tap"
    "vet-run/vet"
  ];

  baseBrews = [
    "bashdb"
    "bcrypt"
    "block-goose-cli"
    "charmbracelet/tap/crush"
    "claude-squad"
    "hashicorp/tap/terraform"
    "libgit2@1.8"
    "luarocks"
    "opencode"
    "vet-run"
  ];

  baseCasks = [
    "block-goose"
    "cursor"
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
