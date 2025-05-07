{ pkgs, lib, config, userConfig ? {}, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in activationUtils.mkPackageManager {
  name = "uvx";
  basePackages = [ "skydeckai-code" ];
  additionalPackages = if userConfig ? uvx && userConfig.uvx ? additionalPackages
    then userConfig.uvx.additionalPackages
    else [];
  executableArguments = [];
  executablePath = "uvx";  # Using PATH now instead of hardcoded path
  skipIfMissing = true;    # Skip if uvx is not installed
}
