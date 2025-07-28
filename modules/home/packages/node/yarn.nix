{
  lib,
  values,
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
      "bash-language-server"
      "markdownlint-cli"
      "markdownlint-cli2"
      "mcp-hub@latest"
    ];
    additionalPackages = (values.yarn.additionalPackages or [ ]);
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

