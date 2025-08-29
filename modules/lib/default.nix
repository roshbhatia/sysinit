{
  lib,
  pkgs,
  system,
  ...
}:

with lib;

let
  defaultManagers = {
    cargo = {
      bin = "${pkgs.cargo}/bin/cargo";
      env = ''
        export PATH="${pkgs.clang}/bin:$PATH"
      '';
      installCmd = ''"$MANAGER_CMD" install --locked "$pkg" || echo "Warning: Failed to install $pkg"'';
    };
    npm = {
      bin = "${pkgs.nodejs}/bin/npm";
      env = ''
        export PATH="${pkgs.nodejs}/bin:$PATH"
      '';
      installCmd = ''"$MANAGER_CMD" install -g "$pkg" || echo "Warning: Failed to install $pkg"'';
    };
  };
in
rec {
  paths = import ./paths { inherit lib; };
  platform = import ./platform.nix { inherit lib system; };
  shell = import ./shell { inherit lib; };
  theme = import ./theme.nix;
  themes = import ./theme { inherit lib; };
  themeHelper = import ./theme-helper.nix { inherit lib; };
  validation = import ./validation.nix { inherit lib; };
  packages = import ./packages.nix { inherit platform pkgs; };

  sysinit = {
    mkPackageManagerScript =
      config: manager: packages:
      let
        managers = config.packages.managers or defaultManagers;
        m = managers.${manager} or null;
      in
      ''
        if [ ${toString (length packages)} -gt 0 ]; then
          if [ -z "${toString m}" ]; then
            echo "Unknown package manager: ${manager}"
            exit 1
          fi
          echo "Installing ${manager} packages: ${concatStringsSep " " packages}"
          MANAGER_CMD=${m.bin}
          ${m.env}
          if command -v "$MANAGER_CMD" >/dev/null 2>&1; then
            for pkg in ${concatStringsSep " " packages}; do
              ${m.installCmd}
            done
            echo "Completed ${manager} package installation"
          else
            echo "Warning: ${manager} command '$MANAGER_CMD' not available, skipping package installation"
          fi
        fi
      '';
  };
}
