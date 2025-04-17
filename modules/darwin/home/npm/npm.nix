{ pkgs, lib, config, userConfig ? {}, ... }:

let
  additionalPackages = if userConfig ? npm && userConfig.npm ? additionalPackages
                      then userConfig.npm.additionalPackages
                      else [];

  basePackages = [
    "typescript-language-server"
    "prettier"
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
      
      mkdir -p ${npmGlobalDir}
      chmod -R 755 ${npmGlobalDir}
      
      NPM="/etc/profiles/per-user/rbha27/bin/npm"
      if [ -x "$NPM" ]; then
        for package in ${lib.escapeShellArgs allPackages}; do
          if command -v npm &>/dev/null; then
            echo "Installing $package if needed..."
            npm install -g "$package" || true
          fi
        done
      else
        echo "❌ npm not found at $NPM"
      fi
    '';
  };
}