{
  lib,
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

  xdg.configFile."changes/config.yaml".source = yamlFormat.generate "changes-config.yaml" {
    color = "auto";
    diff = {
      command = [ ];
      engine = "internal";
      layout = "unified";
    };
    providers = [
      {
        capabilities = [ "symbols" ];
        command = [ (lib.getExe pkgs.changes-provider-ast-grep) ];
        description = "Map changed lines to source symbols with ast-grep";
        name = "symbols";
        requires = [ (lib.getExe pkgs.ast-grep) ];
      }
      {
        capabilities = [ "calls" ];
        command = [ (lib.getExe pkgs.changes-provider-calldiff) ];
        description = "Find call edges changed by the patch with calldiff";
        name = "calls";
        requires = [ (lib.getExe pkgs.calldiff) ];
      }
    ];
  };
}
