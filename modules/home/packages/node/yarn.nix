{
  lib,
  overlay,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.file.".yarnrc" = {
    text = ''
      strict-ssl false
      yarn-offline-mirror ".local/share/yarn/packages-cache"
    '';
  };

  home.activation.yarnPackages = activation.mkPackageManager {
    name = "yarn";
    basePackages = [
      "@dice-roller/cli"
    ];
    additionalPackages = (overlay.yarn.additionalPackages or [ ]);
    executableArguments = [
      "global"
      "add"
      "--no-progress"
      "--non-interactive"
      "--silent"
    ];
    executableName = "yarn";
  };
}

