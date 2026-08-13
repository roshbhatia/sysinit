{ inputs, ... }:

# `minimal` rather than `default`: `default` is `minimal` plus 20 extras including
# `voice`, which pulls faster-whisper and its wheel-only ctranslate2/onnxruntime
# transitives.

final: _prev:
let
  base = inputs.hermes-agent.packages.${final.stdenv.hostPlatform.system}.minimal.override {
    extraDependencyGroups = [ "anthropic" ];
  };

  subagentBins = [
    "${final.claude-code}/bin"
    "${final.codex-acp}/bin"
    "${final.opencode}/bin"
    "${final.github-copilot-cli}/bin"
    "${final.gh}/bin"
    "${final.gemini-cli}/bin"
  ];
in
{
  hermes-agent = final.symlinkJoin {
    name = "hermes-agent-${base.version or "wrapped"}";
    paths = [ base ];
    nativeBuildInputs = [ final.makeWrapper ];

    # Prefix, not suffix: a hermes session must resolve the Nix-managed subagent
    # even when the parent environment has its own on PATH.
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
