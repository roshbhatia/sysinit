{ pkgs }:
pkgs.writeShellApplication {
  name = "agent-workspace";
  runtimeInputs = [
    (import ../diff { inherit pkgs; })
    pkgs.bun
    pkgs.changes
    pkgs.changes-provider-local-notes
    pkgs.coreutils
    pkgs.git
    pkgs.seshy
    pkgs.wezterm
  ];
  text = ''
    export SYSINIT_AGENT_WORKSPACE_BIN="$0"
    exec ${pkgs.nushell}/bin/nu --no-config-file ${./.}/workspace.nu "$@"
  '';
}
