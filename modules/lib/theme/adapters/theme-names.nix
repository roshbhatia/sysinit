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
      everforest = {
        dark-hard = "Everforest Dark Hard (Gogh)";
        dark-medium = "Everforest Dark (Gogh)";
        dark-soft = "Everforest Dark Soft (Gogh)";
        light-hard = "Everforest Light Hard (Gogh)";
        light-medium = "Everforest Light (Gogh)";
        light-soft = "Everforest Light Soft (Gogh)";
      };
      "windows-95" = {
        light = "Windows 95 Light (base16)";
        dark = "Windows 95 (base16)";
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
