{
  lib,
  values,
  utils,
  ...
}:

{
  imports = [
    (import ./krew.nix {
      inherit
        lib
        values
        utils
        ;
    })
  ];
}
