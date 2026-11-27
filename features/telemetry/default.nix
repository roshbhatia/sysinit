{
  flake.modules.homeManager = {
    otelCollector = ./otel-collector.nix;
    otelTui = ./otel-tui.nix;
    traces = ./traces.nix;
  };
}
