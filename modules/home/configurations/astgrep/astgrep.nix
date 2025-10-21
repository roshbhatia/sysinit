{
  lib,
  pkgs,
  ...
}:

let
  astgrepConfig = {
    rulesDirs = [ "rules" ];
  };

  astgrepYaml = pkgs.writeText "sgconfig.yml" (lib.generators.toYAML { } astgrepConfig);
in
{
  xdg.configFile."ast-grep/sgconfig.yml" = {
    source = astgrepYaml;
    force = true;
  };
}
