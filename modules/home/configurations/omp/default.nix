{
  lib,
  overlay,
  ...
}:
{
  imports = [
    (import ./omp.nix {
      inherit lib overlay;
    })
  ];
}
