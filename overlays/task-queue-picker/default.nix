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
        follow) pueue follow --lines 1000 "$1" | less -R -P "Pueue #$1 | Ctrl-C pause | j/k scroll | F follow | q quit" +F ;;
        log) pueue log --lines 1000 "$1" | less -R -P "Pueue #$1 | j/k scroll | g/G top/end | q quit" +G ;;
        *) echo "pueue-task-view: invalid log mode" >&2; exit 2 ;;
      esac
    '';
  };
  executable = final.writeShellApplication {
    name = "task-queue-picker";
    runtimeInputs = [
      final.pueue
      final.zmx
      final.coreutils
      viewer
    ];
    text = ''
      exec ${final.python3}/bin/python3 ${./provider.py} \
        ${final.lib.getExe final.zmx} ${final.lib.getExe viewer} ${final.lib.getExe' final.coreutils "env"}
    '';
  };
  manifest = final.writeText "task-queue.json" (
    builtins.toJSON {
      version = "provider/v1";
      kind = "picker";
      name = "task-queue";
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
  pueue-task-view = viewer;
  task-queue-picker = final.symlinkJoin {
    name = "task-queue-picker";
    paths = [
      executable
      viewer
    ];
    postBuild = ''
      mkdir -p "$out/share/wezterm/providers"
      cp ${manifest} "$out/share/wezterm/providers/task-queue.json"
    '';
    meta.mainProgram = "task-queue-picker";
  };
}
