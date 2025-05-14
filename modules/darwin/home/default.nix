{
  config,
  pkgs,
  lib,
  inputs,
  username,
  homeDirectory,
  userConfig ? { },
  ...
}:

{
  imports = [
    ./aider/aider.nix
    ./atuin/atuin.nix
    ./colima/colima.nix
    ./git/git.nix
    ./k9s/k9s.nix
    ./macchina/macchina.nix
    ./mcphub/mcphub.nix
    ./neovim/neovim.nix
    ./omp/omp.nix
    ./wezterm/wezterm.nix
    ./zsh/zsh.nix
    ./borders/borders.nix

    ./core/packages.nix
    ./cargo/cargo.nix
    ./node/npm.nix
    ./node/yarn.nix
    ./python/pipx.nix
    ./python/uvx.nix
    ./go/go.nix
    ./gh/gh.nix
    ./krew/krew.nix
  ];
}

