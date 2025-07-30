{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;

  ompColors = {
    os = (
      palette.accent or palette.blue or palette.pine or palette.iris or palette.violet or "#8CAAEE"
    );
    closer = (
      palette.accent or palette.blue or palette.pine or palette.iris or palette.violet or "#8CAAEE"
    );
    pink = (
      palette.pink or palette.love or palette.magenta or palette.purple or palette.rose or "#F4B8E4"
    );
    lavender = (palette.lavender or palette.iris or palette.violet or palette.foam or "#BABBF1");
    blue = (
      palette.blue or palette.accent or palette.pine or palette.iris or palette.violet or "#8CAAEE"
    );
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
          {
            type = "text";
            foreground = "p:closer";
            style = "plain";
            template = "{{ if .Env.POSH_VI_MODE }}({{ .Env.POSH_VI_MODE }}){{ end }}";
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

