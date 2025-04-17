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
      echo "Installing pipx packages..."
      set +u

      PIPX="/opt/homebrew/bin/pipx"
      if [ -x "$PIPX" ]; then
        PIPX_OUTPUT=$("$PIPX" list || echo "nothing has been installed with pipx")
        echo "$PIPX_OUTPUT"
        
        PACKAGES="${lib.escapeShellArgs allPackages}"
        if [ -n "$PACKAGES" ]; then
          for package in $PACKAGES; do
            echo "Installing $package if needed..."
            "$PIPX" install "$package" || true
          done
        fi
      else
        echo "❌ pipx not found at $PIPX"
      fi
    '';
  };
}