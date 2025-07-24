{
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./bat.nix {
      inherit lib values;
    })
  ];
}
