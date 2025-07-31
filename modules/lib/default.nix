{
  lib,
  pkgs,
  system,
  ...
}:

with lib;

rec {
  paths = import ./paths { inherit lib; };
  platform = import ./platform.nix { inherit lib system; };
  shell = import ./shell { inherit lib; };
  theme = import ./theme-module.nix;
  themes = import ./themes { inherit lib; };
  packages = import ./packages.nix { inherit platform pkgs; };

  sysinit = {
    mkPackageManagerScript = manager: packages: ''
      if [ ${toString (length packages)} -gt 0 ]; then
        echo "Installing ${manager} packages: ${concatStringsSep " " packages}"
        MANAGER_PATH=""
        case "${manager}" in
          "cargo")
            MANAGER_PATH="${pkgs.rustup}/bin/cargo"
            ;;
          "npm")
            MANAGER_PATH="${pkgs.nodejs}/bin/npm"
            ;;
          "yarn")
            MANAGER_PATH="${pkgs.yarn}/bin/yarn"
            ;;
          "pipx")
            MANAGER_PATH="${pkgs.pipx}/bin/pipx"
            ;;
          "go")
            MANAGER_PATH="${pkgs.go}/bin/go"
            ;;
          "uv")
            MANAGER_PATH="${pkgs.uv}/bin/uv:${config.home.homeDirectory}/.local/bin"
            ;;
          "kubectl")
            MANAGER_PATH="${pkgs.kubectl}/bin/kubectl:${config.home.homeDirectory}.krew/bin"
            ;;
          "gh")
            MANAGER_PATH="${pkgs.gh}/bin/gh"
            ;;
          *)
            echo "Unknown package manager: ${manager}"
            exit 1
            ;;
        esac

        if [ -f "$MANAGER_PATH" ]; then
          for pkg in ${concatStringsSep " " packages}; do
            case "${manager}" in
              "cargo")
                "$MANAGER_PATH" install --locked "$pkg" || echo "Warning: Failed to install $pkg"
                ;;
              "npm")
                PATH="${pkgs.nodejs}/bin:$PATH" "$MANAGER_PATH" install -g "$pkg" || echo "Warning: Failed to install $pkg"
                ;;
              "yarn")
                "$MANAGER_PATH" global add "$pkg" || echo "Warning: Failed to install $pkg"
                ;;
              "pipx")
                "$MANAGER_PATH" install "$pkg" || echo "Warning: Failed to install $pkg"
                ;;
              "go")
                "$MANAGER_PATH" install "$pkg" || echo "Warning: Failed to install $pkg"
                ;;
              "uv")
                "$MANAGER_PATH" tool install "$pkg" || echo "Warning: Failed to install $pkg"
                ;;
              "kubectl")
                PATH="${pkgs.krew}/bin:$PATH" "${pkgs.krew}/bin/krew" install "$pkg" || echo "Warning: Failed to install $pkg"
                ;;
              "gh")
                "$MANAGER_PATH" extension install "$pkg" || echo "Warning: Failed to install $pkg"
                ;;
            esac
          done
          echo "Completed ${manager} package installation"
        else
          echo "Warning: ${manager} not available at $MANAGER_PATH, skipping package installation"
        fi
      fi
    '';
  };
}

