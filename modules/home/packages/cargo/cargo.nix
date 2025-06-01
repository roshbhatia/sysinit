{
  lib,
  userConfig ? { },
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.cargoPackages = activation.mkPackageManager {
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
