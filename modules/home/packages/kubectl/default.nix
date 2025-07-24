{
  lib,
  values,
  ...
}:

{
  imports = [
    (import ./krew.nix {
      inherit
        lib
        values
        ;
    })
  ];
}
