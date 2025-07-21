{
  config,
  lib,
  overlay,
  ...
}:
{
  imports = [
    (import ./neovim.nix {
      inherit config lib overlay;
    })
  ];
}
