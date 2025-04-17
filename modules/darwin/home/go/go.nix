{ pkgs, lib, config, userConfig ? {}, ... }:
let
  additionalPackages = if userConfig ? go && userConfig.go ? additionalPackages
    then userConfig.go.additionalPackages
    else [];
  basePackages = [
    "github.com/x-motemen/gore/cmd/gore"
    "golang.org/x/tools/cmd/godoc"
    "golang.org/x/tools/gopls"
  ];
  allPackages = basePackages ++ additionalPackages;
in
{
  home.activation.goPackages = {
    after = [ "fixVariables" ];
    before = [];
    data = ''
      echo "Installing Go packages..."
      set +u
      GO="/etc/profiles/per-user/$USER/bin/go"
      if [ -x "$GO" ]; then
        PACKAGES="${lib.escapeShellArgs allPackages}"
        if [ -n "$PACKAGES" ]; then
          for package in $PACKAGES; do
            echo "Installing $package if needed..."
            "$GO" install "$package@latest" || true
          done
        fi
      else
        echo "❌ go not found at $GO"
      fi
    '';
  };
}