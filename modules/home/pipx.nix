{ pkgs, lib, config, userConfig ? {}, ... }:

let
  additionalPackages = if userConfig ? pipx && userConfig.pipx ? additionalPackages
                      then userConfig.pipx.additionalPackages
                      else [];

  basePackages = [
    "black"
    "flake8"
    "poetry"
  ];

  allPackages = basePackages ++ additionalPackages;
in
{
  home.activation.pipxPackages = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      # Handle unbound variables
      set +u
      
      # Source user profile to ensure pipx is available
      [ -f /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh ] && \
        . /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
      [ -f /etc/profile ] && . /etc/profile
      
      set -u
      
      echo "📦 Setting up PipX packages..."
      
      # Get list of currently installed packages
      echo "🔍 Checking for unmanaged packages..."
      INSTALLED_PACKAGES=$(/opt/homebrew/bin/pipx list --json | jq -r '.venvs | keys[]' 2>/dev/null)
      
      # Uninstall packages not in our managed list
      for package in $INSTALLED_PACKAGES; do
        if ! echo ${lib.escapeShellArgs allPackages} | grep -q "$package"; then
          echo "🗑️  Uninstalling unmanaged package $package..."
          /opt/homebrew/bin/pipx uninstall "$package"
        fi
      done
      
      # Install our managed packages
      for package in ${lib.escapeShellArgs allPackages}; do
        if ! /opt/homebrew/bin/pipx list | grep -q "$package"; then
          echo "🚀 Installing $package with pipx..."
          if /opt/homebrew/bin/pipx install "$package"; then
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