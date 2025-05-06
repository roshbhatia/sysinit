{ pkgs, lib, config, userConfig ? {}, ... }:

let
  packageManager = import ../../../../modules/lib/package-manager.nix { inherit lib; };
in packageManager.mkPackageManager {
  name = "pipx";
  basePackages = [
    "black"
    "hererocks"
    "yamllint"
  ];
  additionalPackages = if userConfig ? pipx && userConfig.pipx ? additionalPackages
    then userConfig.pipx.additionalPackages
    else [];
  executableArguments = [ "install" "--force" ];
  executablePath = "/opt/homebrew/bin/pipx";
}
