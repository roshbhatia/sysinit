{
  lib,
  overlay,
  ...
}:

{
  imports = [
    (import ./npm.nix {
      inherit
        lib
        overlay
        ;
    })
    (import ./yarn.nix {
      inherit
        lib
        overlay
        ;
    })
  ];
}
