{
  config,
  lib,
  values,
  utils,
  ...
}:

{
  imports = [
    (import ./krew.nix {
      inherit
        config
        lib
        values
        utils
        ;
    })
  ];
}
