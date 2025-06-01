{
  lib,
  overlay,
  ...
}:

{
  imports = [
    (import ./gh.nix {
      inherit
        lib
        overlay
        ;
    })
  ];
}
