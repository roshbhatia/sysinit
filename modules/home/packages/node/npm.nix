{
  lib,
  overlay,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.file.".npmrc" = {
    text = ''
      prefix = ''\${HOME}/.local/share/.npm-packages
    '';
  };

  home.activation.npmPackages = activation.mkPackageManager {
    name = "npm";
    basePackages = [
      "yarn"
    ];
    additionalPackages = (overlay.npm.additionalPackages or [ ]);
    executableArguments = [
      "install"
      "-g"
    ];
    executableName = "npm";
  };
}
