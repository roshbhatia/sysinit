{ pkgs, lib, config, userConfig ? {}, ... }:

let
  additionalPackages =
    if userConfig ? go && userConfig.go ? additionalPackages
    then userConfig.go.additionalPackages
    else [];

  basePackages = [
    "github.com/x-motemen/gore/cmd/gore"
    "golang.org/x/tools/cmd/godoc"
    "golang.org/x/tools/gopls"
  ];

  allPackages = basePackages ++ additionalPackages;

  escapedPackages = lib.concatStringsSep " " (map lib.escapeShellArg allPackages);
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
        PACKAGES='${escapedPackages}'
        if [ -n "$PACKAGES" ]; then
          for package in $PACKAGES; do
            "$GO" install "$package@latest" >/dev/null 2>&1 \
              && echo "✅ Successfully installed $package via go install" \
              || echo "❌ Failed to install $package via go install"
          done
        fi
      else
        echo "❌ go not found at $GO"
      fi
    '';
  };
}
