{
  config,
  overlay,
  pkgs,
  ...
}:
{
  imports = [
    (import ./nixpkgs.nix {
      inherit config overlay pkgs;
    })
  ];
}
