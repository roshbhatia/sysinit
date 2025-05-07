{ pkgs, lib, config, userConfig ? {}, ... }:

let
  packageManager = import ../../../../modules/lib/package-manager.nix { inherit lib; };
in packageManager.mkPackageManager {
  name = "yarn";
  basePackages = [];
  additionalPackages = if userConfig ? yarn && userConfig.yarn ? additionalPackages
    then userConfig.yarn.additionalPackages
    else [];
  executableArguments = [ "global" "add" ];
  executablePath = "/Users/$USER/.npm-global/bin/yarn";
}
