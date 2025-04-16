{ pkgs, lib, config, userConfig ? {}, ... }:

let
  additionalPackages = if userConfig ? pipx && userConfig.pipx ? additionalPackages
                      then userConfig.pipx.additionalPackages
                      else [];

  basePackages = [];

  allPackages = basePackages ++ additionalPackages;
in
{
  home.activation.pipxPackages = {
    after = [ "fixVariables" ];
    before = [];
    data = ''
      # Handle unbound variables
      set +u
      
      echo "📦 Setting up PipX packages..."
      echo "🔍 Checking for unmanaged packages..."
      
      PIPX="/opt/homebrew/bin/pipx"
      if [ -x "$PIPX" ]; then
        PIPX_OUTPUT=$("$PIPX" list || echo "nothing has been installed with pipx 😴")
        echo "$PIPX_OUTPUT"
        
        # Only try to install if there are packages to install
        PACKAGES="${lib.escapeShellArgs allPackages}"
        if [ -n "$PACKAGES" ]; then
          for package in $PACKAGES; do
            echo "Installing $package if needed..."
            "$PIPX" install "$package" || true
          done
        fi
      else
        echo "pipx not found at $PIPX"
      fi
    '';
  };
}