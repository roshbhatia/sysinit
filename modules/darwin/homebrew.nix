{
  config,
  lib,
  pkgs,
  ...
}:

let
  additionalTaps = config.sysinit.darwin.homebrew.additionalPackages.taps;
  additionalBrews = config.sysinit.darwin.homebrew.additionalPackages.brews;
  additionalCasks = config.sysinit.darwin.homebrew.additionalPackages.casks;

  cfg = config.homebrew;
  brewfile = pkgs.writeText "Brewfile" cfg.brewfile;
  brew = lib.concatStringsSep " " (
    [
      "/usr/bin/sudo"
      "--user=${lib.escapeShellArg cfg.user}"
      "--set-home"
      "/usr/bin/env"
      "HOMEBREW_NO_AUTO_UPDATE=1"
      ''PATH="${cfg.prefix}/bin:${lib.makeBinPath [ pkgs.mas ]}:$PATH"''
    ]
    ++ lib.mapAttrsToList (name: value: "${name}=${lib.escapeShellArg value}") cfg.onActivation.extraEnv
    ++ [ "${lib.escapeShellArg cfg.prefix}/bin/brew" ]
  );
  inventory = pkgs.sysinit.writeShellScript "homebrew-inventory" ''
    set -euo pipefail
    printf '%s\n' ${
      lib.escapeShellArgs [
        (toString brewfile)
        (toString reconcile)
      ]
    }
    ${brew} list --versions | LC_ALL=C sort
    ${brew} tap | LC_ALL=C sort
  '';
  check = pkgs.sysinit.writeShellScript "homebrew-check" ''
    set -euo pipefail
    ${brew} bundle check --file=${lib.escapeShellArg (toString brewfile)} --no-upgrade
  '';
  reconcile = pkgs.sysinit.writeShellScript "homebrew-reconcile" ''
    set -euo pipefail
    ${cfg.onActivation.brewBundleCmd { onlyCheck = false; }}
  '';
  incremental = pkgs.sysinit.writeShellApplication {
    name = "sysinit-homebrew";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./reconcile-homebrew.sh;
  };

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
  system.activationScripts.homebrew.text = lib.mkIf cfg.enable (
    lib.mkForce ''
      ${
        if cfg.onActivation.autoUpdate || cfg.onActivation.upgrade then
          toString reconcile
        else
          "${lib.getExe incremental} /var/db/sysinit/homebrew-inventory ${inventory} ${check} ${reconcile}"
      }
    ''
  );

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
