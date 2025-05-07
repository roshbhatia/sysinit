{ pkgs, lib, config, userConfig ? {}, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in activationUtils.mkPackageManager {
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
  executableArguments = [ "install" "-g" ];
  executablePath = "npm";  # Using PATH now instead of hardcoded path
}
