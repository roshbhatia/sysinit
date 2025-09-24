{
  lib,
  pkgs,
  ...
}:

with lib;

let
  defaultManagers = {
    cargo = {
      bin = "${pkgs.cargo}/bin/cargo";
      env = ''
        export PATH="${pkgs.clang}/bin:$HOME/.cargo/bin:$PATH"
        export RUSTUP_HOME="$HOME/.rustup"
        export CARGO_HOME="$HOME/.cargo"
      '';
      installCmd = ''"$MANAGER_CMD" install --locked "$pkg" || echo "Warning: Failed to install $pkg"'';
    };
    npm = {
      bin = "${pkgs.nodejs}/bin/npm";
      env = ''
        export NODE_NO_WARNINGS=1
        export NODE_TLS_REJECT_UNAUTHORIZED=0
        export PATH="${pkgs.nodejs}/bin:$PATH"
        export NPM_CONFIG_PREFIX="$HOME/.npm-global"
      '';
      installCmd = ''"$MANAGER_CMD" install -g "$pkg" --silent || echo "Warning: Failed to install $pkg"'';
    };
    uv = {
      bin = "${pkgs.uv}/bin/uv";
      env = ''
        export PATH="${pkgs.uv}/bin:$HOME/.local/bin:$PATH"
        export UV_PYTHON_PREFERENCE=only-managed
        export UV_TOOL_DIR="$HOME/.local"
        export UV_TOOL_BIN_DIR="$HOME/.local/bin"
      '';
      installCmd = ''
        # Remove any existing directory conflicts
        [ -d "$HOME/.local/bin/$pkg" ] && rm -rf "$HOME/.local/bin/$pkg"
        "$MANAGER_CMD" tool install --force --quiet --reinstall "$pkg" || echo "Warning: Failed to install $pkg"
      '';
    };
    yarn = {
      bin = "${pkgs.yarn}/bin/yarn";
      env = ''
        export NODE_NO_WARNINGS=1
        export NODE_TLS_REJECT_UNAUTHORIZED=0
        export PATH="${pkgs.yarn}/bin:$PATH"
        export YARN_GLOBAL_FOLDER="$HOME/.yarn"
      '';
      installCmd = ''
        "$MANAGER_CMD" config set strict-ssl false -g
        "$MANAGER_CMD" global add "$pkg" --silent || echo "Warning: Failed to install $pkg"
      '';
    };
    pipx = {
      bin = "${pkgs.pipx}/bin/pipx";
      env = ''
        export PATH="${pkgs.pipx}/bin:$HOME/.local/bin:$PATH"
        export PIPX_BIN_DIR="$HOME/.local/bin"
        export PIPX_HOME="$HOME/.local/pipx"
      '';
      installCmd = ''"$MANAGER_CMD" install "$pkg" --quiet || echo "Warning: Failed to install $pkg"'';
    };
    go = {
      bin = "${pkgs.go}/bin/go";
      env = ''
        export PATH="${pkgs.go}/bin:${pkgs.git}/bin:$PATH"
        export GOPATH="$HOME/go"
        export GOPROXY=https://proxy.golang.org,direct
        export GOSUMDB=sum.golang.org
        export GO111MODULE=on
        export PATH="$GOPATH/bin:$PATH"
        export CGO_ENABLED=1
        export CGO_LDFLAGS="-framework CoreFoundation -framework Security"
      '';
      installCmd = ''"$MANAGER_CMD" install -v "$pkg" || echo "Warning: Failed to install $pkg"'';
    };
    gh = {
      bin = "${pkgs.gh}/bin/gh";
      env = ''
        export PATH="${pkgs.gh}/bin:/usr/bin:$PATH"
        export GH_FORCE_TTY=false
      '';
      installCmd = ''
        if output=$("$MANAGER_CMD" extension install "$pkg" 2>&1); then
          true
        else
          case "$output" in
            *"there is already an installed extension that provides"*)
              echo "Extension already installed: $pkg"
              ;;
            *)
              echo "Warning: Failed to install $pkg"
              ;;
          esac
        fi
      '';
    };
    kubectl = {
      bin = "${pkgs.kubectl}/bin/kubectl";
      env = ''
        export PATH="${pkgs.kubectl}/bin:${pkgs.krew}/bin:$PATH"
        export KREW_ROOT="$HOME/.krew"
        export PATH="$KREW_ROOT/bin:$PATH"
      '';
      installCmd = ''
        # Initialize krew if not already done
        if [ ! -f "$KREW_ROOT/bin/kubectl-krew" ]; then
          mkdir -p "$KREW_ROOT"
          "${pkgs.krew}/bin/krew" install krew
        fi
        "$KREW_ROOT/bin/kubectl-krew" install "$pkg" || echo "Warning: Failed to install $pkg"
      '';
    };
    curlBash = {
      bin = "${pkgs.curl}/bin/curl";
      env = ''
        export PATH="${pkgs.curl}/bin:${pkgs.bashInteractive}/bin:$PATH"
      '';
      installCmd = ''
        vet $pkg
      '';
    };
  };
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
