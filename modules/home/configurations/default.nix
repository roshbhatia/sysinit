{
  config,
  lib,
  values,
  pkgs,
  utils,
  ...
}:

{
  imports = [
    ./aerospace
    ./borders
    ./direnv
    ./llm
    ./vivid

    (import ./atuin {
      inherit
        lib
        values
        ;
    })
    (import ./bat {
      inherit
        lib
        pkgs
        values
        utils
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
    (import ./helix {
      inherit
        config
        lib
        pkgs
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
