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

    ./aerospace
    ./aider
    ./atuin
    ./bat
    ./borders
    (import ./colima {
      inherit lib pkgs;
    })
    ./direnv
    ./k9s
    (import ./macchina {
      inherit config pkgs;
    })
    ./mcp
    ./neovim
    ./omp
    (import ./treesitter {
      inherit config lib pkgs;
    })
    ./wezterm
  ];
}

