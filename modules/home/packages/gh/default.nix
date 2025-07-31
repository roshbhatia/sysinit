{
  config,
  lib,
  values,
  utils,
  ...
}:

{
  imports = [
    (import ./gh.nix {
      inherit
        config
        lib
        values
        utils
        ;
    })
  ];
}
