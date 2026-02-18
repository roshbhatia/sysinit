{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Language runtimes
    # These are installed system-wide on macOS and persistent VM
    # Projects can override via shell.nix for specific versions

    bun
    go
    nodejs_22
    python311

    # Rust (rustup provides toolchain, including cargo/rustc)
    # Note: Some tools like cargo-watch require being installed separately
    cargo-watch
    delve

    # Additional language tools
    typescript
    yarn
  ];
}
