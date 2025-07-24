{
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./wezterm.nix {
      inherit lib values;
    })
  ];
}
