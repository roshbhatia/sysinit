{
  config,
  lib,
  pkgs,
  ...
}:
let
  paths = import ../shared/codesign.nix;
  user = config.sysinit.user.username;
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

  # Runs last, after nix-darwin has rewritten /Applications/Nix Apps from the
  # store and dropped whatever signature was on it.
  system.activationScripts.postActivation.text = ''
    ${lib.getExe config.home-manager.users.${user}.sysinit.codesign.package} system || true
  '';
}
