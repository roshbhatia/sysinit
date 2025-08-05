{
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./borders.nix {
      inherit
        lib
        values
        ;
    })
  ];
}

