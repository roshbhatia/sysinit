{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  themeLib = import ../../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  paths = import ../../../lib/paths.nix { inherit lib; };
  themeConfig = config.sysinit.theme;
  c = themeColors;

  sshCfg = config.sysinit.git.ssh;
  sshAgentSocket =
    if lib.hasPrefix "~/" sshCfg.agentSocket then
      config.home.homeDirectory + lib.removePrefix "~" sshCfg.agentSocket
    else
      sshCfg.agentSocket;

in
{

  imports = [ inputs.sysinit-wezterm.homeManagerModules.default ];
  programs.sysinit-wezterm = {
    enable = true;
    settings = {
      # Generated from the harness registry, so the deck cannot fall behind it.
      # ui.lua used to hold this table inline, and hermes was never added.
      agents = import ../llm/harnesses/deck-patterns.nix;
      # Identity for the same fourteen, so the status bar stops carrying its own
      # partial copy. sigil.setup used to name claude and codex and nothing else.
      agentIdentity = lib.mapAttrs (_n: h: {
        inherit (h) label glyph;
      }) (import ../llm/harnesses/registry.nix);
      # Absolute, because utils.lua hardcoded the nix-darwin profile path, which
      # does not exist under standalone home-manager on Linux.
      bin = "${config.home.profileDirectory}/bin";
      shell = [
        (lib.getExe pkgs.nushell)
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
      picker.providers = [
        {
          name = "tether";
          key = "!";
          manifest = "${pkgs.tether-picker}/share/wezterm/providers/tether.json";
        }
        {
          name = "seshy";
          key = "@";
          manifest = "${pkgs.seshy-picker}/share/wezterm/providers/seshy.json";
        }
        {
          name = "zoxide";
          key = "#";
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
      TERMINFO_DIRS = "${pkgs.wezterm.terminfo}/share/terminfo";
    };
  };

}
