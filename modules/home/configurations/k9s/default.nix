{
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./k9s.nix {
      inherit
        lib
        values
        ;
    })
  ];
}
