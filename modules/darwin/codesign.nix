{
  config,
  lib,
  pkgs,
  ...
}:
let
  paths = import ../shared/codesign.nix;
  user = config.sysinit.user.username;
  appState = "${lib.getExe pkgs.python3} ${../home/app-copy-state.py}";
  appStateArgs = lib.escapeShellArgs [
    "${config.system.build.applications}/Applications"
    "/Applications/Nix Apps"
    "/var/db/sysinit/app-copy.json"
  ];
  signedBin = "${config.users.users.${user}.home}/${paths.signedBinDir}";

  # Keep everything the real package ships and redirect only the executable, so
  # the launchd arguments nix-darwin builds from the service options stay intact.
  # The symlink target is what macOS resolves and what TCC records, and that
  # target does not move when the package updates.
  stable =
    name: pkg:
    pkgs.symlinkJoin {
      name = "${name}-stable-path";
      paths = [ pkg ];
      postBuild = ''
        rm -f "$out/bin/${name}"
        ln -s "${signedBin}/${name}" "$out/bin/${name}"
      '';
    };
in
{
  # Both read the screen, so both hold a Screen Recording grant, and launchd
  # starts both straight out of the store. See modules/shared/codesign.nix for
  # why that costs a fresh grant on every update.
  home-manager.users.${user}.sysinit.codesign.binaries = {
    borders = "${pkgs.jankyborders}/bin/borders";
    sketchybar = "${pkgs.sketchybar}/bin/sketchybar";
  };

  services.jankyborders.package = lib.mkForce (stable "borders" pkgs.jankyborders);
  services.sketchybar.package = lib.mkForce (stable "sketchybar" pkgs.sketchybar);

  system.activationScripts.postActivation.text = ''
    SYSINIT_APPS_VALIDATED="''${sysinit_system_apps_validated:-0}" ${
      lib.getExe config.home-manager.users.${user}.sysinit.codesign.package
    } system
    if [ "''${sysinit_system_apps_validated:-0}" != 1 ]; then
      ${appState} record ${appStateArgs} || echo "sysinit: app signatures need repair" >&2
    fi
  '';

  system.activationScripts.applications.text = lib.mkMerge [
    (lib.mkBefore ''
      sysinit_system_apps_validated=0
      if ${appState} check ${appStateArgs}; then
        sysinit_system_apps_validated=1
      else
    '')
    (lib.mkAfter ''
      fi
    '')
  ];
}
