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
      # Handle unbound variables
      set +u
      
      echo "📦 Setting up NPM packages..."
      mkdir -p ${npmGlobalDir}
      chmod -R 755 ${npmGlobalDir}
      
      # Simplified approach - just install the packages we need
      for package in ${lib.escapeShellArgs allPackages}; do
        if command -v npm &>/dev/null; then
          echo "Installing $package if needed..."
          npm install -g "$package" || true
        fi
      done
    '';
  };
}