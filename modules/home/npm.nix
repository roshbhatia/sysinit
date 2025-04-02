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
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      # Handle unbound variables
      set +u
      
      # Source user profile to ensure npm is available
      [ -f /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh ] && \
        . /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
      [ -f /etc/profile ] && . /etc/profile
      
      set -u
      
      echo "📦 Setting up NPM packages..."
      mkdir -p ${npmGlobalDir}
      
      # Install npm packages globally
      for package in ${lib.escapeShellArgs allPackages}; do
        if ! npm list -g "$package" &>/dev/null; then
          echo "🚀 Installing $package globally..."
          if npm install -g "$package"; then
            echo "✅ Successfully installed $package"
          else
            echo "❌ Failed to install $package"
          fi
        else
          echo "✨ $package is already installed"
        fi
      done
    '';
  };
}