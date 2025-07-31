{
  lib,
  values,
  utils,
  ...
}:

{
  imports = [
    (import ./pipx.nix {
      inherit
        lib
        values
        utils
        ;
    })
    (import ./uvx.nix {
      inherit
        lib
        values
        utils
        ;
    })
  ];
}
