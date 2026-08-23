{
  lib,
  pkgs,
  config,
  ...
}:
let
  telemetryFile = config.sysinit.paths.resolved.otelTelemetry;

  # The collector owns 4317, 4318 and the OTLP traffic; otel-tui reads what the
  # collector wrote. It still opens receivers of its own, so they move off the
  # collector's ports, off 8888, and off 0.0.0.0.
  otel-tui = pkgs.writeShellApplication {
    name = "otel-tui";
    text = ''
      mkdir -p "$(dirname '${telemetryFile}')"
      touch '${telemetryFile}'
      exec ${lib.getExe pkgs.otel-tui} \
        --host 127.0.0.1 \
        --grpc 14317 \
        --http 14318 \
        --disable-internal-metrics \
        --from-json-file '${telemetryFile}' "$@"
    '';
  };
in
{
  home.packages = [ otel-tui ];
}
