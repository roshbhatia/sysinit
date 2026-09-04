{
  pkgs,
  ...
}:
let
  commandPath = import ../modules/shared/command-path.nix { inherit (pkgs) lib; };
  darwinPath = commandPath.entriesFor true "/profile/bin";
  linuxPath = commandPath.entriesFor false "/profile/bin";

  mcpCatalog = import ../modules/home/programs/llm/lib/mcp-catalog.nix {
    inherit (pkgs) lib;
    additionalServers = {
      kept = {
        command = "kept";
        args = [ ];
      };
      suppressed = {
        command = "suppressed";
        args = [ ];
      };
    };
    harnessSuppressedServers.amp = [ "suppressed" ];
  };
  mcp = import ../modules/home/programs/llm/lib/mcp.nix { inherit (pkgs) lib; };
  ampMcpServers = mcp.formatForAmp (mcpCatalog.serversFor "amp");
in
assert builtins.elemAt darwinPath 3 == "/opt/homebrew/bin";
assert builtins.elemAt darwinPath 4 == "/opt/homebrew/sbin";
assert builtins.elemAt darwinPath 5 == "/usr/local/bin";
assert !(builtins.elem "/opt/homebrew/bin" linuxPath);
assert ampMcpServers.kept.command == "kept";
assert !(ampMcpServers ? suppressed);
{
  command-path-order = pkgs.runCommand "command-path-order" { } ''
    touch $out
  '';
  editor-config = import ./editor-config.nix { inherit pkgs; };
  closed-lid-ssh = import ./closed-lid-ssh.nix { inherit pkgs; };
  go-tests = pkgs.sysinit-gotools;
  orc-no-startup-units = pkgs.runCommand "orc-no-startup-units" { } ''
    test ! -e ${pkgs.orc-cli}/etc/systemd
    test ! -e ${pkgs.orc-cli}/lib/systemd
    test ! -e ${pkgs.orc-cli}/Library/LaunchAgents
    test ! -e ${pkgs.orc-cli}/Library/LaunchDaemons
    touch $out
  '';
}
