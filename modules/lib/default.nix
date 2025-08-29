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
    uv = {
      bin = "${pkgs.uv}/bin/uv";
      env = ''
        export PATH="${pkgs.uv}/bin:$PATH"
        export UV_PYTHON_PREFERENCE=only-managed
      '';
      installCmd = ''"$MANAGER_CMD" tool install --force "$pkg" || echo "Warning: Failed to install $pkg"'';
    };
    yarn = {
      bin = "${pkgs.yarn}/bin/yarn";
      env = ''
        export PATH="${pkgs.yarn}/bin:$PATH"
      '';
      installCmd = ''"$MANAGER_CMD" global add "$pkg" || echo "Warning: Failed to install $pkg"'';
    };
    pipx = {
      bin = "${pkgs.pipx}/bin/pipx";
      env = ''
        export PATH="${pkgs.pipx}/bin:$PATH"
      '';
      installCmd = ''"$MANAGER_CMD" install "$pkg" || echo "Warning: Failed to install $pkg"'';
    };
    go = {
      bin = "${pkgs.go}/bin/go";
      env = ''
        export PATH="${pkgs.go}/bin:$PATH"
        export GOPATH="$HOME/go"
        export PATH="$GOPATH/bin:$PATH"
      '';
      installCmd = ''"$MANAGER_CMD" install "$pkg@latest" || echo "Warning: Failed to install $pkg"'';
    };
    gh = {
      bin = "${pkgs.gh}/bin/gh";
      env = ''
        export PATH="${pkgs.gh}/bin:$PATH"
      '';
      installCmd = ''"$MANAGER_CMD" extension install "$pkg" || echo "Warning: Failed to install $pkg"'';
    };
    kubectl = {
      bin = "${pkgs.kubectl}/bin/kubectl";
      env = ''
        export PATH="${pkgs.kubectl}/bin:$PATH"
        export KREW_ROOT="$HOME/.krew"
        export PATH="$KREW_ROOT/bin:$PATH"
      '';
      installCmd = ''"$MANAGER_CMD" krew install "$pkg" || echo "Warning: Failed to install $pkg"'';
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
  };
}
