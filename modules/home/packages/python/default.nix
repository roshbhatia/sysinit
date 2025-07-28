{
  lib,
  values,
  ...
}:

{
  imports = [
    (import ./pipx.nix {
      inherit
        lib
        values
        ;
    })
    (import ./uvx.nix {
      inherit
        lib
        values
        ;
    })
  ];
}
