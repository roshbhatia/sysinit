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
    os = colors.primary;
    closer = colors.primary;
    pink = palette.pink or palette.love or palette.magenta or palette.mauve or colors.error;
    lavender = palette.lavender or palette.iris or palette.violet or palette.foam or colors.info;
    blue = colors.info;
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
            foreground = "p:os";
            style = "plain";
            template = "󱄅 ";
            type = "os";
          }
          {
            foreground = "p:blue";
            style = "plain";
            template = "{{ .UserName }}@{{ .HostName }} ";
            type = "session";
          }
          {
            foreground = "p:pink";
            properties = {
              folder_icon = "....";
              home_icon = "~";
              style = "agnoster_short";
            };
            style = "plain";
            template = "{{ .Path }} ";
            type = "path";
          }
          {
            foreground = "p:lavender";
            properties = {
              branch_icon = " ";
              cherry_pick_icon = " ";
              commit_icon = " ";
              fetch_status = true;
              fetch_upstream_icon = " ";
              merge_icon = " ";
              no_commits_icon = " ";
              rebase_icon = " ";
              revert_icon = "󰆴 ";
              tag_icon = " ";
            };
            template = "{{ .HEAD }} ";
            style = "plain";
            type = "git";
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
