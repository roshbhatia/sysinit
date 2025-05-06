{
  pkgs,
  lib,
  config,
  userConfig ? { },
  ...
}:

let
  additionalPackages =
    if userConfig ? npm && userConfig.npm ? additionalPackages then
      userConfig.npm.additionalPackages
    else
      [ ];

  basePackages = [
    "jsonlint"
    "markdownlint"
    "@mermaid-js/mermaid-cli"
    "prettier"
    "typescript-language-server"
    "typescript"
  ];

  allPackages = basePackages ++ additionalPackages;

  escapedPackages = lib.concatStringsSep " " (map lib.escapeShellArg allPackages);
in
{
  home.file.".npmrc".text = ''
    prefix=.npm-global
  '';

  home.sessionVariables.NPM_CONFIG_PREFIX = ".npm-global";

  home.activation.npmPackages = {
    after = [ "fixVariables" ];
    before = [ ];
    data = ''
      echo "Installing npm packages..."
      set +u
      NPM="/etc/profiles/per-user/$USER/bin/npm"
      if [ -x "$NPM" ]; then
        echo "Installing yarn..."
        "$NPM" install -g yarn

        YARN="/Users/$USER/.npm-global/bin/yarn"
        if [ -x "$YARN" ]; then
          echo "Installing packages via yarn..."
          PACKAGES='${escapedPackages}'
          if [ -n "$PACKAGES" ]; then
            "$YARN" global add $PACKAGES
          fi
        else
          echo "❌ yarn not found at $YARN"
        fi
      else
        echo "❌ npm not found at $NPM"
      fi
    '';
  };
}
