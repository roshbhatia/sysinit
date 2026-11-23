final: _prev:
let
  viewer = final.writeShellApplication {
    name = "pueue-task-view";
    runtimeInputs = [
      final.pueue
      final.less
    ];
    text = ''exec ${final.lib.getExe final.nushell} --no-config-file ${./view.nu} "$@"'';
  };
  queue = final.writeShellApplication {
    name = "task-queue";
    runtimeInputs = [
      final.pueue
      final.taskwarrior-cli
      final.seshy
      final.atuin
      viewer
    ];
    text = ''
      ${final.terminal-provider-selection}
      exec ${final.sysinit-gotools}/bin/tq "$@"
    '';
  };
  queuePackage = final.symlinkJoin {
    name = "task-queue";
    paths = [ queue ];
    postBuild = ''ln -s task-queue "$out/bin/tq"'';
    meta = queue.meta // {
      mainProgram = "task-queue";
    };
  };
  executable = final.writeShellApplication {
    name = "tq-picker";
    runtimeInputs = [
      final.pueue
      final.coreutils
    ];
    text = ''
      exec ${final.lib.getExe final.nushell} --no-config-file --stdin ${./provider.nu} \
        ${final.lib.getExe queue} ${final.lib.getExe viewer}
    '';
  };
  manifest = final.writeText "tq.json" (
    builtins.toJSON {
      version = "provider/v1";
      kind = "picker";
      name = "tq";
      description = "Pueue tasks and Taskwarrior execution terminals";
      command = [ (final.lib.getExe executable) ];
      actions =
        final.lib.genAttrs [ "provider.validate" "picker.describe" "picker.list" "picker.open" ]
          (action: {
            description = action;
          });
      defaults.timeout = "5s";
    }
  );
  weztermProvider = final.writeShellApplication {
    name = "tq-wezterm-provider";
    runtimeInputs = [ final.wezterm ];
    text = "exec ${final.sysinit-gotools}/bin/tq wezterm-provider";
  };
  terminalManifest = "${terminalProvider}/share/sysinit/terminal-providers/wezterm.json";
  terminalProvider = final.writeTextDir "share/sysinit/terminal-providers/wezterm.json" (
    builtins.toJSON {
      version = "provider/v1";
      name = "wezterm";
      description = "Run and review tasks in WezTerm panes";
      command = [ (final.lib.getExe weztermProvider) ];
      actions =
        final.lib.genAttrs
          [ "terminal.spawn" "terminal.status" "terminal.focus" "terminal.close" "terminal.review" ]
          (action: {
            description = action;
          });
    }
  );
  rexProvider = final.writeShellApplication {
    name = "tq-rex-provider";
    runtimeInputs = [ final.rex ];
    text = "exec ${final.lib.getExe final.nushell} --no-config-file --stdin ${./rex.nu}";
  };
  rexManifest = "${rexTerminalProvider}/share/sysinit/terminal-providers/rex.json";
  rexTerminalProvider = final.writeTextDir "share/sysinit/terminal-providers/rex.json" (
    builtins.toJSON {
      version = "provider/v1";
      name = "rex";
      description = "Run tasks in Rex session tabs and open review beside the caller";
      command = [ (final.lib.getExe rexProvider) ];
      actions =
        final.lib.genAttrs
          [ "terminal.spawn" "terminal.status" "terminal.focus" "terminal.close" "terminal.review" ]
          (action: {
            description = action;
          });
    }
  );
in
{
  terminal-provider-selection = ''
    provider="${terminalManifest}"
    ${final.lib.optionalString final.stdenv.hostPlatform.isDarwin ''
      if [ -n "''${REX_BLOCK:-}" ]; then
        provider="${rexManifest}"
      fi
    ''}
    export SYSINIT_TERMINAL_PROVIDER="''${SYSINIT_TERMINAL_PROVIDER:-$provider}"
  '';
  tq-terminal-wezterm = terminalProvider;
  tq-terminal-rex = rexTerminalProvider;
  task-queue = queuePackage;
  tq = queuePackage;
  pueue-task-view = viewer;
  tq-picker = final.symlinkJoin {
    name = "tq-picker";
    paths = [
      executable
      viewer
    ];
    postBuild = ''
      mkdir -p "$out/share/wezterm/providers"
      cp ${manifest} "$out/share/wezterm/providers/tq.json"
    '';
    meta.mainProgram = "tq-picker";
  };
}
