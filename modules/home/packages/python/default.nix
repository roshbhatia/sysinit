{
  lib,
  overlay,
  ...
}:

{
  imports = [
    (import ./pipx.nix {
      inherit
        lib
        overlay
        ;
    })
    (import ./uvx.nix {
      inherit
        lib
        overlay
        ;
    })
  ];
}
