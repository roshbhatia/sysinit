{ pkgs }:

{
  cargo = {
    bin = "${pkgs.cargo}/bin/cargo";
    env = ''
      export PATH="${pkgs.clang}/bin:$HOME/.cargo/bin:$PATH"
      export RUSTUP_HOME="$HOME/.rustup"
      export CARGO_HOME="$HOME/.cargo"
    '';
    installCmd = ''"$MANAGER_CMD" install --locked "$pkg" || echo "Warning: Failed to install $pkg"'';
    cleanupCmd = ''
      local installed=$(
        "$MANAGER_CMD" install --list 2>/dev/null \
          | awk '/^[a-zA-Z]/ {print $1}' \
          | sort
      )

      local managed=$(sort "$managed_pkg_file")

      comm -23 <(echo "$installed") <(echo "$managed") | while read pkg; do
        [ -n "$pkg" ] && "$MANAGER_CMD" uninstall "$pkg" 2>/dev/null || true
      done
    '';
  };
}
