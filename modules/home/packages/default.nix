{
  config,
  lib,
  pkgs,
  values,
  utils,
  ...
}:
{
  imports = [
    (import ./nixpkgs {
      inherit config values pkgs;
    })
    (import ./cargo {
      inherit
        config
        lib
        pkgs
        values
        utils
        ;
    })
    (import ./gh {
      inherit
        config
        lib
        values
        utils
        ;
    })
    (import ./go {
      inherit
        config
        lib
        values
        utils
        ;
    })
    (import ./kubectl {
      inherit
        config
        lib
        values
        utils
        ;
    })
    (import ./node {
      inherit
        config
        lib
        values
        utils
        ;
    })
    (import ./python {
      inherit
        config
        lib
        values
        utils
        ;
    })
  ];
}
