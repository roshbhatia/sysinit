{
  lib,
  overlay,
  ...
}:
{
  imports = [
    (import ./git.nix {
      inherit lib overlay;
    })
  ];
}
