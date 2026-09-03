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
    pkgs.changes-provider-ast-grep
    pkgs.changes-provider-calldiff
  ];

  xdg.configFile = {
    "changes/config.yaml".source = yamlFormat.generate "changes-config.yaml" {
      color = "auto";
      diff = {
        command = [ ];
        engine = "internal";
        layout = "unified";
      };
      providers.directory = "${config.xdg.configHome}/changes/providers";
    };

    "changes/providers/ast-grep/provider.yaml".source =
      "${pkgs.changes-provider-ast-grep}/share/changes/providers/ast-grep/provider.yaml";
    "changes/providers/calldiff/provider.yaml".source =
      "${pkgs.changes-provider-calldiff}/share/changes/providers/calldiff/provider.yaml";
  };
}
