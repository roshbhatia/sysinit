final: _prev: {

  git-ai-gate = final.writeShellApplication {
    name = "git-ai-gate";
    runtimeInputs = [
      final.jq
      final.git-ai
    ];
    text = ''
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
      if [ -z "$raw" ]; then
        echo "git-ai-gate: missing native hook payload for $harness" >&2
        exit 1
      fi

      cwd=$(jq -r '.input.event.cwd // ""' <<<"$request")
      if [ -n "$cwd" ]; then cd "$cwd"; fi

      printf '%s' "$raw" | git-ai checkpoint "$preset" --hook-input stdin >&2
      emit_pass
    '';
  };
}
