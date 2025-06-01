{
  lib,
  userConfig ? { },
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
      "github/gh-copilot"
    ];
    additionalPackages =
      if userConfig ? gh && userConfig.gh ? additionalPackages then
        userConfig.gh.additionalPackages
      else
        [ ];
    executableArguments = [
      "extension"
      "install"
    ];
    executableName = "gh";
  };
}
