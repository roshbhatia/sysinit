final: _prev:
let
  # Not `gotools`. That name is taken by the nixpkgs package holding goimports
  # and godoc, which modules/home/packages.nix installs.
  sysinit-gotools = final.buildGoModule {
    pname = "sysinit-gotools";
    version = "0.1.0";

    src = ../pkgs;

    vendorHash = "sha256-EOg+81XREEckJekm0YePGZsrPbuP8EZnCknP1p+Oacc=";

    # No tests in this repository, so the check phase would run nothing.
    doCheck = false;

    meta.platforms = final.lib.platforms.unix;
  };

  select =
    {
      pname,
      binary,
      names,
      meta,
    }:
    final.runCommand "${pname}-${sysinit-gotools.version}"
      {
        inherit meta;
        passthru = { inherit sysinit-gotools; };
      }
      ''
        mkdir -p "$out/bin"
        ${final.lib.concatMapStringsSep "\n" (name: ''
          ln -s "${sysinit-gotools}/bin/${binary}" "$out/bin/${name}"
        '') names}
      '';
in
{
  inherit sysinit-gotools;

  seshy = select {
    pname = "seshy";
    binary = "seshy";
    names = [
      "sy"
      "seshy"
    ];
    meta = {
      description = "Minimal session manager for multi-repo, worktree-based work";
      mainProgram = "sy";
      platforms = final.lib.platforms.unix;
    };
  };

  specutil = select {
    pname = "specutil";
    binary = "specutil";
    names = [ "specutil" ];
    meta = {
      description = "Project spec-framework change artifacts into other artifacts and visualizations";
      mainProgram = "specutil";
      platforms = final.lib.platforms.unix;
    };
  };

  changes =
    let
      # Each of the three is one layer of the view. Without ast-grep the hunks
      # stop grouping under their symbol, and without calldiff the symbol rows
      # lose their call counts, both silently. The wrapper is what keeps a
      # caller's PATH from deciding how much of the view renders.
      runtimePath = final.lib.makeBinPath [
        final.git
        final.ast-grep
        final.calldiff
      ];
    in
    final.runCommand "changes-${sysinit-gotools.version}"
      {
        nativeBuildInputs = [ final.makeBinaryWrapper ];
        meta = {
          description = "A diff read as a symbol tree, with the call edges the edit moved";
          mainProgram = "changes";
          platforms = final.lib.platforms.unix;
        };
      }
      ''
        mkdir -p "$out/bin"
        makeWrapper "${sysinit-gotools}/bin/changes" "$out/bin/changes" \
          --prefix PATH : "${runtimePath}"
      '';

  reel = select {
    pname = "reel";
    binary = "reel";
    names = [ "reel" ];
    meta = {
      description = "Agent trace view over the local OTLP collector's spans";
      mainProgram = "reel";
      platforms = final.lib.platforms.unix;
    };
  };

  ask =
    let
      # pkgs/ask/wrappers.txt is the one list of the names the binary answers
      # to; pkgs/ask/main.go dispatches on the same names.
      wrappers = final.lib.filter (name: name != "") (
        final.lib.splitString "\n" (builtins.readFile ../pkgs/ask/wrappers.txt)
      );
    in
    final.runCommand "ask-${sysinit-gotools.version}"
      {
        nativeBuildInputs = [ final.installShellFiles ];
        meta = {
          description = "Agents in your shell!";
          mainProgram = "ask";
          platforms = final.lib.platforms.unix;
        };
      }
      (
        ''
          mkdir -p "$out/bin"
          for name in ask ${final.lib.escapeShellArgs wrappers}; do
            ln -s "${sysinit-gotools}/bin/ask" "$out/bin/$name"
          done
        ''
        + final.lib.optionalString (final.stdenv.buildPlatform.canExecute final.stdenv.hostPlatform) ''
          for name in ask ${final.lib.escapeShellArgs wrappers}; do
            installShellCompletion --cmd "$name" \
              --bash <("$out/bin/$name" completion bash) \
              --zsh <("$out/bin/$name" completion zsh)
          done
        ''
      );

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
        # prose-gate shells out to vale for the whole rule set. Without it on
        # PATH the gate passes every reply.
        final.vale
      ];

      proseStyle = "${final.vale-styles}/vale.ini";
    in
    final.runCommand "utils-${sysinit-gotools.version}"
      {
        nativeBuildInputs = [ final.makeBinaryWrapper ];
        meta = {
          description = "The commands that used to be shell scripts, one binary and one name each";
          mainProgram = "utils";
          platforms = final.lib.platforms.unix;
        };
      }
      ''
        mkdir -p "$out/bin"
        makeWrapper "${sysinit-gotools}/bin/utils" "$out/bin/utils" \
          --prefix PATH : "${runtimePath}" \
          --set-default SYSINIT_PROSE_STYLE "${proseStyle}"
        ${final.lib.concatMapStringsSep "\n" (name: ''
          makeWrapper "${sysinit-gotools}/bin/utils" "$out/bin/${name}" \
            --argv0 "${name}" \
            --prefix PATH : "${runtimePath}" \
            --set-default SYSINIT_PROSE_STYLE "${proseStyle}"
        '') links}
      '';
}
