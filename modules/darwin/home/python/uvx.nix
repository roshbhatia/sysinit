{ pkgs, lib, config, userConfig ? {}, ... }:

let
  packageManager = import ../../../lib/package-manager.nix { inherit lib; };
in packageManager.mkPackageManager {
  name = "uvx";
  basePackages = [ "skydeckai-code" ];
  additionalPackages = [];
  executableArguments = [];
  executablePath = "$HOME/.local/bin/uvx";
}
