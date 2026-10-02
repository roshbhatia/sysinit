{ inputs, ... }:

final: _prev:
let
  upstream = inputs.hermes-agent.packages.${final.stdenv.hostPlatform.system}.minimal;
  base = upstream.override {

    stdenv = upstream.stdenv // {
      inherit (upstream.stdenv.hostPlatform) isLinux;
    };

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
