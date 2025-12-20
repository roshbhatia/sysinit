{
  lib,
  pkgs,
  ...
}:

with lib;

let
  defaultManagers = (import ../../../home/packages/node/lib.nix { inherit pkgs; })
    // (import ../../../home/packages/cargo/lib.nix { inherit pkgs; })
    // (import ../../../home/packages/python/lib.nix { inherit pkgs; })
    // (import ../../../home/packages/go/lib.nix { inherit pkgs; })
    // (import ../../../home/packages/gh/lib.nix { inherit pkgs; })
    // (import ../../../home/packages/vet/lib.nix { });
in

{
  inherit defaultManagers;

  mkPackageManagerScript =
    config: manager: packages:
    let
      managers = config.packages.managers or defaultManagers;
      m = managers.${manager} or null;
    in
    if m == null then
      ''
        echo "Unknown package manager: ${manager}"
        exit 1
      ''
    else
      ''
        if [ ${toString (length packages)} -gt 0 ]; then
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
}
