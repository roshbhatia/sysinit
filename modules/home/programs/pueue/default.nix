{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sysinit.queue;
  queue = pkgs.writeShellApplication {
    name = "task-queue";
    runtimeInputs = [
      pkgs.pueue
      pkgs.taskwarrior-cli
      pkgs.seshy
      pkgs.zmx
    ];
    text = ''exec ${pkgs.sysinit-gotools}/bin/task-queue "$@"'';
  };
  completions = pkgs.runCommand "task-queue-completions" { } ''
    mkdir -p "$out/share/zsh/site-functions"
    cp ${./_task-queue} "$out/share/zsh/site-functions/_task-queue"
  '';
in
{
  options.sysinit.queue.enable = lib.mkEnableOption "Local Pueue queues and explicit task dispatch";
  config = lib.mkIf cfg.enable {
    services.pueue = {
      enable = true;
      settings = {
        shared = {
          pueue_directory = "${config.xdg.stateHome}/pueue";
          use_unix_socket = true;
        };
        daemon = {
          shell_command = [
            "${pkgs.bash}/bin/bash"
            "-c"
            "{{ pueue_command_string }}"
          ];
          pause_group_on_failure = true;
        };
      };
    };
    launchd.agents.pueued.config.Umask = 63;
    systemd.user.services.pueued.Service.UMask = "0077";
    home.packages = [
      queue
      completions
    ];
    xdg.configFile = {
      "carapace/specs/pueue.yaml".text = ''
        name: pueue
        description: Queue and inspect background commands
        parsing: disabled
        completion:
          positionalany: ["$carapace.bridge.Zsh([pueue])"]
      '';
      "carapace/bridge/zsh/.zshrc".text = ''
        fpath=(${pkgs.pueue}/share/zsh/site-functions ${completions}/share/zsh/site-functions $fpath)
        autoload -Uz _pueue _task-queue
        compdef _pueue pueue
        compdef _task-queue task-queue
      '';
      "carapace/specs/task-queue.yaml".text = ''
        name: task-queue
        description: Dispatch explicit execution attempts
        parsing: disabled
        completion:
          positionalany: ["$carapace.bridge.Zsh([task-queue])"]
      '';
    };
  };
}
