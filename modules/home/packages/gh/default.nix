{
  lib,
  values,
  ...
}:

{
  imports = [
    (import ./gh.nix {
      inherit
        lib
        values
        ;
    })
  ];
}
