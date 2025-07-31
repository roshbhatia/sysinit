{
  lib,
  values,
  utils,
  ...
}:

{
  imports = [
    (import ./cargo.nix {
      inherit
        lib
        values
        utils
        ;
    })
  ];
}
