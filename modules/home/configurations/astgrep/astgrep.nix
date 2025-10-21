{ config, lib, ... }:
{
  xdg.configFile = {
    "ast-grep/sgconfig.yml" = {
      text = lib.generators.toYAML {} {
        # Global ast-grep configuration
        rules = [
          {
            id = "no-console-log";
            message = "Avoid console.log in production code";
            severity = "warning";
            language = "typescript";
            pattern = "console.log($$$)";
            fix = "// TODO: Replace with proper logging";
          }
          {
            id = "proper-error-handling";
            message = "Always handle errors explicitly";
            severity = "error";
            language = "go";
            pattern = "_, err := $CALL($$$)\nif err != nil { return err }";
          }
          {
            id = "async-await";
            message = "Prefer async/await over .then()";
            severity = "info";
            language = "typescript";
            pattern = "$PROMISE.then($CALLBACK)";
            fix = "await $PROMISE";
          }
        ];
        
        # Language-specific settings
        languageGlobs = {
          typescript = ["*.ts" "*.tsx"];
          javascript = ["*.js" "*.jsx"];
          python = ["*.py"];
          go = ["*.go"];
          rust = ["*.rs"];
          lua = ["*.lua"];
          nix = ["*.nix"];
        };
      };
      force = true;
    };
    
    # Project-specific rules can be added to .ast-grep/sgconfig.yml in each project
    "ast-grep/README.md" = {
      source = ../llm/docs/ast-grep-guide.md;
    };
  };
}
