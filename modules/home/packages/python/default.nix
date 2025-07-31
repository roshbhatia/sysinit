{
  lib,
  values,
  utils,
  ...
}:

{
  imports = [
    (import ./aider.nix {
      inherit
        lib
        values
        utils
        ;
    })
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
