{ inputs, ... }:

# Hermes Agent — consume the upstream flake's prebuilt package.
#
# Upstream (NousResearch/hermes-agent) builds the agent via uv2nix and
# bundles the Ink/React TUI (`ui-tui/dist/entry.js`), web assets, skills,
# plugins, anthropic SDK, and runtime deps (Node, git, ripgrep, ffmpeg).
# Their wrapper sets HERMES_TUI_DIR / HERMES_BUNDLED_SKILLS automatically.
#
# We add a thin re-wrap to prepend the subagent CLIs (claude-code, codex-acp,
# opencode, github-copilot-cli, gh, gemini-cli) so any hermes session can
# delegate to them regardless of the user's shell PATH.
#
# Bumping the pin: change the `v<date>` ref in flake.nix's hermes-agent input,
# then `nix flake lock --update-input hermes-agent`.

final: _prev:
let
  base = inputs.hermes-agent.packages.${final.stdenv.hostPlatform.system}.default;

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

    # Re-wrap the three upstream entrypoints (hermes, hermes-agent,
    # hermes-acp). symlinkJoin links them as symlinks into $out/bin/; we
    # then replace each symlink with a wrapper that prepends subagent PATH.
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
