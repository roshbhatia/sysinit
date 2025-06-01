{
  lib,
  userConfig ? { },
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
    additionalPackages =
      if userConfig ? npm && userConfig.npm ? additionalPackages then
        userConfig.npm.additionalPackages
      else
        [ ];
    executableArguments = [
      "install"
      "-g"
    ];
    executableName = "npm";
  };
}

