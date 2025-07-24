{
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./atuin.nix {
      inherit lib values;
    })
  ];
}
