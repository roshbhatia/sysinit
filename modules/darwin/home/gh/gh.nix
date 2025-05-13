{ pkgs, lib, config, userConfig ? {}, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in {
  home.activation.ghPackages = activationUtils.mkPackageManager {
    name = "gh";
    basePackages = [
      "dlvhdr/gh-dash"
      "github/gh-copilot"
    ];
    additionalPackages = if userConfig ? gh && userConfig.gh ? additionalPackages
      then userConfig.gh.additionalPackages
      else [];
    executableArguments = [ "extension", "install" ];
    executablePath = "gh";
  };
}
