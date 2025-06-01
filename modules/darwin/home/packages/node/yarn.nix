{
  lib,
  userConfig ? { },
  ...
}:

let
  activationUtils = import ../../../../lib/activation/utils.nix { inherit lib; };
in
{
  home.file.".yarnrc" = {
    text = ''
      strict-ssl false
      yarn-offline-mirror ".local/share/yarn/packages-cache"
    '';
  };

  home.activation.yarnPackages = activationUtils.mkPackageManager {
    name = "yarn";
    basePackages = [
      "fkill-cli"
      "jsonlint"
      "markdownlint-cli2"
      "@mermaid-js/mermaid-cli"
      "prettier"
      "typescript-language-server"
      "typescript"
    ];
    additionalPackages =
      if userConfig ? yarn && userConfig.yarn ? additionalPackages then
        userConfig.yarn.additionalPackages
      else
        [ ];
    executableArguments = [
      "global"
      "add"
      "--non-interactive"
    ];
    executableName = "yarn";
  };
}

