final: _prev: {
  # A gate provider that turns a PostToolUse edit event into a git-ai checkpoint,
  # so the edit's lines are attributed to the agent in refs/notes/ai. It speaks
  # provider/v1 gate.decide: it reads the request frame, checkpoints as a side
  # effect, and always answers pass. A checkpoint must never block an edit, so
  # every step that can fail is swallowed.
  git-ai-gate = final.writeShellApplication {
    name = "git-ai-gate";
    runtimeInputs = [
      final.jq
      final.git-ai
    ];
    text = ''
      # Only the serve verb exists; the manifest always passes it.
      if [ "''${1:-}" != "serve" ]; then
        echo "git-ai-gate: expected 'serve'" >&2
        exit 2
      fi

      request=$(cat)
      requestId=$(jq -r '.requestId // ""' <<<"$request")

      emit_pass() {
        jq -cn --arg id "$requestId" \
          '{version:"provider/v1",kind:"result",requestId:$id,status:"ok",output:{decision:"pass"}}'
      }

      harness=$(jq -r '.input.event.harness // ""' <<<"$request")

      # git-ai's checkpoint presets each parse one harness's native hook payload,
      # which gate carries through unchanged as .input.event.raw. Map only the
      # harnesses git-ai has a preset for; pass the rest untouched.
      case "$harness" in
        claude) preset=claude ;;
        codex) preset=codex ;;
        cursor) preset=cursor ;;
        gemini) preset=gemini ;;
        amp) preset=amp ;;
        opencode) preset=opencode ;;
        pi) preset=pi ;;
        copilot) preset=github-copilot ;;
        *) emit_pass; exit 0 ;;
      esac

      raw=$(jq -c '.input.event.raw // empty' <<<"$request")
      if [ -z "$raw" ]; then emit_pass; exit 0; fi

      cwd=$(jq -r '.input.event.cwd // ""' <<<"$request")
      if [ -n "$cwd" ] && [ -d "$cwd" ]; then cd "$cwd" || true; fi

      printf '%s' "$raw" | git-ai checkpoint "$preset" --hook-input stdin >/dev/null 2>&1 || true
      emit_pass
    '';
  };
}
