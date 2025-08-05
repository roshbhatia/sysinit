{
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./sketchybar.nix {
      inherit lib values;
    })
  ];
}
