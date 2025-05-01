{ pkgs, lib, config, userConfig ? {}, ... }:

let
  additionalPackages = if userConfig ? cargo && userConfig.cargo ? additionalPackages
    then userConfig.cargo.additionalPackages
    else [];

  basePackages = [
    "cargo-watch"
    "ripgrep-all"
  ];

  allPackages = basePackages ++ additionalPackages;

  escapedPackages = lib.concatStringsSep " " (map lib.escapeShellArg allPackages);
in
{
  home.activation.cargoPackages = {
    after = [ "fixVariables" ];
    before = [];
    data = ''
      echo "Installing Cargo packages..."
      set +u
      CARGO="/opt/homebrew/bin/cargo"
      if [ -x "$CARGO" ]; then
        PACKAGES='${escapedPackages}'
        if [ -n "$PACKAGES" ]; then
          for package in $PACKAGES; do
            "$CARGO" install "$package" --quiet >/dev/null 2>&1 \
              && echo "✅ Successfully installed $package via cargo" \
              || echo "❌ Failed to install $package via cargo"
          done
        fi
      else
        echo "❌ cargo not found at $CARGO"
      fi
    '';
  };
}
