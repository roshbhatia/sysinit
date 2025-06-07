{
  lib,
  overlay,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.ghPackages = activation.mkPackageManager {
    name = "gh";
    basePackages = [ ];
    additionalPackages = (overlay.gh.additionalPackages or [ ]);
    executableArguments = [
      "extension"
      "install"
    ];
    executableName = "gh";
  };
}
