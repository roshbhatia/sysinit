{ pkgs }:
pkgs.runCommand "task-command-contracts"
  {
    nativeBuildInputs = [
      pkgs.go-task
      pkgs.taskwarrior-cli
      pkgs.zsh
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    export TASKRC="$TMPDIR/taskrc"
    export TASKDATA="$TMPDIR/tasks"
    mkdir -p "$HOME"
    touch "$TASKRC"
    test "$(task --version)" = "${pkgs.go-task.version}"
    taskwarrior rc.confirmation:no add 'Command separation' > /dev/null
    taskwarrior rc.json.array:on export | grep 'Command separation'
    test ! -e ${pkgs.taskwarrior-cli}/bin/task
    test ! -e ${pkgs.taskwarrior-cli}/share/zsh/site-functions/_task
    grep '#compdef taskwarrior' ${pkgs.taskwarrior-cli}/share/zsh/site-functions/_taskwarrior
    zsh -n ${pkgs.taskwarrior-cli}/share/zsh/site-functions/_taskwarrior
    cat > Taskfile.yml <<'YAML'
    version: '3'
    tasks:
      default:
        cmds:
          - echo taskfile-command-ok
    YAML
    task | grep taskfile-command-ok
    touch "$out"
  ''
