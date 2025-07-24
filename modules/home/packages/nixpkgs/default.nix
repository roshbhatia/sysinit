{
  config,
  values,
  pkgs,
  ...
}:
{
  imports = [
    (import ./nixpkgs.nix {
      inherit config values pkgs;
    })
  ];
}
