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

    # The file exporter is a contrib component; the core distribution does not
    # carry it. It writes one OTLP JSON request per line, which is the only
    # on-disk shape otel-tui can read back.
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
      # The collector serves its own Prometheus metrics on 8888 by default, and
      # otel-tui wants that same port. Nothing here reads them.
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

  otelCollector = pkgs.writeShellApplication {
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

  # Every harness that speaks OTLP reads this one variable, so the collector
  # publishes it rather than each harness module repeating the endpoint. The
  # protocol is left unset so each exporter keeps its own default; the receiver
  # above takes both protobuf and JSON on 4318.
  home.sessionVariables.OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318";

  # Both are declared on both hosts. home-manager gates each on its own `enable`,
  # which already defaults to the platform that owns it, so the one that does not
  # apply writes nothing.
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
