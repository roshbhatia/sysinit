{
  config,
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./neovim.nix {
      inherit config lib values;
    })
  ];
}
