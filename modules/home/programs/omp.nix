{
  lib,
  config,
  ...
}:
let
  themeLib = import ../../shared/theme-colors.nix { inherit lib; };
  themeColors = themeLib.colorsOf config;
  ompColors = {
    primary = "#${themeColors.base0D}";
    muted = "#${themeColors.base03}";
    error = "#${themeColors.base08}";
    accent = "#${themeColors.base0E}";
    info = "#${themeColors.base0D}";
  };
in
{
  programs.oh-my-posh = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;

    settings = {
      "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
      console_title_template = "{{ .Folder }}";
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
            # Same job as the nix-shell segment: name the thing wrapping this
            # shell. It matters more here, because zmx is a VT boundary that OSC
            # does not cross, so wezterm's agent and cwd surfaces go quiet for
            # any pane showing this.
            {
              foreground = "p:error";
              style = "plain";
              template = "{{ if .Env.ZMX_SESSION }}zmx({{ trimPrefix .Env.ZMX_SESSION_PREFIX .Env.ZMX_SESSION }}) {{ end }}";
              type = "text";
            }
            {
              foreground = "p:accent";
              style = "plain";
              template = "{{ if .Env.ORC_PROMPT }}{{ .Env.ORC_PROMPT }} {{ end }}";
              type = "text";
            }
          ];
          type = "prompt";
        }
      ];
      final_space = true;
      version = 3;
    };
  };
}
