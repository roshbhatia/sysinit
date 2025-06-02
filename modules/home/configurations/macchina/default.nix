{
  config,
  pkgs,
  ...
}:

{
  imports = [
    (import ./macchina.nix {
      inherit
        config
        pkgs
        ;
    })
  ];
}
