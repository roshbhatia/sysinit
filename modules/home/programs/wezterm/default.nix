{
  config,
  lib,
  pkgs,
  ...
}:

let
  paths = import ../../../lib/paths.nix { inherit lib; };
  themeConfig = config.sysinit.theme;
  c = config.lib.stylix.colors;

  # Pre-fetch wezterm plugins and wrap them as git repos
  # (wezterm.plugin.require needs a git repo even for file:// URLs)
  mkWeztermPlugin = { owner, repo, rev, hash }:
    pkgs.runCommand "wezterm-plugin-${repo}" {
      src = pkgs.fetchFromGitHub { inherit owner repo rev hash; };
      nativeBuildInputs = [ pkgs.git ];
    } ''
      cp -r $src $out
      chmod -R u+w $out
      cd $out
      git init
      git add .
      git commit -m "init" --allow-empty
    '';

  weztermPlugins = {
    tabline = mkWeztermPlugin {
      owner = "michaelbrusegard";
      repo = "tabline.wez";
      rev = "main";
      hash = "sha256-G5sFPIJ2SDLKjeiuauJfzu3JgvViwoe9RLhYAScaHbs=";
    };
    agent-deck = mkWeztermPlugin {
      owner = "Eric162";
      repo = "wezterm-agent-deck";
      rev = "main";
      hash = "sha256-nb5eCStxsgLBgZSNZjOBMYLNbv0haxXM+6609FywnwE=";
    };
    sessionizer = mkWeztermPlugin {
      owner = "mikkasendke";
      repo = "sessionizer.wezterm";
      rev = "main";
      hash = "sha256-A+4fGRfPKwOoSEH3MYHz3x5eMOCqPRpfYRCrIIHxZHM=";
    };
    resurrect = mkWeztermPlugin {
      owner = "MLFlexer";
      repo = "resurrect.wezterm";
      rev = "main";
      hash = "sha256-j7BIvJV7brkqWTtdWE/v9FnXRuHH0+934MTDCFNLEdY=";
    };
  };
in
{
  # Disable Stylix's wezterm target — we manage colors via config.json
  stylix.targets.wezterm.enable = false;

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    extraConfig = ''
      if wezterm.config_builder then
        config = wezterm.config_builder()
      end

      local home_dir = os.getenv("HOME") or (os.getenv("USER") and "/Users/" .. os.getenv("USER"))
      package.path = package.path
        .. ";"
        .. home_dir
        .. "/.config/wezterm/lua/?.lua"
        .. ";"
        .. home_dir
        .. "/.config/wezterm/lua/?/init.lua"

      require("sysinit.pkg.core").setup(config)
      require("sysinit.pkg.sessions").setup(config)
      require("sysinit.pkg.keybindings").setup(config)
      require("sysinit.pkg.ui").setup(config)

      return config
    '';
  };

  xdg.configFile = {
    "wezterm/lua".source = ./lua;
    "wezterm/config.json".text = builtins.toJSON {
      font = {
        monospace = themeConfig.font.monospace;
        symbols = themeConfig.font.symbols;
      };
      transparency = {
        opacity = themeConfig.transparency.opacity;
        blur = themeConfig.transparency.blur;
      };
      colors = {
        foreground = "#${c.base05}";
        background = "#${c.base00}";
        cursor_bg = "#${c.base05}";
        cursor_fg = "#${c.base00}";
        cursor_border = "#${c.base05}";
        selection_bg = "#${c.base02}";
        selection_fg = "#${c.base05}";
        ansi = [
          "#${c.base00}" "#${c.base08}" "#${c.base0B}" "#${c.base0A}"
          "#${c.base0D}" "#${c.base0E}" "#${c.base0C}" "#${c.base05}"
        ];
        brights = [
          "#${c.base03}" "#${c.base08}" "#${c.base0B}" "#${c.base0A}"
          "#${c.base0D}" "#${c.base0E}" "#${c.base0C}" "#${c.base07}"
        ];
        tab_bar = {
          background = "#${c.base01}";
          active_tab = { bg_color = "#${c.base02}"; fg_color = "#${c.base05}"; };
          inactive_tab = { bg_color = "#${c.base01}"; fg_color = "#${c.base04}"; };
          inactive_tab_hover = { bg_color = "#${c.base02}"; fg_color = "#${c.base05}"; };
          new_tab = { bg_color = "#${c.base01}"; fg_color = "#${c.base04}"; };
          new_tab_hover = { bg_color = "#${c.base02}"; fg_color = "#${c.base05}"; };
        };
      };
      # Pre-fetched plugin paths (avoids runtime git clones)
      plugins = {
        tabline = "${weztermPlugins.tabline}";
        agent-deck = "${weztermPlugins.agent-deck}";
        sessionizer = "${weztermPlugins.sessionizer}";
        resurrect = "${weztermPlugins.resurrect}";
      };
    };
    "wezterm/env.json".text = builtins.toJSON {
      PATH = paths.getPathString config.home.username config.home.homeDirectory;
    };
  };
}
