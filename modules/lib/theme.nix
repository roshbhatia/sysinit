{ lib, config, ... }:

with lib;

let
  themes = import ./theme { inherit lib; };
  cfg = config.sysinit.theme;
in
{
  options.sysinit.theme = {
    colorscheme = mkOption {
      type = types.enum [
        "catppuccin"
        "rose-pine"
        "gruvbox"
        "solarized"
        "nord"
        "kanagawa"
      ];
      default = "catppuccin";
      description = "The color scheme to use system-wide";
    };

    variant = mkOption {
      type = types.enum [
        "macchiato" # catppuccin
        "moon" # rose-pine
        "wave" # kanagawa
        "dragon" # kanagawa
        "dark" # gruvbox nord solarized
      ];
      default = "macchiato";
      description = "The variant of the chosen color scheme";
    };

    transparency = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable transparency effects";
      };

      opacity = mkOption {
        type = types.float;
        default = 0.85;
        description = "Opacity level for transparency effects";
      };
    };

    palette = mkOption {
      type = types.attrs;
      readOnly = true;
      default = themes.getThemePalette cfg.colorscheme cfg.variant;
      description = "Color palette for the current theme";
    };

    appThemes = mkOption {
      type = types.attrs;
      readOnly = true;
      default = {
        neovim = themes.getAppTheme "neovim" cfg.colorscheme cfg.variant;
        wezterm = themes.getAppTheme "wezterm" cfg.colorscheme cfg.variant;
        bat = themes.getAppTheme "bat" cfg.colorscheme cfg.variant;
        git = themes.getAppTheme "delta" cfg.colorscheme cfg.variant;
        atuin = themes.getAppTheme "atuin" cfg.colorscheme cfg.variant;
        vivid = themes.getAppTheme "vivid" cfg.colorscheme cfg.variant;
      };
      description = "App-specific theme names";
    };

    ansiMappings = mkOption {
      type = types.attrs;
      readOnly = true;
      default =
        themes.ansiMappings.${cfg.colorscheme}.${cfg.variant} or themes.ansiMappings.catppuccin.macchiato;
      description = "ANSI color mappings for terminal applications";
    };
  };

  config = {
    # Generate JSON config file for applications that need it (like Neovim Lua)
    home.file.".config/sysinit/theme_config.json" = {
      text = builtins.toJSON {
        colorscheme = cfg.colorscheme;
        variant = cfg.variant;
        transparency = cfg.transparency;
        palette = themes.getThemePalette cfg.colorscheme cfg.variant;
        plugins = {
          catppuccin = {
            plugin = "catppuccin/nvim";
            name = "catppuccin";
            setup = "catppuccin";
            colorscheme = "catppuccin-${cfg.variant}";
          };
          rose-pine = {
            plugin = "cdmill/neomodern.nvim";
            name = "neomodern";
            setup = "neomodern";
            colorscheme = "roseprime";
          };
          gruvbox = {
            plugin = "ellisonleao/gruvbox.nvim";
            name = "gruvbox";
            setup = "gruvbox";
            colorscheme = "gruvbox";
          };
          solarized = {
            plugin = "craftzdog/solarized-osaka.nvim";
            name = "solarized-osaka";
            setup = "solarized-osaka";
            colorscheme = "solarized-osaka";
          };
          nord = {
            plugin = "EdenEast/nightfox.nvim";
            name = "nightfox";
            setup = "nightfox";
            colorscheme = "nordfox";
          };
          kanagawa = {
            plugin = "rebelot/kanagawa.nvim";
            name = "kanagawa";
            setup = "kanagawa";
            colorscheme = "kanagawa-${cfg.variant}";
          };
        };
        colors = themes.getUnifiedColors (themes.getThemePalette cfg.colorscheme cfg.variant);
        ansi = themes.ansiMappings.${cfg.colorscheme}.${cfg.variant} or { };
      };
    };
  };
}
