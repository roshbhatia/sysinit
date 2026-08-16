final: _prev: {
  sysinit-utils =
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
        "lint-gate"
        "loop-gate"
        "nix-guard"
        "note"
        "prose-gate"
        "read-guard"
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

      # There are no tests to run. This package is first-party and absent from
      # nixpkgs, so Hydra never caches it and skipping the check phase costs
      # nothing: the cache concern in AGENTS.md applies to overridden nixpkgs
      # derivations, not to this one.
      doCheck = false;

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
