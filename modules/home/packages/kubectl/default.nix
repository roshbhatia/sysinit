{
  lib,
  overlay,
  ...
}:

{
  imports = [
    (import ./krew.nix {
      inherit
        lib
        overlay
        ;
    })
  ];
}
