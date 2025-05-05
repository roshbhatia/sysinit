{ pkgs, lib, config, userConfig ? {}, ... }:

let
  additionalPackages = if userConfig ? cargo && userConfig.cargo ? additionalPackages
    then userConfig.cargo.additionalPackages
    else [];

  basePackages = [
    "cargo-watch"
    "ripgrep-all"
    "stylua"
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
      
      export PATH="$PATH:/opt/homebrew/bin:/usr/bin"

      if [ -x "$CARGO" ]; then
        PACKAGES='${escapedPackages}'
        if [ -n "$PACKAGES" ]; then
          for package in $PACKAGES; do
            "$CARGO" install "$package" -f
          done
        fi
      else
        echo "❌ cargo not found at $CARGO"
      fi
    '';
  };
}
