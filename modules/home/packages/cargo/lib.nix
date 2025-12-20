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
      comm -23 <(ls "$HOME/.cargo/bin" 2>/dev/null | sort) <(sort "$managed_pkg_file") | while read bin; do
        rm -f "$HOME/.cargo/bin/$bin"
      done
    '';
  };
}
