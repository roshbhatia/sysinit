final: _prev: {
  utils =
    let
      # Mirrored in `pkgs/utils/main.go`, which dispatches on `argv[0]`. A name in one
      # and not the other either installs nothing or installs a name that runs the
      # multiplexer's usage text.
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

      # A hook runs with the harness's own PATH, and these are what the commands shell
      # out to. Not wezterm: naming it here would put a terminal in the closure of every
      # host that installs these commands, so `worker` relies on the WezTerm session it
      # only ever runs inside, and `wezspawn`'s caller prepends the path it wants.
      runtimePath = final.lib.makeBinPath [
        final.git
        final.curl
      ];
    in
    final.buildGoModule {
      pname = "utils";
      version = "0.1.0";

      src = ../pkgs/utils;

      # null, not a hash.
      vendorHash = null;

      # A compiled wrapper rather than a shell one, so a hook that fires on every tool
      # call reaches the binary without forking a shell first.
      nativeBuildInputs = [ final.makeBinaryWrapper ];

      # The tests build real working trees: the store path is derived from
      nativeCheckInputs = [ final.git ];
      preCheck = ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
      '';

      # One name per command, each carrying its own `argv[0]`, which is what the binary
      # dispatches on.
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
