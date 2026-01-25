{ lib, ... }:

{
  # === AST-grep: AST-based code search ===
  xdg.configFile = {
    "ast-grep/sgconfig.yml" = {
      text = lib.generators.toYAML { } {
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
            id = "async-await";
            message = "Prefer async/await over .then()";
            severity = "info";
            language = "typescript";
            pattern = "$PROMISE.then($CALLBACK)";
            fix = "await $PROMISE";
          }

          {
            id = "go-error-ignore";
            message = "Never ignore errors silently";
            severity = "error";
            language = "go";
            pattern = "_, err := $CALL($$$)";
          }
          {
            id = "go-context-first";
            message = "Context should be the first parameter";
            severity = "warning";
            language = "go";
            pattern = "func $NAME($$$, ctx context.Context, $$$) $$$";
          }
          {
            id = "go-defer-close";
            message = "Always defer Close() after checking error on Open/Create";
            severity = "warning";
            language = "go";
            pattern = ''
              $VAR, err := $OPEN($$$)
              if err != nil {
                $$$
              }
            '';
            note = "Add: defer $VAR.Close()";
          }
          {
            id = "go-nil-check-before-len";
            message = "Check for nil before using len() on slices/maps";
            severity = "warning";
            language = "go";
            pattern = "if len($VAR) == 0";
            note = "Consider: if $VAR == nil || len($VAR) == 0";
          }
          {
            id = "go-empty-interface";
            message = "Prefer 'any' over 'interface{}'";
            severity = "info";
            language = "go";
            pattern = "interface{}";
            fix = "any";
          }

          {
            id = "shell-unquoted-variable";
            message = "Always quote variables to prevent word splitting";
            severity = "error";
            language = "bash";
            pattern = "echo $$VAR";
            fix = ''echo "$$VAR"'';
          }
          {
            id = "shell-set-errexit";
            message = "Use 'set -e' or 'set -euo pipefail' at script start";
            severity = "warning";
            language = "bash";
            pattern = "#!/bin/bash";
            note = "Add 'set -euo pipefail' after shebang for safer scripts";
          }
          {
            id = "shell-command-substitution";
            message = "Prefer $() over backticks for command substitution";
            severity = "info";
            language = "bash";
            pattern = "`$CMD`";
            fix = "$$($CMD)";
          }
          {
            id = "shell-test-bracket";
            message = "Prefer [[ ]] over [ ] in bash/zsh";
            severity = "info";
            language = "bash";
            pattern = "if [ $$$";
            fix = "if [[ $$$";
          }
          {
            id = "shell-rm-no-force";
            message = "Be cautious with 'rm -rf', consider checking path first";
            severity = "warning";
            language = "bash";
            pattern = "rm -rf $$$";
          }
          {
            id = "shell-cd-without-check";
            message = "Always check if cd succeeded";
            severity = "error";
            language = "bash";
            pattern = "cd $DIR";
            note = "Use: cd $DIR || exit 1";
          }

          {
            id = "k8s-no-latest-tag";
            message = "Avoid using 'latest' tag in production";
            severity = "warning";
            language = "yaml";
            pattern = "image: $IMAGE:latest";
            note = "Specify explicit version tags for reproducibility";
          }
          {
            id = "k8s-resource-limits";
            message = "Always specify resource limits and requests";
            severity = "warning";
            language = "yaml";
            pattern = ''
              containers:
                - name: $NAME
                  image: $IMAGE
            '';
            note = "Add resources.limits and resources.requests";
          }
          {
            id = "k8s-liveness-probe";
            message = "Consider adding liveness and readiness probes";
            severity = "info";
            language = "yaml";
            pattern = ''
              containers:
                - name: $NAME
            '';
            note = "Add livenessProbe and readinessProbe for better health checks";
          }
          {
            id = "k8s-security-context";
            message = "Consider adding securityContext for better security";
            severity = "info";
            language = "yaml";
            pattern = ''
              containers:
                - name: $NAME
            '';
            note = "Add securityContext with runAsNonRoot, readOnlyRootFilesystem";
          }
          {
            id = "k8s-image-pull-policy";
            message = "Explicitly set imagePullPolicy";
            severity = "info";
            language = "yaml";
            pattern = ''
              containers:
                - name: $NAME
                  image: $IMAGE
            '';
            note = "Add imagePullPolicy: Always or IfNotPresent";
          }
        ];

        languageGlobs = {
          typescript = [
            "*.ts"
            "*.tsx"
          ];
          javascript = [
            "*.js"
            "*.jsx"
          ];
          python = [ "*.py" ];
          go = [ "*.go" ];
          rust = [ "*.rs" ];
          lua = [ "*.lua" ];
          nix = [ "*.nix" ];
          bash = [
            "*.sh"
            "*.bash"
            "*.zsh"
          ];
          yaml = [
            "*.yaml"
            "*.yml"
            "*.tmpl"
            "*.tpl"
          ];
        };
      };
      force = true;
    };
  };

  # === Utils: Script installation ===
  home.file = {
    ".local/bin/dns-flush" = {
      source = ./configurations/utils/network/dns-flush.nu;
      executable = true;
    };

    ".local/bin/set-background" = {
      source = ./configurations/utils/system/set-background.nu;
      executable = true;
    };

    ".local/bin/connect" = {
      source = ./configurations/utils/dev/connect.nu;
      executable = true;
    };

    ".local/bin/loglib.nu" = {
      source = ./configurations/utils/dev/loglib.nu;
      executable = true;
    };
  };
}
