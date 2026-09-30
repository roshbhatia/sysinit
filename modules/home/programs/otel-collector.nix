{
  lib,
  pkgs,
  config,
  ...
}:
let
  telemetryFile = config.sysinit.paths.resolved.otelTelemetry;

  format = pkgs.formats.yaml { };

  collectorConfig = format.generate "otelcol-config.yaml" {
    receivers.otlp.protocols = {
      grpc.endpoint = "127.0.0.1:4317";
      http.endpoint = "127.0.0.1:4318";
    };

    exporters.file = {
      path = telemetryFile;
      format = "json";
      flush_interval = "1s";
      rotation = {
        max_megabytes = 64;
        max_days = 7;
        max_backups = 2;
        localtime = true;
      };
    };

    service = {

      telemetry.metrics.level = "none";
      pipelines = {
        traces = {
          receivers = [ "otlp" ];
          exporters = [ "file" ];
        };
        logs = {
          receivers = [ "otlp" ];
          exporters = [ "file" ];
        };
        metrics = {
          receivers = [ "otlp" ];
          exporters = [ "file" ];
        };
      };
    };
  };

  otelCollector = pkgs.sysinit.writeShellApplication {
    name = "otel-collector";
    text = ''
      mkdir -p "$(dirname '${telemetryFile}')"
      exec ${pkgs.opentelemetry-collector-contrib}/bin/otelcol-contrib \
        --config ${collectorConfig} "$@"
    '';
  };
in
{
  home.packages = [ otelCollector ];

  home.sessionVariables.OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318";

  launchd.agents.otel-collector = {
    enable = true;
    config = {
      ProgramArguments = [ "${lib.getExe otelCollector}" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/otel-collector.log";
      StandardErrorPath = "/tmp/otel-collector.error.log";
    };
  };

  systemd.user.services.otel-collector = {
    Unit.Description = "OpenTelemetry collector, the on-disk store behind otel-tui";
    Service = {
      ExecStart = "${lib.getExe otelCollector}";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
