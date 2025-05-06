{ pkgs, lib, config, userConfig ? {}, ... }:

let
  packageManager = import ../../lib/package-manager.nix { inherit lib; };
in packageManager.mkPackageManager {
  name = "uv";
  basePackages = [ "uv" ];
  additionalPackages = [];
  executableArguments = [ "install" "--force" ];
  executablePath = "/opt/homebrew/bin/pipx";
}
