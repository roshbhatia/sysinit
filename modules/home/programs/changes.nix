{
  config,
  pkgs,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
in
{
  home.packages = [
    pkgs.changes-providers
  ];

  xdg.configFile = {
    "changes/config.yaml".source = yamlFormat.generate "changes-config.yaml" {
      color = "auto";
      diff = {
        engine = "builtin";
        layout = "unified";
      };
      providers.directory = "${config.xdg.configHome}/changes/providers";
    };

    "changes/providers/ast-grep/provider.yaml".source =
      "${pkgs.changes-providers}/share/changes/providers/ast-grep/provider.yaml";
    "changes/providers/calldiff/provider.yaml".source =
      "${pkgs.changes-providers}/share/changes/providers/calldiff/provider.yaml";
  };
}
