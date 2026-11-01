{ pkgs }:
pkgs.writeShellApplication {
  name = "agent-diff";
  runtimeInputs = [
    pkgs.python3
    pkgs.git
    pkgs.wezterm
  ];
  text = ''
    exec python3 ${./open.py} "$@"
  '';
}
