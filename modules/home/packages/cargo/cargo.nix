{
  lib,
  overlay,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.cargoPackages = activation.mkPackageManager {
    name = "cargo";
    basePackages = [
      "eza"
      "tree-sitter-cli"
    ];
    additionalPackages = (overlay.cargo.additionalPackages or [ ]);
    executableArguments = [
      "install"
      "--locked"
      "--features"
      "vendored-libgit2"
    ];
    executableName = "cargo";
  };
}

