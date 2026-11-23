final: _prev:
let
  viewer = final.writeShellApplication {
    name = "pueue-task-view";
    runtimeInputs = [
      final.pueue
      final.less
    ];
    text = ''
      if [[ $# != 2 || ! "$1" =~ ^[0-9]+$ ]]; then
        echo "pueue-task-view: expected task ID and log mode" >&2
        exit 2
      fi
      case "$2" in
        stdin) less -R -P "Pueue #$1 | j/k scroll | g/G top/end | q quit" +G ;;
        follow) pueue follow --lines 1000 "$1" | less -R -P "Pueue #$1 | Ctrl-C pause | j/k scroll | F follow | q quit" +F ;;
        log) pueue log --lines 1000 "$1" | less -R -P "Pueue #$1 | j/k scroll | g/G top/end | q quit" +G ;;
        *) echo "pueue-task-view: invalid log mode" >&2; exit 2 ;;
      esac
    '';
  };
  queue = final.writeShellApplication {
    name = "tq";
    runtimeInputs = [
      final.pueue
      final.taskwarrior-cli
      final.seshy
      final.wezterm
      final.atuin
      viewer
    ];
    text = ''exec ${final.sysinit-gotools}/bin/tq "$@"'';
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
in
{
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
