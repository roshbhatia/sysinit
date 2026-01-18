# Darwin packages: Homebrew
{ values, ... }:

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
    "osx-cross/arm"
    "osx-cross/avr"
    "sandreas/tap"
    "slp/krunkit"
    "vet-run/vet"
  ];

  baseBrews = [
    "bashdb"
    "bcrypt"
    "block-goose-cli"
    "colima"
    "ctags"
    "hashicorp/tap/terraform"
    "libgit2@1.8"
    "luarocks"
    "lunchy"
    "ollama"
    "osx-cross/arm/arm-none-eabi-binutils"
    "osx-cross/arm/arm-none-eabi-gcc@8"
    "slp/krunkit/krunkit"
    "vet-run"
  ];

  baseCasks = [
    "1password"
    "1password-cli"
    "firefox"
    "font-symbols-only-nerd-font"
    "hammerspoon"
    "handy"
    "mediosz/tap/swipeaerospace"
    "raycast"
    "slack"
  ];
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
      cleanup = "uninstall";
    };
    global = {
      brewfile = true;
      lockfiles = true;
      autoUpdate = true;
    };
    taps = baseTaps ++ additionalTaps;
    brews = baseBrews ++ additionalBrews;
    casks = baseCasks ++ additionalCasks;
  };
}
