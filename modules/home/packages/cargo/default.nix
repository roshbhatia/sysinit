{
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
        lib
        pkgs
        values
        utils
        ;
    })
  ];
}
