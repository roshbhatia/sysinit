{ pkgs, lib, config, userConfig ? {}, ... }:
let
  additionalPackages = if userConfig ? npm && userConfig.npm ? additionalPackages
    then userConfig.npm.additionalPackages
    else [];
  basePackages = [
    "jsonlint"
    "prettier"
    "typescript-language-server"
    "typescript"
  ];
  allPackages = basePackages ++ additionalPackages;
  npmGlobalDir = "$HOME/.npm-global";
in
{
  home.file.".npmrc".text = ''
    prefix=${npmGlobalDir}
  '';
  home.sessionVariables.NPM_CONFIG_PREFIX = npmGlobalDir;
  home.activation.npmPackages = {
    after = [ "fixVariables" ];
    before = [];
    data = ''
      echo "Installing npm packages..."
      set +u
      NPM="/etc/profiles/per-user/$USER/bin/npm"
      if [ -x "$NPM" ]; then
        PACKAGES="${lib.escapeShellArgs allPackages}"
        if [ -n "$PACKAGES" ]; then
          for package in $PACKAGES; do
            echo "Installing $package if needed..."
            "$NPM" install -g "$package" || true
          done
        fi
      else
        echo "❌ npm not found at $NPM"
      fi
    '';
  };
}