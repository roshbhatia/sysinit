{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sysinit.queue;
  queue = pkgs.writeShellApplication {
    name = "tq";
    runtimeInputs = [
      pkgs.pueue
      pkgs.taskwarrior-cli
      pkgs.seshy
      pkgs.wezterm
      pkgs.atuin
      pkgs.pueue-task-view
    ];
    text = ''exec ${pkgs.sysinit-gotools}/bin/tq "$@"'';
  };
  completions = pkgs.runCommand "tq-completions" { } ''
    mkdir -p "$out/share/zsh/site-functions"
    cp ${./_tq} "$out/share/zsh/site-functions/_tq"
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
        autoload -Uz _pueue _tq
        compdef _pueue pueue
        compdef _tq tq
      '';
      "carapace/specs/tq.yaml".text = ''
        name: tq
        description: Dispatch explicit execution attempts
        parsing: disabled
        completion:
          positionalany: ["$carapace.bridge.Zsh([tq])"]
      '';
    };
  };
}
