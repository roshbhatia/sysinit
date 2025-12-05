{ lib, ... }:

let
  utils = import ../core/utils.nix { inherit lib; };
in

rec {
  meta = {
    name = "Black Metal";
    id = "black-metal";
    variants = [ "gorgoroth" ];
    supports = [ "dark" ];
    appearanceMapping = {
      light = null;
      dark = "gorgoroth";
    };
    author = "metalelf0";
    homepage = "https://github.com/metalelf0/base16-black-metal-scheme";
  };

  palettes = {
    # Gorgoroth variant - based on base16 Black Metal (Gorgoroth)
    # Pure black background with muted, desaturated accent colors
    gorgoroth = utils.validatePalette {
      # Base16 colors
      base00 = "#000000"; # Pure black background
      base01 = "#121212"; # Lighter black
      base02 = "#222222"; # Selection background
      base03 = "#555555"; # Comments, invisibles (brighter)
      base04 = "#aaaaaa"; # Dark foreground (brighter)
      base05 = "#c1c1c1"; # Default foreground
      base06 = "#bbbbbb"; # Light foreground
      base07 = "#d0d0d0"; # Lightest foreground
      base08 = "#cc6666"; # Red - distinct washed red
      base09 = "#de935f"; # Orange - distinct washed orange
      base0A = "#f0c674"; # Yellow - distinct washed yellow
      # Semantic colors - expanded with distinct washed-out colors
      # Following industry standards:
      # - Red: errors, deletions, destructive actions
      # - Orange: warnings, moderate priority
      # - Yellow: caution, information that needs attention
      # - Green: success, additions, confirmations
      # - Blue: info, primary actions, links
      # - Purple: special, unique elements
      # - Cyan: highlights, secondary info
      red = "#cc6666"; # Error/destructive - washed red
      orange = "#de935f"; # Warning/moderate - washed orange
      yellow = "#f0c674"; # Caution/attention - washed yellow
      green = "#a5c25a"; # Success/safe - washed green (brighter for visibility)
      cyan = "#8abeb7"; # Highlight/secondary - washed cyan
      blue = "#81a2be"; # Info/primary - washed blue
      purple = "#b294bb"; # Special/unique - washed purple
      magenta = "#b777e0"; # Accent/tertiary - washed magenta
      teal = "#5e8d87"; # Muted accent - washed teal
      brown = "#a88654"; # Neutral/data - washed brown
      pink = "#d0879f"; # Soft accent - washed pink
      lime = "#a5b76e"; # Success variant - washed lime

      # UI semantic mappings following best practices
      accent = "#81a2be"; # Primary accent (blue - safe, neutral)
      accent_dim = "#222222"; # Dimmed background
      border_active = "#81a2be"; # Active border (blue - clearly visible)
      border_inactive = "#555555"; # Inactive border (dark gray - subtle)
      border_focus = "#8abeb7"; # Focus border (cyan - distinct from active)
      border_active = "#81a2be"; # Active border (blue - clearly visible)
      border_inactive = "#555555"; # Inactive border (dark gray - subtle)
      border_focus = "#8abeb7"; # Focus border (cyan - distinct from active)
    };
  };

  semanticMapping = palette: utils.createSemanticMapping palette;

  appAdapters = {
    # Wezterm uses base16 built-in theme
    wezterm = {
      gorgoroth = "Black Metal (Gorgoroth)";
    };

    # Neovim uses metalelf0's black-metal-theme-neovim plugin
    neovim = {
      plugin = "metalelf0/black-metal-theme-neovim";
      name = "black-metal";
      setup = "black-metal";
      colorscheme = _variant: "gorgoroth";
    };

    # Custom theme files for other tools
    bat = variant: "black-metal-${variant}";
    delta = variant: "black-metal-${variant}";
    k9s = variant: "black-metal-${variant}";
    atuin = variant: "black-metal-${variant}";
    vivid = variant: "black-metal-${variant}";
    helix = _variant: "black-metal";
    opencode = "system";

    # Sketchybar colors
    sketchybar = {
      background = palettes.gorgoroth.base00;
      foreground = palettes.gorgoroth.base05;
      accent = palettes.gorgoroth.base0D;
      warning = palettes.gorgoroth.base0A;
      success = palettes.gorgoroth.base0B;
      error = palettes.gorgoroth.base08;
      info = palettes.gorgoroth.base0D;
      muted = palettes.gorgoroth.base04;
      highlight = palettes.gorgoroth.base09;
    };
  };
}
