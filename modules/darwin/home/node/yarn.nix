{ pkgs, lib, config, userConfig ? {}, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in {
  home.activation.yarnPackages = activationUtils.mkPackageManager {
    name = "yarn";
    basePackages = [];
    additionalPackages = if userConfig ? yarn && userConfig.yarn ? additionalPackages
      then userConfig.yarn.additionalPackages
      else [];
    executableArguments = [ "global" "add" ];
    executableName = "yarn";  # Use PATH instead of hardcoded path
  };
}
