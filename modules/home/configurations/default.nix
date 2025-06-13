{
  config,
  lib,
  overlay,
  pkgs,
  ...
}:
{
  imports = [
    (import ./zsh {
      inherit config lib pkgs;
    })
    (import ./git {
      inherit lib overlay;
    })

    ./aider
    ./atuin
    ./bat
    ./borders
    ./colima
    ./direnv
    ./hammerspoon
    ./k9s
    (import ./macchina {
      inherit config pkgs;
    })
    ./mcp
    ./neovim
    ./omp
    ./wezterm
  ];
}

