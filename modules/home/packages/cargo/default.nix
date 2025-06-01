{
  lib,
  overlay,
  ...
}:

{
  imports = [
    (import ./cargo.nix {
      inherit
        lib
        overlay
        ;
    })
  ];
}
