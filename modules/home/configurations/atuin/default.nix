{
  lib,
  overlay,
  ...
}:
{
  imports = [
    (import ./atuin.nix {
      inherit lib overlay;
    })
  ];
}
