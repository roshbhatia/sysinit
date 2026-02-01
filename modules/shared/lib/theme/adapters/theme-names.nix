_:

let
  appMetadata = {
    wezterm = {
      catppuccin = {
        latte = "Catppuccin Latte";
        macchiato = "Catppuccin Macchiato";
      };
      "rose-pine" = {
        dawn = "Rosé Pine Dawn (base16)";
        moon = "Rosé Pine Moon (base16)";
      };
      gruvbox = {
        dark = "Gruvbox Material (Gogh)";
        light = "Gruvbox light, hard (base16)";
      };
      solarized = {
        dark = "Solarized Dark Higher Contrast (Gogh)";
        light = "Solarized Light (Gogh)";
      };
      nord = {
        default = "Nord (Gogh)";
        light = "Nord Light (Gogh)";
      };
      everforest = {
        dark-hard = "Everforest Dark Hard (Gogh)";
        dark-medium = "Everforest Dark (Gogh)";
        dark-soft = "Everforest Dark Soft (Gogh)";
        light-hard = "Everforest Light Hard (Gogh)";
        light-medium = "Everforest Light (Gogh)";
        light-soft = "Everforest Light Soft (Gogh)";
      };
      kanagawa = {
        lotus = "Kanagawa Lotus (Gogh)";
        wave = "Kanagawa (Gogh)";
        dragon = "Kanagawa Dragon (Gogh)";
      };
      "black-metal" = {
        gorgoroth = "Black Metal (Gorgoroth) (base16)";
      };
      kanso = {
        zen = "kanso-zen";
        ink = "kanso-ink";
        mist = "kanso-mist";
        pearl = "kanso-pearl";
      };
      tokyonight = {
        night = "Tokyo Night (Gogh)";
        storm = "Tokyo Night Storm (Gogh)";
        day = "Tokyo Night Day (Gogh)";
      };
      flexoki = {
        light = "flexoki-light";
      };
      "apple-system-colors" = {
        light = "apple-system-colors-light";
      };
    };
  };
  getAppMetadata =
    app: colorscheme: variant: fallback:
    let
      appMap = appMetadata.${app} or { };
      themeMap = appMap.${colorscheme} or { };
      result = themeMap.${variant} or fallback;
    in
    result;

  getWeztermTheme =
    colorscheme: variant: getAppMetadata "wezterm" colorscheme variant "${colorscheme}-${variant}";
in

{
  inherit
    getAppMetadata
    getWeztermTheme
    ;
}
