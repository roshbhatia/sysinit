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
    additionalPackages =
      if userConfig ? go && userConfig.go ? additionalPackages then
        userConfig.go.additionalPackages
      else
        [ ];
    executableArguments = [ "install" ];
    executableName = "go";
  };
}

