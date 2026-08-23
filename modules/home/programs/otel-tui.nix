{
  lib,
  pkgs,
  ...
}:
let
  # otel-tui binds 0.0.0.0 by default, so its OTLP ports 4317 and 4318 accept
  # spans from the whole LAN. Only this machine produces them.
  otel-tui = pkgs.writeShellApplication {
    name = "otel-tui";
    text = ''
      exec ${lib.getExe pkgs.otel-tui} --host 127.0.0.1 "$@"
    '';
  };
in
{
  home.packages = [ otel-tui ];
}
