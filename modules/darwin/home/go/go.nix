{
  lib,
  userConfig ? { },
  ...
}:

let
  activationUtils = import ../../../lib/activation/utils.nix { inherit lib; };
in
{
  home.activation.goPackages = activationUtils.mkPackageManager {
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
