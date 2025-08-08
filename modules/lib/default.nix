
{ lib, pkgs, system, ... }:

with lib;

rec {
  paths = import ./paths { inherit lib; };
  platform = import ./platform.nix { inherit lib system; };
  shell = import ./shell { inherit lib; };
  theme = import ./theme.nix;
  themes = import ./theme { inherit lib; };
  packages = import ./packages.nix { inherit platform pkgs; };

  sysinit = {
    mkPackageManagerScript = config: manager: packages: ''
      if [ ${toString (length packages)} -gt 0 ]; then
        echo "Installing ${manager} packages: ${concatStringsSep " " packages}"
        case "${manager}" in
          "cargo") export PATH="${pkgs.rustup}/bin:$PATH"; MANAGER_CMD="cargo" ;;
          "npm") export PATH="${pkgs.nodejs}/bin:$PATH"; MANAGER_CMD="npm" ;;
          "yarn") export PATH="${pkgs.yarn}/bin:$PATH"; MANAGER_CMD="yarn" ;;
          "pipx") export PATH="${pkgs.pipx}/bin:$PATH"; MANAGER_CMD="pipx" ;;
          "go") export PATH="${pkgs.go}/bin:$PATH"; MANAGER_CMD="go" ;;
          "uv") export PATH="${pkgs.uv}/bin:${config.home.homeDirectory}/.local/bin:$PATH"; MANAGER_CMD="uv" ;;
          "kubectl") export PATH="${pkgs.krew}/bin:${config.home.homeDirectory}/.krew/bin:$PATH"; MANAGER_CMD="krew" ;;
          "gh") export PATH="${pkgs.gh}/bin:$PATH"; MANAGER_CMD="gh" ;;
          *) echo "Unknown package manager: ${manager}"; exit 1 ;;
        esac
        if command -v "$MANAGER_CMD" >/dev/null 2>&1; then
          for pkg in ${concatStringsSep " " packages}; do
            case "${manager}" in
              "cargo") "$MANAGER_CMD" install --locked "$pkg" || echo "Warning: Failed to install $pkg" ;;
              "npm") "$MANAGER_CMD" install -g "$pkg" || echo "Warning: Failed to install $pkg" ;;
              "yarn") "$MANAGER_CMD" global add "$pkg" || echo "Warning: Failed to install $pkg" ;;
              "pipx") "$MANAGER_CMD" install "$pkg" || echo "Warning: Failed to install $pkg" ;;
              "go") "$MANAGER_CMD" install "$pkg" || echo "Warning: Failed to install $pkg" ;;
              "uv") "$MANAGER_CMD" tool install "$pkg" || echo "Warning: Failed to install $pkg" ;;
              "kubectl") "$MANAGER_CMD" install "$pkg" || echo "Warning: Failed to install $pkg" ;;
              "gh") "$MANAGER_CMD" extension install "$pkg" || echo "Warning: Failed to install $pkg" ;;
            esac
          done
          echo "Completed ${manager} package installation"
        else
          echo "Warning: ${manager} command '$MANAGER_CMD' not available, skipping package installation"
        fi
      fi
    '';
  };
}
