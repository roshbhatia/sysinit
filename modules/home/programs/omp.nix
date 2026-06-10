{
  config,
  ...
}:
let
  ompColors = {
    primary = "#${config.lib.stylix.colors.base0D}"; # Blue (accent primary)
    muted = "#${config.lib.stylix.colors.base03}"; # Comments (accent dim)
    error = "#${config.lib.stylix.colors.base08}"; # Red
    accent = "#${config.lib.stylix.colors.base0E}"; # Purple (accent tertiary)
    info = "#${config.lib.stylix.colors.base0D}"; # Blue
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
      # Emit an OSC-2 title carrying just the current folder so the terminal
      # (WezTerm) has a meaningful per-prompt title to show instead of "zsh"
      # or an empty string. WezTerm's format-tab-title reads this as pane.title.
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
          ];
          type = "prompt";
        }
      ];
      final_space = true;
      version = 3;
    };
  };
}
