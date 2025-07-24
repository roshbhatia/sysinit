{
  lib,
  values,
  ...
}:

{
  imports = [
    (import ./go.nix {
      inherit
        lib
        values
        ;
    })
  ];
}
