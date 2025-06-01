{
  lib,
  overlay,
  ...
}:

{
  imports = [
    (import ./go.nix {
      inherit
        lib
        overlay
        ;
    })
  ];
}
