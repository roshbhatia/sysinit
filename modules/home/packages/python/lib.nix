{ pkgs }:

{
  pipx = {
    bin = "${pkgs.pipx}/bin/pipx";
    env = ''
      export PATH="${pkgs.pipx}/bin:$HOME/.local/bin:$PATH"
      export PIPX_BIN_DIR="$HOME/.local/bin"
      export PIPX_HOME="$HOME/.local/pipx"
    '';
    installCmd = ''"$MANAGER_CMD" install "$pkg" --quiet || echo "Warning: Failed to install $pkg"'';
    cleanupCmd = ''
      local installed=$(
        "$MANAGER_CMD" list --short 2>/dev/null \
          | awk '{print $1}' \
          | sort
      )

      local managed=$(sort "$managed_pkg_file")

      comm -23 <(echo "$installed") <(echo "$managed") | while read pkg; do
        [ -n "$pkg" ] && "$MANAGER_CMD" uninstall "$pkg" --quiet 2>/dev/null || true
      done
    '';
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
      [ -d "$HOME/.local/bin/$pkg" ] && rm -rf "$HOME/.local/bin/$pkg"
      "$MANAGER_CMD" tool install --force --quiet --reinstall "$pkg" || echo "Warning: Failed to install $pkg"
    '';
    cleanupCmd = ''
      local installed=$(
        "$MANAGER_CMD" tool list 2>/dev/null \
          | grep v \
          | awk '{print $1}' \
          | sort
      )

      local managed=$(sort "$managed_pkg_file")

      comm -23 <(echo "$installed") <(echo "$managed") | while read pkg; do
        [ -n "$pkg" ] && "$MANAGER_CMD" tool remove "$pkg" 2>/dev/null || true
      done
    '';
  };
}
