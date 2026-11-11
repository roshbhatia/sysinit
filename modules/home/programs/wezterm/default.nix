{
  config,
  inputs,
  lib,
  pkgs,
  values ? { },
  ...
}:

let
  themeLib = import ../../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  paths = import ../../../lib/paths.nix { inherit lib; };
  themeConfig = config.sysinit.theme;
  c = themeColors;
  luaSource = inputs.sysinit-wezterm.lib.luaSource pkgs;

  paneName = pkgs.writeShellApplication {
    name = "wezterm-pane-name";
    runtimeInputs = [ pkgs.lua5_4 ];
    text = ''
      if [[ -z ''${WEZTERM_PANE:-} ]]; then
        echo "wezterm-pane-name: must run inside a WezTerm pane" >&2
        exit 2
      fi

      lua - ${luaSource}/sysinit/pkg/ui/badges.lua "$WEZTERM_PANE" <<'LUA'
      local badges = dofile(arg[1])
      local pane_id = tonumber(arg[2])
      if not pane_id then
        io.stderr:write("wezterm-pane-name: invalid WEZTERM_PANE value\n")
        os.exit(2)
      end
      print(badges.name(pane_id))
      LUA
    '';
  };

  sshCfg = config.sysinit.git.ssh;
  sshAgentSocket =
    if lib.hasPrefix "~/" sshCfg.agentSocket then
      config.home.homeDirectory + lib.removePrefix "~" sshCfg.agentSocket
    else
      sshCfg.agentSocket;

in
{

  imports = [ inputs.sysinit-wezterm.homeManagerModules.default ];
  home.packages = [ paneName ];
  programs.sysinit-wezterm = {
    enable = true;
    persistence = {
      enable = true;
      service = values.wezterm.remoteMux or false;
      # The copied bundle keeps one path and one signing identity across updates.
      muxBinary = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/WezTerm.app/Contents/MacOS/wezterm-mux-server";
    };
    settings = {
      unsetEnvironmentVariables = [ "NO_COLOR" ];
      persistentRemoteHosts = [
        "arrakis"
      ];

      agents = import ../llm/harnesses/deck-patterns.nix;

      # Saved in plain text under the 0700 recovery directory; history copies omit it.
      persistence.scrollback_lines = 10000;

      agentResume = lib.mapAttrs (_n: h: [ h.command ] ++ h.launch.continueArgs) (
        lib.filterAttrs (_n: h: h ? launch.continueArgs) (import ../llm/harnesses/registry.nix)
      );

      agentIdentity = lib.mapAttrs (_n: h: {
        inherit (h) label glyph;
      }) (import ../llm/harnesses/registry.nix);

      bin = "${config.home.profileDirectory}/bin";
      shell = [
        "${config.home.profileDirectory}/bin/nu"
        "--config"
        "${config.xdg.configHome}/nushell/config.nu"
        "--env-config"
        "${config.xdg.configHome}/nushell/env.nu"
        "--plugin-config"
        "${config.xdg.configHome}/nushell/plugin.msgpackz"
      ];
      ssh = lib.optionalAttrs sshCfg.use1PasswordAgent { agent_socket = sshAgentSocket; };
      font = {
        inherit (themeConfig.font) monospace;
        inherit (themeConfig.font) symbols;
      };
      transparency = {
        inherit (themeConfig.transparency) opacity;
        inherit (themeConfig.transparency) blur;
      };
      colors = {
        foreground = "#${c.base05}";
        background = "#${c.base00}";
        cursor_bg = "#${c.base05}";
        cursor_fg = "#${c.base00}";
        cursor_border = "#${c.base05}";
        selection_bg = "#${c.base02}";
        selection_fg = "#${c.base05}";
        split = "#${c.base0D}";
        ansi = [
          "#${c.base00}"
          "#${c.base08}"
          "#${c.base0B}"
          "#${c.base0A}"
          "#${c.base0D}"
          "#${c.base0E}"
          "#${c.base0C}"
          "#${c.base05}"
        ];
        brights = [
          "#${c.base03}"
          "#${c.base08}"
          "#${c.base0B}"
          "#${c.base0A}"
          "#${c.base0D}"
          "#${c.base0E}"
          "#${c.base0C}"
          "#${c.base07}"
        ];
        tab_bar = {
          background = "#${c.base01}";
          active_tab = {
            bg_color = "#${c.base02}";
            fg_color = "#${c.base05}";
          };
          inactive_tab = {
            bg_color = "#${c.base01}";
            fg_color = "#${c.base04}";
          };
          inactive_tab_hover = {
            bg_color = "#${c.base02}";
            fg_color = "#${c.base05}";
          };
          new_tab = {
            bg_color = "#${c.base01}";
            fg_color = "#${c.base04}";
          };
          new_tab_hover = {
            bg_color = "#${c.base02}";
            fg_color = "#${c.base05}";
          };
        };
      };
      spawn.commands = {
        ssh = lib.getExe' pkgs.openssh "ssh";
        mosh = lib.getExe' pkgs.mosh "mosh";
      };
      picker.providers = [
        {
          name = "tether";
          key = "@";
          manifest = "${pkgs.tether-picker}/share/wezterm/providers/tether.json";
        }
        {
          name = "zmx";
          key = "#";
          manifest = "${pkgs.zmx-picker}/share/wezterm/providers/zmx.json";
        }
        {
          name = "seshy";
          key = "$";
          manifest = "${pkgs.seshy-picker}/share/wezterm/providers/seshy.json";
        }
        {
          name = "zoxide";
          key = "%";
          manifest = "${pkgs.zoxide-picker}/share/wezterm/providers/zoxide.json";
        }
      ];
      cwd_aliases.sy = config.sysinit.paths.resolved.seshySessions;
      passthrough_procs = [
        "zmx"
        "caffeinate"
      ];
    };
    environment = {

      PATH = paths.getPathString config.home.username config.home.homeDirectory;
      # A long-lived mux outlives the store path of any one terminfo build.
      TERMINFO_DIRS = "${config.home.profileDirectory}/share/terminfo";
    };
  };

}
