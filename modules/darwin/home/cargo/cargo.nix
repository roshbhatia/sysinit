{ pkgs, lib, config, userConfig ? {}, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in {
  home.activation.cargoPackages = activationUtils.mkPackageManager {
    name = "cargo";
    basePackages = [
      "cargo-watch"
      "stylua"
    ];
    additionalPackages = if userConfig ? cargo && userConfig.cargo ? additionalPackages
      then userConfig.cargo.additionalPackages
      else [];
    executableArguments = [ "install" "-f" ];
    executablePath = "cargo";  # Use PATH instead of hardcoded path
  };
}
