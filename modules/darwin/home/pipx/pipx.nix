{ pkgs, lib, config, userConfig ? {}, ... }:

let
  packageManager = import ../../../../lib/package-manager.nix { inherit lib; };
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
  installCommand = ''
    "$EXECUTABLE" install "$package" --force
  '';
  executablePath = "/opt/homebrew/bin/pipx";
}
