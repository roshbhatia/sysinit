{pkgs, lib, config, userConfig ? {}, ...}:

let
  additionalPackages = if userConfig ? pipx && userConfig.pipx ? additionalPackages
                      then userConfig.pipx.additionalPackages
                      else [];

  basePackages = [];

  allPackages = basePackages ++ additionalPackages;
in
{
  home.activation.pipxPackages = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      # Handle unbound variables
      set +u
      
      # Source Homebrew and user profile
      [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
      [ -f /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh ] && \
        . /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
      
      set -u
      
      echo "🐍 Setting up Pipx packages..."
      
      # Install packages using pipx if they're not already installed
      for package in ${lib.escapeShellArgs allPackages}; do
        if ! pipx list | grep -q "$package"; then
          echo "🚀 Installing $package with pipx..."
          if pipx install "$package"; then
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