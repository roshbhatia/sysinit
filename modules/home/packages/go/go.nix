{
  lib,
  overlay,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.goPackages = activation.mkPackageManager {
    name = "go";
    basePackages = [ ];
    additionalPackages = (overlay.go.additionalPackages or [ ]);
    executableArguments = [ "install" ];
    executableName = "go";
  };
}
