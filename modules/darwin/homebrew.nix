{ config, ... }:

let
  additionalTaps = config.sysinit.darwin.homebrew.additionalPackages.taps;
  additionalBrews = config.sysinit.darwin.homebrew.additionalPackages.brews;
  additionalCasks = config.sysinit.darwin.homebrew.additionalPackages.casks;

  baseTaps = [
    "charmbracelet/tap"
    "hashicorp/tap"
    "jakehilborn/jakehilborn"
    "noahgorstein/tap"
    "osx-cross/arm"
    "osx-cross/avr"
    "sandreas/tap"
    "slp/krunkit"
  ];

  baseBrews = [
    "bashdb"
    "bcrypt"
    "ctags"
    "hashicorp/tap/terraform"
    "libgit2@1.8"
    "luarocks"
    "lunchy"
    "ollama"
    "osx-cross/arm/arm-none-eabi-binutils"
    "osx-cross/arm/arm-none-eabi-gcc@8"
    "slp/krunkit/krunkit"
  ];

  baseCasks = [
    "1password"
    "1password-cli"
    "firefox"
    "font-sf-mono-nerd-font-ligaturized"
    "font-sf-mono-nerd-font-ligaturized"
    "font-symbols-only-nerd-font"
    "ghostty"
    "hammerspoon"
    "handy"
    "raycast"
    "slack"
  ];
in
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    global = {
      brewfile = true;
      autoUpdate = true;
    };
    taps = baseTaps ++ additionalTaps;
    brews = baseBrews ++ additionalBrews;
    casks = baseCasks ++ additionalCasks;
  };
}
