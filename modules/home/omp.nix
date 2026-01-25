{
  lib,
  values,
  ...
}:
let
  themes = import ../shared/lib/theme.nix { inherit lib; };

  validatedTheme = values.theme;
  palette = themes.getThemePalette validatedTheme.colorscheme validatedTheme.variant;
  semanticColors = themes.getSemanticColors validatedTheme.colorscheme validatedTheme.variant;

  ompColors = {
    inherit (semanticColors.accent) primary;
    muted = semanticColors.accent.dim;
    inherit (semanticColors.semantic) error;
    accent =
      palette.lavender or palette.iris or palette.violet or palette.foam
        or semanticColors.accent.tertiary;
    inherit (semanticColors.semantic) info;
  };

  themeConfig = {
    "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
    palette = {
      inherit (ompColors) primary;
      muted = "p:primary";
      inherit (ompColors) error;
      inherit (ompColors) accent;
      inherit (ompColors) info;
    };
    blocks = [
      {
        alignment = "left";
        segments = [
          {
            foreground = "p:accent";
            style = "plain";
            template = "{{ .UserName }}";
            type = "session";
          }
          {
            foreground = "p:info";
            style = "plain";
            template = "@[";
            type = "session";
          }
          {
            foreground = "p:accent";
            style = "plain";
            template = "{{.HostName}}";
            type = "path";
          }
          {
            foreground = "p:info";
            style = "plain";
            template = "] ➜";
            type = "session";
          }
          {
            foreground = "p:info";
            properties = {
              style = "agnoster_short";
            };
            style = "plain";
            template = " {{ .Path }} ";
            type = "path";
          }
          {
            foreground = "p:info";
            properties = {
              branch_icon = "";
            };
            style = "plain";
            template = "<p:accent>git</>({{ .HEAD }}) ";
            type = "git";
          }
          {
            foreground = "p:accent";
            style = "plain";
            template = "󱄅 ({{ .Type }}) ";
            type = "nix-shell";
          }
          {
            style = "plain";
            foreground = "p:error";
            template = " > ";
            type = "text";
          }
        ];
        type = "prompt";
      }
    ];
    final_space = true;
    version = 3;
  };
in
{
  xdg.configFile."oh-my-posh/themes/sysinit.omp.json" = {
    text = themes.toJsonFile themeConfig;
    force = true;
  };
}
