{ config, ... }:

let
  additionalTaps = config.sysinit.darwin.homebrew.additionalPackages.taps;
  additionalBrews = config.sysinit.darwin.homebrew.additionalPackages.brews;
  additionalCasks = config.sysinit.darwin.homebrew.additionalPackages.casks;

  baseTaps = [
    "charmbracelet/tap"
    "jakehilborn/jakehilborn"
    "noahgorstein/tap"
    "osx-cross/arm"
    "osx-cross/avr"
    "sandreas/tap"
    "slp/krunkit"
    "steipete/tap"
  ];

  baseBrews = [
    "bashdb"
    "bcrypt"
    "ctags"
    "libgit2@1.8"
    "luarocks"
    "lunchy"
    "ollama"
    "osx-cross/arm/arm-none-eabi-binutils"
    "osx-cross/arm/arm-none-eabi-gcc@8"
    # krunkit pulls both of these from the same untrusted tap. brew bundle
    # rewrites ~/.homebrew/trust.json to exactly the tap-qualified formulae the
    # Brewfile names, so a dependency trusted by hand is dropped on the next
    # switch and activation fails again. Naming them here is what makes the
    # trust survive.
    "slp/krunkit/krunkit"
    "slp/krunkit/libkrun-efi"
    "slp/krunkit/virglrenderer"
    "steipete/tap/peekaboo"
    "switchaudio-osx"
  ];

  baseCasks = [
    "1password"
    "1password-cli"
    "firefox"
    "font-sf-mono-nerd-font-ligaturized"
    "font-symbols-only-nerd-font"
    "hammerspoon"
    "slack"
  ];
in
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
    };
    global = {
      brewfile = true;
      autoUpdate = false;
    };
    taps = baseTaps ++ additionalTaps;
    brews = baseBrews ++ additionalBrews;
    casks = baseCasks ++ additionalCasks;
  };
}
