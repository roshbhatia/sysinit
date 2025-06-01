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
    additionalPackages = (userConfig.cargo.additionalPackages or [ ]);
    executableArguments = [
      "install"
      "--locked"
    ];
    executableName = "cargo";
  };
}
