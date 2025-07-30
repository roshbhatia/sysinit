{
  config,
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./wezterm.nix {
      inherit config lib values;
    })
  ];
}
