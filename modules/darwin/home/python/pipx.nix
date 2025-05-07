{ pkgs, lib, config, userConfig ? {}, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in {
  home.activation.pipxPackages = activationUtils.mkPackageManager {
    name = "pipx";
    basePackages = [
      "black"
      "hererocks"
      "yamllint"
      "uv"
    ];
    additionalPackages = if userConfig ? pipx && userConfig.pipx ? additionalPackages
      then userConfig.pipx.additionalPackages
      else [];
    executableArguments = [ "install" "--force" ];
    executablePath = "pipx";  # Using PATH now instead of hardcoded path
    skipIfMissing = true;     # Skip if pipx is not installed
    logFailures = false;      # Don't fail the entire activation if package install fails
  };
}
