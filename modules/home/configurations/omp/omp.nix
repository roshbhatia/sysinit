{
  lib,
  values,
  ...
}:
let
  themes = import ../../../lib/theme { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

  ompColors = {
    primary = semanticColors.accent.primary;
    muted = semanticColors.accent.dim;
    error = semanticColors.semantic.error;
    accent =
      palette.lavender or palette.iris or palette.violet or palette.foam
        or semanticColors.accent.tertiary;
    info = semanticColors.semantic.info;
  };

  themeConfig = {
    "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
    palette = {
      primary = ompColors.primary;
      muted = "p:primary";
      error = ompColors.error;
      accent = ompColors.accent;
      info = ompColors.info;
    };
    blocks = [
      {
        alignment = "left";
        segments = [
          {
            foreground = "p:accent";
            style = "plain";
            template = "@{{ .UserName }} ➜";
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
            template = "<p:accent>git(</>{{ .HEAD }}<p:accent>) </>";
            type = "git";
          }
          {
            foreground = "p:accent";
            style = "plain";
            template = "󱄅 ({{ .Type }})";
            type = "nix-shell";
          }
          {
            foreground = "p:error";
            properties = {
              always_enabled = false;
              style = "austin";
              threshold = 100;
            };
            style = "powerline";
            template = "{{ .FormattedMs }}";
            type = "executiontime";
          }
          {
            style = "plain";
            foreground = "p:primary";
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
    text = builtins.toJSON themeConfig;
    force = true;
  };
}
