{
  lib,
  pkgs,
  config,
  ...
}:
let
  ruleRoot = ./rules;
  configDir = "${config.xdg.configHome}/ast-grep";

  # Enumerated off the directory, so adding a rule file needs no edit here.
  ruleFiles = lib.listToAttrs (
    map (name: {
      name = "ast-grep/rules/${name}";
      value.source = ruleRoot + "/${name}";
    }) (lib.filter (lib.hasSuffix ".yml") (lib.attrNames (builtins.readDir ruleRoot)))
  );

  # ast-grep has no config environment variable and never reads XDG. It finds
  # `sgconfig.yml` by walking up from the working directory, so a global rule set
  # is only reachable through `-c`. This wrapper is that reachability: inside a
  # repository with its own sgconfig.yml, run plain `ast-grep scan` instead and
  # get that project's rules.
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

  xdg.configFile = ruleFiles // {
    "ast-grep/sgconfig.yml".text = lib.generators.toYAML { } {
      # `ruleDirs` is the only way in. An inline `rules:` key parses as YAML and
      # is then discarded, which is how the previous version of this module ran
      # zero of its eighteen rules for as long as it existed.
      ruleDirs = [ "rules" ];

      # Only genuine additions belong here. ast-grep already maps every standard
      # extension to its language, so restating `*.ts -> typescript` buys
      # nothing. These two are extensions ast-grep does not know.
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
