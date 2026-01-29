{
  lib,
  ...
}:

with lib;

let
  mkPackageManagerScript =
    config: manager: packages:
    let
      # Manager metadata is now defined in individual package manager .nix files
      # This function is kept for backward compatibility
      managers = config.packages.managers or { };
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
                  managed_pkg_file="$HOME/.config/home-manager/managed-${manager}-packages"
                  ${m.env}
                  if command -v "$MANAGER_CMD" >/dev/null 2>&1; then
                    ${m.setupCmd or ""}

                    # Track managed packages for cleanup
                    mkdir -p "$(dirname "$managed_pkg_file")"
                    cat > "$managed_pkg_file.tmp" << 'MANAGED_PKGS'
        ${concatStringsSep "\n" packages}
        MANAGED_PKGS

                    # Install new/updated packages
                    for pkg in ${concatStringsSep " " packages}; do
                      ${m.installCmd}
                    done

                    # Replace tracking file only after successful installation
                    mv "$managed_pkg_file.tmp" "$managed_pkg_file"
                    echo "Completed ${manager} package installation"
                  else
                    echo "Warning: ${manager} command '$MANAGER_CMD' not available, skipping package installation"
                  fi
                fi
      '';

  mkPackageActivationScript =
    manager: packages: config:
    mkPackageManagerScript config manager packages;
in

{
  inherit mkPackageManagerScript mkPackageActivationScript;

  mkPackageManagerCleanup =
    config: manager:
    let
      managers = config.packages.managers or { };
      m = managers.${manager} or null;
    in
    if m == null || !(m ? cleanupCmd) then
      ""
    else
      ''
        managed_pkg_file="$HOME/.config/home-manager/managed-${manager}-packages"
        MANAGER_CMD=${m.bin}
        ${m.env}
        if command -v "$MANAGER_CMD" >/dev/null 2>&1 && [ -f "$managed_pkg_file" ]; then
          echo "Cleaning up ${manager} packages not in configuration..."
          ${m.cleanupCmd}
        fi
      '';
}
