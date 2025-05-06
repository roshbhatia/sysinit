{ pkgs, lib, config, userConfig ? {}, ... }:

let
  packageManager = import ../../../../lib/package-manager.nix { inherit lib; };
in packageManager.mkPackageManager {
  name = "uv";
  basePackages = [ "uv" ];
  additionalPackages = [];
  installCommand = ''"$PIPX" install "$package" --force''; # Use single quotes for the outer string
  executablePath = "/opt/homebrew/bin/pipx";
}
