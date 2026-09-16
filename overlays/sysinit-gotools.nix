{ inputs }:
final: _prev:
let
  # Not `gotools`. That name is taken by the nixpkgs package holding goimports
  # and godoc, which modules/home/packages.nix installs.
  sysinit-gotools = final.buildGoModule {
    pname = "sysinit-gotools";
    version = "0.1.0";

    src = ../pkgs;

    vendorHash = "sha256-LLhR96vCSXd90RwwoFHEtMCik4p1iVVU2YGcIkIuR9k=";

    nativeCheckInputs = [ final.git ];
    AGENTGATEWAY_BINARY = "${final.agentgateway}/bin/agentgateway";
    MCP_REMOTE_BINARY = "${final.mcp-remote-go}/bin/mcp-remote";

    meta.platforms = final.lib.platforms.unix;
  };

  select =
    {
      pname,
      package,
      binary,
      names,
      completionNames ? [ ],
      completionPaths ? [ ],
      meta,
    }:
    final.runCommand "${pname}-${final.lib.getVersion package}"
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
          ${final.lib.concatMapStringsSep "\n" (path: ''
            test -s "$out/share/${path}"
          '') completionPaths}
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
    completionPaths = [
      "bash-completion/completions/sy.bash"
      "fish/vendor_completions.d/sy.fish"
      "nushell/vendor/autoload/sy.nu"
      "zsh/site-functions/_sy"
    ];
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
    completionPaths = [
      "bash-completion/completions/specutil.bash"
      "fish/vendor_completions.d/specutil.fish"
      "nushell/vendor/autoload/specutil.nu"
      "zsh/site-functions/_specutil"
    ];
    meta = {
      description = "Project spec-framework change artifacts into other artifacts and visualizations";
      mainProgram = "specutil";
      platforms = final.lib.platforms.unix;
    };
  };

  changes = final.changes-cli;

  traces = final.traces-cli;

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
          chmod -R u+w "$out/share"
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
      external = {
        agent-state = "${final.agent-state}/bin/agent-state";
        agent-watch = "${final.worker}/bin/agent-watch";
        firefox-tabs = "${final.firefox-tabs}/bin/firefox-tabs";
        worker = "${final.worker}/bin/worker";
        ws = "${final.workspace-cli}/bin/ws";
      };

      runtimePath = final.lib.makeBinPath [
        final.git
        final.curl
      ];
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
          --set SYSINIT_AGENT_STATE "${external.agent-state}" \
          --set SYSINIT_AGENT_WATCH "${external.agent-watch}" \
          --set SYSINIT_FIREFOX_TABS "${external.firefox-tabs}" \
          --set SYSINIT_WORKER "${external.worker}" \
          --set SYSINIT_WORKSPACE "${external.ws}" \
          --set SYSINIT_WEZSPAWN "${final.wezspawn}/bin/wezspawn" \
          --prefix PATH : "${runtimePath}"
        ln -s "${final.wezspawn}/bin/wezspawn" "$out/bin/wezspawn"
        makeWrapper "${sysinit-gotools}/bin/utils" "$out/bin/agent-statusline" \
          --argv0 agent-statusline --prefix PATH : "${runtimePath}"
        ${final.lib.concatStringsSep "\n" (
          final.lib.mapAttrsToList (name: binary: ''
            ln -s "${binary}" "$out/bin/${name}"
          '') external
        )}
      '';
}
