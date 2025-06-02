{
  pkgs,
  ...
}:

{
  imports = [
    (import ./macchina.nix {
      inherit
        pkgs
        ;
    })
  ];
}
