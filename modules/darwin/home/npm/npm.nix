{ pkgs, lib, config, userConfig ? {}, ... }:

let
  packageManager = import ../../../../lib/package-manager.nix { inherit lib; };
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
  installCommand = ''"$NPM" install -g "$package"''; # Use single quotes for the outer string
  executablePath = "/etc/profiles/per-user/$USER/bin/npm";
}
