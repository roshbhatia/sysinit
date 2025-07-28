{
  lib,
  values,
  ...
}:

{
  imports = [
    (import ./npm.nix {
      inherit
        lib
        values
        ;
    })
    (import ./yarn.nix {
      inherit
        lib
        values
        ;
    })
  ];
}
