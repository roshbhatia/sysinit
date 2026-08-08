{
  lib,
  pkgs,
  config,
  ...
}:
let
  configDir = "${config.xdg.configHome}/ast-grep";

  sgg = pkgs.writeShellApplication {
    name = "sgg";
    runtimeInputs = [ pkgs.ast-grep ];
    text = ''
      exec ast-grep scan --config "${configDir}/sgconfig.yml" "$@"
    '';
  };
in
{
  home.packages = [ sgg ];

  xdg.configFile = {
    "ast-grep/rules".source = ./rules;

    "ast-grep/sgconfig.yml".text = lib.generators.toYAML { } {
      ruleDirs = [ "rules" ];

      languageGlobs = {
        bash = [ "*.zsh" ];
        yaml = [
          "*.tmpl"
          "*.tpl"
        ];
      };
    };
  };
}
