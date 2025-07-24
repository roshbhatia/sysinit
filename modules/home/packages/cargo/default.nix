{
  lib,
  values,
  ...
}:

{
  imports = [
    (import ./cargo.nix {
      inherit
        lib
        values
        ;
    })
  ];
}
