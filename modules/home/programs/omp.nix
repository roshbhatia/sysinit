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
              foreground = "p:info";
              style = "plain";
              template = ''{{ if eq .Env.FISH__BIND_MODE "insert" }}:{{ else if or (eq .Env.FISH__BIND_MODE "default") (eq .Env.FISH__BIND_MODE "visual") }}>{{ end }} '';
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
