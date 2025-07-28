{
  config,
  lib,
  values,
  pkgs,
  ...
}:
{
  imports = [
    (import ./zsh {
      inherit
        config
        lib
        values
        pkgs
        ;
    })
    (import ./nushell {
      inherit config lib values pkgs;
    })
    (import ./git {
      inherit lib values;
    })
    ./aerospace
    ./aider
    (import ./atuin {
      inherit lib values;
    })
    (import ./bat {
      inherit lib values;
    })
    ./borders
    (import ./colima {
      inherit lib pkgs;
    })
    ./direnv
    (import ./k9s {
      inherit lib values;
    })
    (import ./macchina {
      inherit config pkgs;
    })
    ./mcp
    (import ./neovim {
      inherit config lib values;
    })
    (import ./omp {
      inherit lib values;
    })
    (import ./treesitter {
      inherit config lib pkgs;
    })
    (import ./wezterm {
      inherit lib values;
    })
  ];
}
