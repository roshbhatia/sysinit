{
  config,
  lib,
  pkgs,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
in
{
  home.packages = [
    pkgs.diffnav
    (lib.lowPrio pkgs.changes-providers)
    (lib.lowPrio pkgs.changes-provider-git-notes)
  ];

  xdg.configFile = {
    "changes/config.yaml".source = yamlFormat.generate "changes-config.yaml" {
      color = "auto";
      interactive.reader = [ "${pkgs.diffnav}/bin/diffnav" ];
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
    "changes/providers/git-notes/provider.yaml".source =
      "${pkgs.changes-provider-git-notes}/share/changes/providers/git-notes/provider.yaml";
  };
}
