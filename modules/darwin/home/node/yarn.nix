{
  pkgs,
  lib,
  config,
  userConfig ? { },
  ...
}:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in
{
  home.file.".yarnrc" = {
    text = ''
      strict-ssl false
    '';
  };

  home.activation.yarnPackages = activationUtils.mkPackageManager {
    name = "yarn";
    basePackages = [
      "jsonlint"
      "markdownlint-cli2"
      "@mermaid-js/mermaid-cli"
      "prettier"
      "tree-sitter-cli"
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
    ];
    executableName = "yarn";
  };
}
