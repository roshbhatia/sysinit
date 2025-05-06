{ pkgs, lib, config, userConfig ? {}, ... }:

let
  packageManager = import ../../../../lib/package-manager.nix { inherit lib; };
in packageManager.mkPackageManager {
  name = "cargo";
  basePackages = [
    "cargo-watch"
    "stylua"
  ];
  additionalPackages = if userConfig ? cargo && userConfig.cargo ? additionalPackages
    then userConfig.cargo.additionalPackages
    else [];
  installCommand = ''
    "$CARGO" install "$package" -f
  '';
  executablePath = "/opt/homebrew/bin/cargo";
}
