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
      inherit
        config
        lib
        overlay
        pkgs
        ;
    })
    (import ./git {
      inherit lib overlay;
    })
    ./aerospace
    ./aider
    (import ./atuin {
      inherit lib overlay;
    })
    (import ./bat {
      inherit lib overlay;
    })
    ./borders
    (import ./colima {
      inherit lib pkgs;
    })
    ./direnv
    (import ./k9s {
      inherit lib overlay;
    })
    (import ./macchina {
      inherit config pkgs;
    })
    ./mcp
    (import ./neovim {
      inherit config lib overlay;
    })
    (import ./omp {
      inherit lib overlay;
    })
    (import ./treesitter {
      inherit config lib pkgs;
    })
    (import ./wezterm {
      inherit lib overlay;
    })
  ];
}

