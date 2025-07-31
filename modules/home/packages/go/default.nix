{
  config,
  lib,
  values,
  utils,
  ...
}:

{
  imports = [
    (import ./go.nix {
      inherit
        config
        lib
        values
        utils
        ;
    })
  ];
}
