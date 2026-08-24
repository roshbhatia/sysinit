{ inputs, ... }:

final: _prev:
let
  base = inputs.hermes-agent.packages.${final.stdenv.hostPlatform.system}.minimal.override {
    # otlp carries the OpenTelemetry SDK. Without it `hermes monitoring status`
    # reports "OTel SDK: not installed" and the monitoring.export.otlp keys are
    # inert. Only the gateway daemon emits, so a plain `hermes chat` still
    # produces nothing.
    extraDependencyGroups = [
      "anthropic"
      "otlp"
    ];
  };

  subagentBins = [
    "${final.claude-code}/bin"
    "${final.codex-acp}/bin"
    "${final.opencode}/bin"
    "${final.github-copilot-cli}/bin"
    "${final.gh}/bin"
    # antigravity-cli, not gemini-cli: nixpkgs marks gemini-cli 0.47.0 removed
    # upstream, and every other site in this repo already uses `agy`.
    "${final.antigravity-cli}/bin"
  ];
in
{
  hermes-agent = final.symlinkJoin {
    name = "hermes-agent-${base.version or "wrapped"}";
    paths = [ base ];
    nativeBuildInputs = [ final.makeWrapper ];

    postBuild = ''
      for bin in hermes hermes-agent hermes-acp; do
        if [ -L "$out/bin/$bin" ]; then
          target="$(readlink -f "$out/bin/$bin")"
          rm "$out/bin/$bin"
          makeWrapper "$target" "$out/bin/$bin" \
            --prefix PATH : ${final.lib.concatStringsSep ":" subagentBins}
        fi
      done
    '';

    meta = base.meta or { };
  };
}
