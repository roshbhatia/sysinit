{ pkgs }:
let
  source = import ./source.nix { inherit (pkgs) lib; };
in
pkgs.writeShellApplication {
  name = "agent-workspace";
  runtimeInputs = [
    pkgs.agent-diff
    pkgs.bun
    pkgs.changes
    pkgs.changes-provider-local-notes
    pkgs.coreutils
    pkgs.git
    pkgs.sysinit-ty
    pkgs.seshy
    pkgs.wezterm
  ];
  text = ''
    export SYSINIT_AGENT_WORKSPACE_BIN="$0"
    exec ${pkgs.nushell}/bin/nu --no-config-file ${source}/features/workspace/workspace.nu "$@"
  '';
}
