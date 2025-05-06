{ lib }:

let
  mkPackageManager = { name, basePackages, additionalPackages, installCommand, executablePath }: {
    home.activation."${name}Packages" = {
      after = [ "fixVariables" ];
      before = [];
      data = ''
        echo "Installing ${name} packages..."
        set +u
        EXECUTABLE="${executablePath}"
        if [ -x "$EXECUTABLE" ]; then
          PACKAGES='${lib.concatStringsSep " " (map lib.escapeShellArg (basePackages ++ additionalPackages))}'
          if [ -n "$PACKAGES" ]; then
            for package in $PACKAGES; do
              ${installCommand}
            done
          fi
        else
          echo "❌ ${name} not found at $EXECUTABLE"
        fi
      '';
    };
  };
in {
  inherit mkPackageManager;
}
