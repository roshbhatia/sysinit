{
  config,
  lib,
  values,
  utils,
  ...
}:

{
  imports = [
    (import ./pipx.nix {
      inherit
        config
        lib
        values
        utils
        ;
    })
    (import ./uvx.nix {
      inherit
        config
        lib
        values
        utils
        ;
    })
  ];
}
