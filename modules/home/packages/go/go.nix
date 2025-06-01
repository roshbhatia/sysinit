{
  lib,
  userConfig ? { },
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.goPackages = activation.mkPackageManager {
    name = "go";
    basePackages = [ ];
    additionalPackages = (userConfig.go.additionalPackages or [ ]);
    executableArguments = [ "install" ];
    executableName = "go";
  };
}
