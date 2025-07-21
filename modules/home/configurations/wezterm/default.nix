{
  lib,
  overlay,
  ...
}:
{
  imports = [
    (import ./wezterm.nix {
      inherit lib overlay;
    })
  ];
}
