{
  lib,
  overlay,
  ...
}:
{
  imports = [
    (import ./bat.nix {
      inherit lib overlay;
    })
  ];
}
