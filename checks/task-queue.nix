{ pkgs }:
let
  module = import ../modules/home/programs/pueue {
    inherit pkgs;
    inherit (pkgs) lib;
    config = {
      sysinit.queue.enable = true;
      xdg.stateHome = "/tmp/queue-test-state";
    };
  };
  files = module.config.content.xdg.configFile;
  bridge = pkgs.writeText "queue-bridge.zsh" files."carapace/bridge/zsh/.zshrc".text;
  spec = pkgs.writeText "pueue.yaml" files."carapace/specs/pueue.yaml".text;
  queueSpec = pkgs.writeText "task-queue.yaml" files."carapace/specs/task-queue.yaml".text;
in
pkgs.runCommand "task-queue-test"
  {
    nativeBuildInputs = [
      pkgs.pueue
      pkgs.taskwarrior-cli
      pkgs.seshy
      pkgs.zmx
      pkgs.bash
      pkgs.zsh
      pkgs.carapace
      pkgs.nushell
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/carapace/bridge/zsh" "$XDG_CONFIG_HOME/carapace/specs"
    cp ${bridge} "$XDG_CONFIG_HOME/carapace/bridge/zsh/.zshrc"
    cp ${spec} "$XDG_CONFIG_HOME/carapace/specs/pueue.yaml"
    cp ${queueSpec} "$XDG_CONFIG_HOME/carapace/specs/task-queue.yaml"
    nu --no-config-file -c '
      let values = (carapace pueue nushell pueue add --sta | from json | get value | str trim)
      if "--stashed" not-in $values { error make {msg: "Pueue Zsh bridge failed"} }
      let values = (carapace task-queue nushell task-queue submit --ter | from json | get value | str trim)
      if "--terminal" not-in $values { error make {msg: "Task queue Zsh bridge failed"} }
    '
    test -x ${pkgs.sysinit-gotools}/bin/task-queue
    touch "$out"
  ''
