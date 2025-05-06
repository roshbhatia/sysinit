{ lib, ... }:

{
  mkPackageManager = {
    name,
    basePackages,
    additionalPackages ? [],
    executableArguments,
    executablePath,
  }: let
    allPackages = basePackages ++ additionalPackages;
    escapedPackages = lib.concatStringsSep " " (map lib.escapeShellArg allPackages);
    escapedArguments = lib.concatStringsSep " " (map lib.escapeShellArg executableArguments);
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
              "$EXECUTABLE" ${escapedArguments} "$package"
            done
          fi
        else
          echo "❌ ${name} not found at $EXECUTABLE"
        fi
      '';
    };
  };
}
