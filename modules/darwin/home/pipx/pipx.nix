{ pkgs, lib, config, userConfig ? {}, ... }:

let
  packageManager = import ../../lib/package-manager.nix { inherit lib; };
in packageManager.mkPackageManager {
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
  installCommand = '"$PIPX" install "$package" --force';
  executablePath = "/opt/homebrew/bin/pipx";
}
