{
  overlay,
  ...
}:

{
  imports = [
    (import ./git.nix {
      inherit
        overlay
        ;
    })
  ];
}
