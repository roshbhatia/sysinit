{
  lib,
  values,
  utils,
  ...
}:

{
  imports = [
    (import ./go.nix {
      inherit
        lib
        values
        utils
        ;
    })
  ];
}
