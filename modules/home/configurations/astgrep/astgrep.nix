{
  lib,
  pkgs,
  ...
}:

let
  astgrepConfig = {
    rulesDirs = [ "rules" ];
    # Support for language injection and custom language configurations
    languageGlobs = {
      yaml = [
        "*.yaml"
        "*.yml"
      ];
      # Support Go template syntax in yaml files
      gotmpl = [
        "*.gotmpl"
        "*.tpl"
      ];
    };
    # Enable custom language support for templates
    customLanguages = {
      # Register gotmpl as an extension of yaml with template support
      "yaml-with-templates" = {
        languageId = "yaml";
        extensions = [
          ".gotmpl"
          ".tpl"
        ];
        # Support template variable syntax like {{ .Values.foo }}
        injections = [
          {
            pattern = "\\{\\{.*?\\}\\}";
            language = "go";
          }
        ];
      };
    };
  };

  # Example rule that demonstrates Go template variable support
  exampleRule = pkgs.writeText "example-rule.yml" ''
    id: example-template-vars
    language: yaml
    message: Example ast-grep rule with template variable support
    note: |
      This rule supports Go template syntax like {{ $VAR }} and {{ .Values.field }}
      Metavariables in ast-grep use $VAR syntax, similar to Go templates

    rule:
      pattern: |
        key: $VALUE

    # Example of using metavariable constraints
    constraints:
      VALUE:
        regex: '^\{\{.*\}\}$'

    fix: |
      key: "{{ .Values.$VALUE }}"
  '';

  astgrepYaml = pkgs.writeText "sgconfig.yml" (lib.generators.toYAML { } astgrepConfig);
in
{
  xdg.configFile."ast-grep/sgconfig.yml" = {
    source = astgrepYaml;
    force = true;
  };

  # Create rules directory with example
  xdg.configFile."ast-grep/rules/.gitkeep".text = "";
  xdg.configFile."ast-grep/rules/examples/template-vars.yml" = {
    source = exampleRule;
  };
}
