{ pkgs, lib, config, userConfig ? {}, ... }:

let
  packageManager = import ../../lib/package-manager.nix { inherit lib; };
in packageManager.mkPackageManager {
  name = "npm";
  basePackages = [
    "jsonlint"
    "markdownlint"
    "@mermaid-js/mermaid-cli"
    "prettier"
    "tree-sitter-cli"
    "typescript-language-server"
    "typescript"
  ];
  additionalPackages = if userConfig ? npm && userConfig.npm ? additionalPackages
    then userConfig.npm.additionalPackages
    else [];
  installCommand = '"$YARN" global add "$package"';
  executablePath = "/Users/$USER/.npm-global/bin/yarn";
} // {
  home.file.".npmrc".text = ''
    prefix=.npm-global
  '';
  home.sessionVariables.NPM_CONFIG_PREFIX = ".npm-global";
}
