{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.atuin;
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  themeEnabled = themeLib.enabled config;
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
      themes.sysinit = lib.mkIf themeEnabled {
        theme.name = "sysinit";
        colors = {
          Base = "#${themeColors.base05}";
          Important = "#${themeColors.base0D}";
          Title = "#${themeColors.base0D}";
          Guidance = "#${themeColors.base0A}";
          Annotation = "#${themeColors.base0A}";
          AlertInfo = "#${themeColors.base0D}";
          AlertWarn = "#${themeColors.base0A}";
          AlertError = "#${themeColors.base08}";
          Muted = "#${themeColors.base04}";
        };
      };
      settings = {
        data_dir = "${config.xdg.dataHome}/atuin";
        auto_sync = false;
        update_check = false;
        style = "compact";
        inline_height = 8;
        auto_hide_height = 0;
        invert = true;
        show_preview = true;
        max_preview_height = 2;
        show_help = false;
        show_tabs = false;
        enter_accept = false;
        search_mode = "fuzzy";
        filter_mode = "global";
        search.shells = "all";
        keymap_mode = "vim-insert";
        keymap.vim-insert = {
          tab = "select-next";
          shift-tab = "select-previous";
        };
        theme.name = lib.mkIf themeEnabled "sysinit";
        daemon.autostart = false;
        output.enabled = false;
        pty_proxy.enabled = false;
        threads = {
          capture = true;
          capture_tools = true;
          filter_mode = "workspace";
        };
      };
    };

    fzf.historyWidget.command = "";

    nushell.extraConfig = lib.mkOrder 2100 ''
      source ${./nushell/atuin-prompt.nu}
    '';

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
  xdg.configFile."atuin/nushell.nu".source = ./nushell/atuin-prompt.nu;
  launchd.agents.atuin-daemon.config = {
    EnvironmentVariables.ATUIN_CONFIG_DIR = configDirectory;
    RunAtLoad = true;
  };
  systemd.user.services.atuin-daemon.Service.Environment = [
    "ATUIN_CONFIG_DIR=${configDirectory}"
  ];
}
