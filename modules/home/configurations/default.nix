# modules/home/configurations/default.nix
# Purpose: Aggregates all home-manager configurations
# Provides consistent parameter passing and module organization

{
  config,
  lib,
  values,
  pkgs,
  ...
}:

{
  imports = [
    # Simple modules (no parameters needed)
    ./aerospace
    ./aider
    ./borders
    ./carapace
    ./direnv
    ./mcp

    # Parameterized modules (explicit inheritance)
    (import ./atuin {
      inherit
        lib
        values
        ;
    })
    (import ./bat {
      inherit
        lib
        values
        ;
    })
    (import ./colima {
      inherit
        lib
        pkgs
        ;
    })
    (import ./git {
      inherit
        lib
        values
        ;
    })
    (import ./k9s {
      inherit
        lib
        values
        ;
    })
    (import ./macchina {
      inherit
        config
        pkgs
        ;
    })
    (import ./neovim {
      inherit
        config
        lib
        values
        ;
    })
    (import ./nu {
      inherit
        config
        lib
        values
        pkgs
        ;
    })
    (import ./omp {
      inherit
        lib
        values
        ;
    })
    (import ./treesitter {
      inherit
        config
        lib
        pkgs
        ;
    })
    (import ./utils {
      inherit
        pkgs
        ;
    })
    (import ./wezterm {
      inherit
        config
        lib
        values
        ;
    })
    (import ./zsh {
      inherit
        config
        lib
        values
        pkgs
        ;
    })
  ];
}
