{ lib, ... }:

{
  mkPackageManager = {
    name,
    basePackages,
    additionalPackages ? [],
    installCommand,
    executablePath,
  }: let
    allPackages = basePackages ++ additionalPackages;
    escapedPackages = lib.concatStringsSep " " (map lib.escapeShellArg allPackages);
  in {
    home.activation."${name}Packages" = {
      after = [ "fixVariables" ];
      before = [];
      data = ''
        echo "Installing ${name} packages..."
        set +u
        EXECUTABLE="${executablePath}"
        if [ -x "$EXECUTABLE" ]; then
          PACKAGES='${escapedPackages}'
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
}
