{
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./nu.nix {
      inherit
        lib
        values
        ;
    })
  ];
}

