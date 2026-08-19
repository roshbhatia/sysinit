final: _prev:
let
  gotools = final.buildGoModule {
    pname = "sysinit-gotools";
    version = "0.1.0";

    src = ../pkgs;

    vendorHash = "sha256-DO7IxIK3RU9KPLgVrxoCdBRMek/71PZex63HNxXoPhU=";

    doCheck = true;

    nativeCheckInputs = [ final.git ];

    meta.platforms = final.lib.platforms.unix;
  };

  select =
    {
      pname,
      binary,
      names,
      meta,
    }:
    final.runCommand "${pname}-${gotools.version}"
      {
        inherit meta;
        passthru = { inherit gotools; };
      }
      ''
        mkdir -p "$out/bin"
        ${final.lib.concatMapStringsSep "\n" (name: ''
          ln -s "${gotools}/bin/${binary}" "$out/bin/${name}"
        '') names}
      '';
in
{
  inherit gotools;

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

  ask =
    let
      # pkgs/ask/wrappers.txt is the one list of the names the binary answers
      # to; pkgs/ask/main.go dispatches on the same names.
      wrappers = final.lib.filter (name: name != "") (
        final.lib.splitString "\n" (builtins.readFile ../pkgs/ask/wrappers.txt)
      );
    in
    final.runCommand "ask-${gotools.version}"
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
            ln -s "${gotools}/bin/ask" "$out/bin/$name"
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
    final.runCommand "utils-${gotools.version}"
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
        makeWrapper "${gotools}/bin/utils" "$out/bin/utils" \
          --prefix PATH : "${runtimePath}" \
          --set-default SYSINIT_PROSE_STYLE "${proseStyle}"
        ${final.lib.concatMapStringsSep "\n" (name: ''
          makeWrapper "${gotools}/bin/utils" "$out/bin/${name}" \
            --argv0 "${name}" \
            --prefix PATH : "${runtimePath}" \
            --set-default SYSINIT_PROSE_STYLE "${proseStyle}"
        '') links}
      '';
}
