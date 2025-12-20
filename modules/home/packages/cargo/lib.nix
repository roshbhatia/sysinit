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
  };
}
