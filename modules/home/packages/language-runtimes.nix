{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Language runtimes installed system-wide
    # Projects can override via shell.nix/flake.nix for specific versions

    bun
    go
    nodejs_22
    python311

    # Lua runtime & libraries (for neovim, wezterm, hammerspoon configs)
    hererocks
    luajit
    lua54Packages.cjson

    # Rust toolchain management via rustup
    # Additional cargo tools
    cargo-watch
    delve

    # JavaScript/TypeScript tools
    typescript
    yarn
  ];
}
