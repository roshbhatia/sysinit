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
    basePackages = [
      "dlvhdr/gh-dash"
    ];
    additionalPackages =
      if overlay ? gh && overlay.gh ? additionalPackages then overlay.gh.additionalPackages else [ ];
    executableArguments = [
      "extension"
      "install"
    ];
    executableName = "gh";
  };
}
