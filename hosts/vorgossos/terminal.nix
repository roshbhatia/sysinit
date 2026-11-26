{
  lib,
  pkgs,
  terminalColors,
  wezterm,
  ...
}:

let
  inherit (lib) getExe;
  user = "rshnbhatia";
  kubeconfig = "/home/${user}/.kube/config";
  palette = import ../../modules/shared/terminal-palette.nix terminalColors;
  ansiNames = [
    "black"
    "red"
    "green"
    "yellow"
    "blue"
    "magenta"
    "cyan"
    "white"
  ];
  brightNames = [
    "brightBlack"
    "brightRed"
    "brightGreen"
    "brightYellow"
    "brightBlue"
    "brightMagenta"
    "brightCyan"
    "brightWhite"
  ];
  browserTheme = {
    inherit (palette) foreground background;
    cursor = palette.cursor_bg;
    cursorAccent = palette.cursor_fg;
    selectionBackground = palette.selection_bg;
    selectionForeground = palette.selection_fg;
  }
  // builtins.listToAttrs (lib.zipListsWith lib.nameValuePair ansiNames palette.ansi)
  // builtins.listToAttrs (lib.zipListsWith lib.nameValuePair brightNames palette.brights);
  muxConfig = pkgs.writeText "vorgossos-wezterm.lua" ''
    local wezterm = require("wezterm")
    return {
      unix_domains = {{ name = "unix", socket_path = "/run/wezterm-mux/mux.sock" }},
      mux_server_spawn_initial_tab = false,
      default_prog = { "${getExe pkgs.bashInteractive}", "-l" },
      default_cwd = "/home/${user}",
      scrollback_lines = 10000,
      colors = wezterm.json_parse(${builtins.toJSON (builtins.toJSON palette)}),
      remote_client = { interface = "cli" },
    }
  '';
  remote = pkgs.writeScriptBin "wezterm-remote" ''
    #!${getExe pkgs.nushell} --no-config-file
    def --wrapped main [...arguments: string] {
        exec ${wezterm}/bin/wezterm --config-file ${muxConfig} remote ...$arguments
    }
  '';
in
{
  environment.systemPackages = [
    remote
    pkgs.k9s
  ];

  systemd.services.wezterm-mux = {
    description = "Persistent WezTerm mux";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = user;
      RuntimeDirectory = "wezterm-mux";
      RuntimeDirectoryMode = "0700";
      ExecStart = "${wezterm}/bin/wezterm-mux-server --config-file ${muxConfig}";
      Restart = "on-failure";
    };
  };

  networking.nftables.enable = true;
  networking.firewall.extraInputRules = ''
    iifname "lxc*" ip saddr 10.244.0.0/24 ip daddr 192.168.50.37 tcp dport 7682 accept
  '';
  systemd.services.ttyd-k9s = {
    description = "Browser terminal for the k9s workspace";
    after = [
      "wezterm-mux.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "wezterm-mux.service" ];
    wantedBy = [ "multi-user.target" ];
    environment.KUBECONFIG = kubeconfig;
    unitConfig.ConditionPathExists = kubeconfig;
    serviceConfig = {
      User = user;
      ExecStart = "${getExe pkgs.ttyd} --interface 192.168.50.37 --port 7682 --writable --client-option ${lib.escapeShellArg "theme=${builtins.toJSON browserTheme}"} ${getExe remote} attach k9s -- ${getExe pkgs.k9s}";
      Restart = "on-failure";
    };
  };
}
