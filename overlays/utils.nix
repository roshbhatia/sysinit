final: _prev: {
  utils =
    let
      links = [
        "agent-edit-event"
        "agent-note-open"
        "agent-state"
        "agent-statusline"
        "agent-watch"
        "bash-guard"
        "citelock"
        "exit-code-guard"
        "firefox-tabs"
        "loop-gate"
        "nix-guard"
        "note"
        "transcript-link"
        "wezspawn"
        "worker"
        "worklog"
        "ws"
      ];

      runtimePath = final.lib.makeBinPath [
        final.git
        final.curl
      ];
    in
    final.buildGoModule {
      pname = "utils";
      version = "0.1.0";

      src = ../pkgs/utils;

      vendorHash = null;

      nativeBuildInputs = [ final.makeBinaryWrapper ];

      nativeCheckInputs = [ final.git ];
      preCheck = ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
      '';

      postInstall = ''
        mv "$out/bin/utils" "$out/bin/.utils-real"
        makeWrapper "$out/bin/.utils-real" "$out/bin/utils" \
          --prefix PATH : "${runtimePath}"
        ${final.lib.concatMapStringsSep "\n" (name: ''
          makeWrapper "$out/bin/.utils-real" "$out/bin/${name}" \
            --argv0 "${name}" \
            --prefix PATH : "${runtimePath}"
        '') links}
      '';

      meta = {
        description = "The commands that used to be shell scripts, one binary and one name each";
        mainProgram = "utils";
        platforms = final.lib.platforms.unix;
      };
    };
}
