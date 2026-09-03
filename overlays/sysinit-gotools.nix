{ inputs }:
final: _prev:
let
  # Not `gotools`. That name is taken by the nixpkgs package holding goimports
  # and godoc, which modules/home/packages.nix installs.
  sysinit-gotools = final.buildGoModule {
    pname = "sysinit-gotools";
    version = "0.1.0";

    src = ../pkgs;

    vendorHash = "sha256-dnGhWezb1M8h1hRA8EUMMe838vo6nLOKndYRgVIPjwo=";

    nativeCheckInputs = [ final.git ];

    meta.platforms = final.lib.platforms.unix;
  };

  select =
    {
      pname,
      package,
      binary,
      names,
      completionNames ? [ ],
      meta,
    }:
    final.runCommand "${pname}-${sysinit-gotools.version}"
      {
        inherit meta;
        nativeBuildInputs = final.lib.optional (completionNames != [ ]) final.installShellFiles;
        passthru = { inherit package; };
      }
      (
        ''
          mkdir -p "$out/bin"
          ${final.lib.concatMapStringsSep "\n" (name: ''
            ln -s "${package}/bin/${binary}" "$out/bin/${name}"
          '') names}
          if [ -d "${package}/share" ]; then
            mkdir -p "$out/share"
            cp -rs "${package}/share/." "$out/share/"
          fi
        ''
        +
          final.lib.optionalString
            (completionNames != [ ] && final.stdenv.buildPlatform.canExecute final.stdenv.hostPlatform)
            ''
              for name in ${final.lib.escapeShellArgs completionNames}; do
                bash_completion="$TMPDIR/$name.bash"
                zsh_completion="$TMPDIR/_$name"
                HOME="$TMPDIR" "${package}/bin/${binary}" completion bash > "$bash_completion"
                HOME="$TMPDIR" "${package}/bin/${binary}" completion zsh > "$zsh_completion"
                installShellCompletion --cmd "$name" \
                  --bash "$bash_completion" \
                  --zsh "$zsh_completion"
              done
            ''
      );
in
{
  inherit sysinit-gotools;

  seshy = select {
    pname = "seshy";
    package = final.seshy-cli;
    binary = "sy";
    names = [
      "sy"
      "seshy"
    ];
    completionNames = [ "sy" ];
    meta = {
      description = "Minimal session manager for multi-repo, worktree-based work";
      mainProgram = "sy";
      platforms = final.lib.platforms.unix;
    };
  };

  specutil = select {
    pname = "specutil";
    package = final.specutil-cli;
    binary = "specutil";
    names = [ "specutil" ];
    completionNames = [ "specutil" ];
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
        final.delta
        final.diff-so-fancy
        final.difftastic
        final.ripgrep
        final.tree-sitter
      ];
    in
    final.runCommand "changes-${final.changes-cli.version}"
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
        makeWrapper "${final.changes-cli}/bin/changes" "$out/bin/changes" \
          --prefix PATH : "${runtimePath}" \
          --set-default CHANGES_DIFF_ENGINE internal \
          --set-default CHANGES_DIFF_LAYOUT unified
        mkdir -p "$out/share"
        cp -rs "${final.changes-cli}/share/." "$out/share/"
      '';

  traces =
    final.runCommand "traces-${final.traces-cli.version}"
      {
        nativeBuildInputs = [ final.makeBinaryWrapper ];
        meta = {
          description = "Agent trace view over the local OTLP collector's spans";
          mainProgram = "traces";
          platforms = final.lib.platforms.unix;
        };
      }
      ''
          mkdir -p "$out/bin"
          makeWrapper "${final.traces-cli}/bin/traces" "$out/bin/traces" \
            --prefix PATH : "${final.lib.makeBinPath [ final.changes ]}" \
            --set-default TRACES_DIFF_PROVIDER changes
        mkdir -p "$out/share"
        cp -rs "${final.traces-cli}/share/." "$out/share/"
      '';

  ask =
    let
      # wrappers.txt is the one list of the names the binary answers to.
      wrappers = final.lib.filter (name: name != "") (
        final.lib.splitString "\n" (builtins.readFile (inputs.ask + "/wrappers.txt"))
      );
    in
    final.runCommand "ask-${final.ask-cli.version}"
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
          cp -rs "${final.ask-cli}/bin/." "$out/bin/"
          mkdir -p "$out/share"
          cp -r "${final.ask-cli}/share/." "$out/share/"
          for name in ${final.lib.escapeShellArgs wrappers}; do
            ln -s "$out/bin/ask" "$out/bin/$name"
          done
        ''
        + final.lib.optionalString (final.stdenv.buildPlatform.canExecute final.stdenv.hostPlatform) ''
          for name in ${final.lib.escapeShellArgs wrappers}; do
            bash_completion="$TMPDIR/$name.bash"
            fish_completion="$TMPDIR/$name.fish"
            nu_completion="$TMPDIR/$name.nu"
            zsh_completion="$TMPDIR/_$name"
            "$out/bin/$name" completion bash > "$bash_completion"
            "$out/bin/$name" completion fish > "$fish_completion"
            "$out/bin/$name" completion nu > "$nu_completion"
            "$out/bin/$name" completion zsh > "$zsh_completion"
            installShellCompletion --cmd "$name" \
              --bash "$bash_completion" \
              --fish "$fish_completion" \
              --zsh "$zsh_completion"
            mkdir -p "$out/share/nushell/vendor/autoload"
            cp "$nu_completion" "$out/share/nushell/vendor/autoload/$name.nu"
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
