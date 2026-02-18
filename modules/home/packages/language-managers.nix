{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Language version managers
    rustup # Rust toolchain manager
    uv # Python version/package manager
    pipx # Python app installer
  ];
}
