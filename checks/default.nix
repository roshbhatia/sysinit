{
  pkgs,
  ...
}:
{
  editor-config = import ./editor-config.nix { inherit pkgs; };
  go-tests = pkgs.sysinit-gotools;
  orc-no-startup-units = pkgs.runCommand "orc-no-startup-units" { } ''
    test ! -e ${pkgs.orc}/etc/systemd
    test ! -e ${pkgs.orc}/lib/systemd
    test ! -e ${pkgs.orc}/Library/LaunchAgents
    test ! -e ${pkgs.orc}/Library/LaunchDaemons
    touch $out
  '';
}
