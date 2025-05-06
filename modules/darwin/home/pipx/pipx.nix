{ pkgs, lib, config, userConfig ? {}, ... }:

let
  additionalPackages = if userConfig ? pipx && userConfig.pipx ? additionalPackages
                      then userConfig.pipx.additionalPackages
                      else [];

  basePackages = [
    "black"
    "hererocks"
    "yamllint"
    "uv"
  ];

  allPackages = basePackages ++ additionalPackages;

  escapedPackages = lib.concatStringsSep " " (map lib.escapeShellArg allPackages);
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
        "$PIPX" ensurepath >/dev/null 2>&1 || true
        PACKAGES='${escapedPackages}'
        if [ -n "$PACKAGES" ]; then
          for package in $PACKAGES; do
            "$PIPX" install "$package" --force
          done
        fi
      else
        echo "❌ pipx not found at $PIPX"
      fi
    '';
  };
}
