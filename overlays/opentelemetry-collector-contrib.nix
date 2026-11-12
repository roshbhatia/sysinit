final: prev: {
  # cockroachdb/swiss in this release excludes Go 1.27 via its runtime build tag.
  opentelemetry-collector-contrib =
    if prev.opentelemetry-collector-contrib.version == "0.155.0" then
      (prev.opentelemetry-collector-releases.override {
        buildGoModule = final.buildGo126Module;
      }).otelcol-contrib
    else
      prev.opentelemetry-collector-contrib;
}
