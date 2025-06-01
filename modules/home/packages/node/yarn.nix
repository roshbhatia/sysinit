{
  lib,
  userConfig ? { },
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
      "fkill-cli"
      "jsonlint"
      "markdownlint-cli2"
      "@mermaid-js/mermaid-cli"
      "prettier"
      "typescript-language-server"
      "typescript"
    ];
    additionalPackages = (userConfig.yarn.additionalPackages or [ ]);
    executableArguments = [
      "global"
      "add"
      "--non-interactive"
    ];
    executableName = "yarn";
  };
}
