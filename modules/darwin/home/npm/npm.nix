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
    "prettier"
    "typescript-language-server"
    "typescript"
    "yarn"
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
        PACKAGES='${escapedPackages}'
        if [ -n "$PACKAGES" ]; then
          for package in $PACKAGES; do
            "$NPM" install -g "$package" --silent >/dev/null 2>&1 \
              && echo "✅ Successfully installed $package via npm" \
              || echo "❌ Failed to install $package via npm"
          done
        fi
      else
        echo "❌ npm not found at $NPM"
      fi
    '';
  };
}
