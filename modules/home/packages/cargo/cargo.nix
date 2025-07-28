{
  lib,
  values,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.cargoPackages = activation.mkPackageManager {
    name = "cargo";
    basePackages = [
      "tree-sitter-cli"
    ];
    additionalPackages = (values.cargo.additionalPackages or [ ]);
    executableArguments = [
      "install"
      "--locked"
    ];
    executableName = "cargo";
  };

  # eza requires a vendored version of libgit2 in order to work properly
  home.activation.eza = activation.mkPackageManager {
    name = "cargo";
    basePackages = [
      "eza"
    ];
    additionalPackages = [ ];
    executableArguments = [
      "install"
      "--locked"
      "--features"
      "vendored-libgit2"
    ];
    executableName = "cargo";
  };
}
