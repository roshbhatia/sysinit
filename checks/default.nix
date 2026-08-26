{
  pkgs,
  ...
}:
{
  editor-config = import ./editor-config.nix { inherit pkgs; };
  go-tests = pkgs.sysinit-gotools;
}
