{
  config,
  lib,
  overlay,
  pkgs,
  ...
}:
{
  imports = [
    ./aider
    ./atuin
    ./bat
    ./borders
    ./colima
    ./direnv
    (import ./git {
      inherit lib overlay;
    })
    ./hammerspoon
    ./k9s
    ./macchina
    ./mcp
    ./neovim
    ./omp
    ./wezterm
    (import ./zsh {
      inherit config lib pkgs;
    })
  ];
}
