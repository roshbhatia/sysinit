{
  lib,
  userConfig ? { },
  ...
}:

let
  activationUtils = import ../../../../lib/activation/utils.nix { inherit lib; };
in
{
  home.activation.cargoPackages = activationUtils.mkPackageManager {
    name = "cargo";
    basePackages = [
      "cargo-watch"
      "eza"
      "stylua"
      "tree-sitter-cli"
    ];
    additionalPackages =
      if userConfig ? cargo && userConfig.cargo ? additionalPackages then
        userConfig.cargo.additionalPackages
      else
        [ ];
    executableArguments = [
      "install"
      "--locked"
    ];
    executableName = "cargo";
  };
}
