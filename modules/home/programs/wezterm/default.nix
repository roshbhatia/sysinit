{
  config,
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

  weztermPlugins = {
    tabline = pkgs.fetchFromGitHub {
      owner = "michaelbrusegard";
      repo = "tabline.wez";
      rev = "5e148f08f134e317bbfe75b26f8a23b0102cb621";
      hash = "sha256-G5sFPIJ2SDLKjeiuauJfzu3JgvViwoe9RLhYAScaHbs=";
    };
    agent-deck = pkgs.applyPatches {
      src = pkgs.fetchFromGitHub {
        owner = "Eric162";
        repo = "wezterm-agent-deck";
        rev = "bd5a57e7806032998e6cae56ade67b72a08b7868";
        hash = "sha256-nb5eCStxsgLBgZSNZjOBMYLNbv0haxXM+6609FywnwE=";
      };
      patches = [ ./patches/agent-deck-idle-detection.patch ];
    };
    warp = pkgs.fetchFromGitHub {
      owner = "sravioli";
      repo = "warp.wz";
      rev = "ccc6816fff3174bd826ab1a7154fb8469a8e4cdd";
      hash = "sha256-GRYSLrZXmGSJqXqfAvolBwsu+o1AYEBSUYBVGlLkLqg=";
    };
    ribbon = pkgs.fetchFromGitHub {
      owner = "sravioli";
      repo = "ribbon.wz";
      rev = "e2735090f8e5e2815429c86f1816260523b86494";
      hash = "sha256-nfSHZnAkd/CNk8GFm6QoBZ36zPhcR5le70geNRpk7J0=";
    };
    sigil = pkgs.fetchFromGitHub {
      owner = "sravioli";
      repo = "sigil.wz";
      rev = "1e58c730dcbf8bfdcd32cdada3484a1d673e0464";
      hash = "sha256-tEspBNdQqGif5DQV8JAzVQRdW0Hl6ykdSMmx+BqNj90=";
    };
    log = pkgs.fetchFromGitHub {
      owner = "sravioli";
      repo = "log.wz";
      rev = "43dc5e48b8962e4636c22be3d67ef3a8b8eca795";
      hash = "sha256-+EvwhQIQTe9QqC7qEG1OnEkCfPux+E5UH6xBEocTk4M=";
    };
    memo = pkgs.fetchFromGitHub {
      owner = "sravioli";
      repo = "memo.wz";
      rev = "f5cdebca623809f7e61563a48b1679c81d32b148";
      hash = "sha256-SnI3n2oi0txKVK+v55aA4TVx0rcmli+okWUdzuy6SGU=";
    };
    lantern = pkgs.applyPatches {
      src = pkgs.fetchFromGitHub {
        owner = "sravioli";
        repo = "lantern.wz";
        rev = "cfe4acb1b04b81a16410a66283477d68c98a3375";
        hash = "sha256-ncxG9quSnpueWPZhEMC4DS63/9m3ayLX6s7g9VoMMIg=";
      };
      patches = [ ./patches/lantern-deps-loader.patch ];
    };
    workspace-manager = pkgs.fetchFromGitHub {
      owner = "ryanmsnyder";
      repo = "workspace-manager.wezterm";
      rev = "2aa02b17b3555035e329a479e6f981027d611b15";
      hash = "sha256-p+J/ilHkrauaviMNH6zEeFpAXLKAistSrJpRNCftqoI=";
    };
  };
in
{

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    extraConfig = ''
      local home_dir = os.getenv("HOME") or (os.getenv("USER") and "/Users/" .. os.getenv("USER"))
      package.path = package.path
        .. ";"
        .. home_dir
        .. "/.config/wezterm/lua/?.lua"
        .. ";"
        .. home_dir
        .. "/.config/wezterm/lua/?/init.lua"

      return require("sysinit.pkg.bootstrap").build()
    '';
  };

  xdg.configFile = {
    "wezterm/lua".source = ./lua;
    "wezterm/config.json".text = builtins.toJSON {
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
      plugins = {
        tabline = "${weztermPlugins.tabline}";
        agent-deck = "${weztermPlugins.agent-deck}";
        warp = "${weztermPlugins.warp}";
        ribbon = "${weztermPlugins.ribbon}";
        sigil = "${weztermPlugins.sigil}";
        log = "${weztermPlugins.log}";
        memo = "${weztermPlugins.memo}";
        lantern = "${weztermPlugins.lantern}";
        workspace-manager = "${weztermPlugins.workspace-manager}";
      };
    };
    "wezterm/env.json".text = builtins.toJSON {
      PATH = paths.getPathString config.home.username config.home.homeDirectory;
      TERMINFO_DIRS = "${pkgs.wezterm.terminfo}/share/terminfo";
    };
  };

}
