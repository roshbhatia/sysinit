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

  # Pre-fetch wezterm plugins via git clone (preserves .git for wezterm.plugin.require)
  weztermPlugins = {
    tabline = pkgs.fetchgit {
      url = "https://github.com/michaelbrusegard/tabline.wez";
      rev = "5e148f08f134e317bbfe75b26f8a23b0102cb621";
      hash = "sha256-XxQJP+O6XL2z93QhDDaytDJXA3KY8QXHrxZ9y1nul2Q=";
      leaveDotGit = true;
    };
    agent-deck = pkgs.fetchgit {
      url = "https://github.com/Eric162/wezterm-agent-deck";
      rev = "bd5a57e7806032998e6cae56ade67b72a08b7868";
      hash = "sha256-pWQkJ9b4efroajimysOQmK/DPC6nH2sZM9poEr9ROgQ=";
      leaveDotGit = true;
    };
    sessionizer = pkgs.fetchgit {
      url = "https://github.com/mikkasendke/sessionizer.wezterm";
      rev = "694f355150325bdb13ef78588ae5514f8aa22124";
      hash = "sha256-6eUCvn+dHoXP1SvLzJQmMywiRdBEFpQI2nLCode70Zk=";
      leaveDotGit = true;
    };
    resurrect = pkgs.fetchgit {
      url = "https://github.com/MLFlexer/resurrect.wezterm";
      rev = "47ce553e07bb2c183d10487c56c406454aa50f36";
      hash = "sha256-+Ps9dlT+PRKjXO1gGQsrwgYLlU7jl16lcCWfc12nDPI=";
      leaveDotGit = true;
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
      # Plugin paths — copied to ~/.local/share/wezterm/plugins/ by activation script
      plugins = {
        tabline = "${config.home.homeDirectory}/.local/share/wezterm/plugins/tabline.wez";
        agent-deck = "${config.home.homeDirectory}/.local/share/wezterm/plugins/wezterm-agent-deck";
        sessionizer = "${config.home.homeDirectory}/.local/share/wezterm/plugins/sessionizer.wezterm";
        resurrect = "${config.home.homeDirectory}/.local/share/wezterm/plugins/resurrect.wezterm";
      };
    };
    "wezterm/env.json".text = builtins.toJSON {
      PATH = paths.getPathString config.home.username config.home.homeDirectory;
    };
  };

  # Copy plugins from Nix store to user-writable directory
  # (wezterm.plugin.require needs write access to the git repo)
  home.activation.weztermPlugins = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    PLUGIN_DIR="${config.home.homeDirectory}/.local/share/wezterm/plugins"
    mkdir -p "$PLUGIN_DIR"

    copy_plugin() {
      local src="$1"
      local dest="$2"
      if [ -d "$dest" ]; then
        rm -rf "$dest"
      fi
      cp -rL "$src" "$dest"
      chmod -R u+w "$dest"
    }

    copy_plugin "${weztermPlugins.tabline}" "$PLUGIN_DIR/tabline.wez"
    copy_plugin "${weztermPlugins.agent-deck}" "$PLUGIN_DIR/wezterm-agent-deck"
    copy_plugin "${weztermPlugins.sessionizer}" "$PLUGIN_DIR/sessionizer.wezterm"
    copy_plugin "${weztermPlugins.resurrect}" "$PLUGIN_DIR/resurrect.wezterm"
  '';
}
