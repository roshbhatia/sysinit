{
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./omp.nix {
      inherit lib values;
    })
  ];
}
