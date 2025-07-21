{
  lib,
  overlay,
  ...
}:
{
  imports = [
    (import ./k9s.nix {
      inherit
        lib
        overlay
        ;
    })
  ];
}
