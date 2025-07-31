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
    (import ./cargo.nix {
      inherit
        config
        lib
        pkgs
        values
        utils
        ;
    })
  ];
}
