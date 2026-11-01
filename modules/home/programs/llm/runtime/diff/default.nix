{ pkgs }:
pkgs.writeShellApplication {
  name = "agent-diff";
  runtimeInputs = [
    pkgs.python3
    pkgs.git
    pkgs.tmux
    pkgs.sysinit-utils
  ];
  text = ''
    exec python3 ${./open.py} "$@"
  '';
}
