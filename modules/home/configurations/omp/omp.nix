{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;

  ompColors = {
    os = colors.accent.primary;
    closer = colors.accent.primary;
    pink = palette.pink or palette.love or palette.magenta or palette.mauve or colors.semantic.error;
    lavender =
      palette.lavender or palette.iris or palette.violet or palette.foam or colors.semantic.info;
    blue = colors.semantic.info;
  };

  themeConfig = {
    "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
    palette = {
      os = ompColors.os;
      closer = "p:os";
      pink = ompColors.pink;
      lavender = ompColors.lavender;
      blue = ompColors.blue;
    };
    blocks = [
      {
        alignment = "left";
        segments = [
          {
            foreground = "p:lavender";
            style = "plain";
            template = "@{{ .UserName }} ➜";
            type = "session";
          }
          {
            foreground = "p:blue";
            properties = {
              style = "agnoster_short";
            };
            style = "plain";
            template = " {{ .Path }} ";
            type = "path";
          }
          {
            foreground = "p:blue";
            style = "powerline";
            template = "({{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }}) ";
            type = "go";
          }
          {
            foreground = "p:pink";
            style = "powerline";
            template = "( {{ if .Error }}{{ .Error }}{{ else }}{{ if .Venv }}{{ .Venv }} {{ end }}{{ .Full }}{{ end }}) ";
            type = "python";
          }
          {
            foreground = "p:blue";
            properties = {
              branch_icon = "";
            };
            style = "plain";
            template = "<p:lavender>git(</>{{ .HEAD }}<p:lavender>) </>";
            type = "git";
          }
          {
            foreground = "p:pink";
            properties = {
              always_enabled = false;
              style = "austin";
              threshold = 100;
            };
            style = "powerline";
            template = "{{ .FormattedMs }}";
            type = "executiontime";
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
