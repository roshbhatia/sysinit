{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.atuin;
  configDirectory = "${config.xdg.configHome}/atuin";
  zshInit = pkgs.runCommand "atuin-zsh-init" { } ''
    export HOME="$TMPDIR"
    ${lib.getExe cfg.package} init zsh ${lib.escapeShellArgs cfg.flags} > "$out"
  '';
in
{
  programs = {
    atuin = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = false;
      flags = [
        "--disable-up-arrow"
        "--disable-ai"
      ];
      daemon.enable = true;
      settings = {
        data_dir = "${config.xdg.dataHome}/atuin";
        auto_sync = false;
        update_check = false;
        style = "compact";
        inline_height = 13;
        show_preview = false;
        show_help = false;
        show_tabs = false;
        enter_accept = false;
        search_mode = "fuzzy";
        filter_mode = "global";
        search.shells = "all";
        keymap_mode = "auto";
        daemon.autostart = false;
        output.enabled = false;
        pty_proxy.enabled = false;
        threads = {
          capture = true;
          capture_tools = true;
          filter_mode = "workspace";
          inline_height = 20;
        };
      };
    };

    fzf.historyWidget.command = "";

    zsh.initContent = lib.mkOrder 610 ''
      __setup_atuin() {
        source ${zshInit}
        bindkey -M vicmd '^R' atuin-search-vicmd
      }
      # zsh-vi-mode installs fzf bindings lazily, so Atuin must follow that callback.
      zvm_after_init_commands+=(__setup_atuin)
    '';
  };

  home.sessionVariables.ATUIN_CONFIG_DIR = configDirectory;
  launchd.agents.atuin-daemon.config = {
    EnvironmentVariables.ATUIN_CONFIG_DIR = configDirectory;
    RunAtLoad = true;
  };
  systemd.user.services.atuin-daemon.Service.Environment = [
    "ATUIN_CONFIG_DIR=${configDirectory}"
  ];
}
