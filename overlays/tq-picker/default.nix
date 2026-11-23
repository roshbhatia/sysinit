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
    name = "tq";
    runtimeInputs = [
      final.pueue
      final.taskwarrior-cli
      final.seshy
      final.atuin
      viewer
    ];
    text = ''
      export SYSINIT_TERMINAL_PROVIDER="''${SYSINIT_TERMINAL_PROVIDER:-${terminalManifest}}"
      exec ${final.sysinit-gotools}/bin/tq "$@"
    '';
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
in
{
  tq-terminal-wezterm = terminalProvider;
  tq = queue;
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
