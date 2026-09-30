{
  lib,
  pkgs,
  config,
  ...
}:
let
  telemetryFile = config.sysinit.paths.resolved.otelTelemetry;

  otel-tui = pkgs.sysinit.writeShellApplication {
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
