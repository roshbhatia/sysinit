{
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./git.nix {
      inherit lib values;
    })
  ];
}

