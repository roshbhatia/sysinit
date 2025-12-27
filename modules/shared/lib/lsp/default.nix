{
  # Shared LSP server configurations used across helix, llm, and other tools
  # This module provides a single source of truth for language server settings

  rust-analyzer = {
    config = {
      checkOnSave = {
        command = "clippy";
      };
      procMacro = {
        enable = true;
      };
    };
  };

  gopls = {
    config = {
      gofumpt = true;
      staticcheck = true;
      analyses = {
        unusedparams = true;
        nilness = true;
      };
    };
    extensions = [ ".go" ];
    env = {
      GOTOOLCHAIN = "go1.24.5";
    };
  };

  golangci-lint-ls = {
    command = "golangci-lint-langserver";
    args = [
      "-debug"
      "false"
    ];
  };

  pyright = {
    command = "pyright-langserver";
    args = [ "--stdio" ];
    config = {
      python.analysis = {
        typeCheckingMode = "basic";
        autoImportCompletions = true;
      };
    };
    extensions = [ ".py" ];
  };

  nil = {
    command = "nil";
    config.nil = {
      formatting.command = [ "nixfmt" ];
      diagnostics.ignored = [
        "unused_binding"
        "unused_with"
      ];
    };
    extensions = [ ".nix" ];
  };

  typescript-language-server = {
    config = {
      preferences = {
        includeInlayParameterNameHints = "all";
        includeInlayParameterNameHintsWhenArgumentMatchesName = true;
        includeInlayFunctionParameterTypeHints = true;
        includeInlayVariableTypeHints = true;
        includeInlayPropertyDeclarationTypeHints = true;
        includeInlayFunctionLikeReturnTypeHints = true;
      };
    };
    extensions = [
      ".ts"
      ".tsx"
    ];
  };

  vscode-eslint-language-server = {
    command = "vscode-eslint-language-server";
    args = [ "--stdio" ];
  };

  vscode-json-language-server = {
    command = "vscode-json-language-server";
    args = [ "--stdio" ];
    extensions = [ ".json" ];
  };

  yaml-language-server = {
    command = "yaml-language-server";
    args = [ "--stdio" ];
    config = {
      yaml = {
        schemas = {
          "https://json.schemastore.org/github-workflow.json" = ".github/workflows/*.{yml,yaml}";
          "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/tasks" =
            "roles/*/tasks/*.{yml,yaml}";
          "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook" =
            "*play*.{yml,yaml}";
        };
      };
    };
    extensions = [
      ".yaml"
      ".yml"
    ];
  };

  ansible-language-server = {
    command = "ansible-language-server";
    args = [ "--stdio" ];
  };

  dockerfile-language-server = {
    command = "docker-langserver";
    args = [ "--stdio" ];
    extensions = [ "Dockerfile" ];
  };

  docker-compose-langserver = {
    command = "docker-compose-langserver";
    args = [ "--stdio" ];
  };

  jdtls = {
    command = "jdtls";
    extensions = [ ".java" ];
  };

  zls = {
    command = "zls";
    extensions = [ ".zig" ];
  };

  bash-language-server = {
    command = "bash-language-server";
    args = [ "start" ];
    extensions = [
      ".sh"
      ".bash"
      ".zsh"
      ".ksh"
    ];
  };

  awk-language-server = {
    command = "awk-language-server";
    extensions = [ ".awk" ];
  };

  vscode-css-language-server = {
    command = "vscode-css-language-server";
    args = [ "--stdio" ];
    extensions = [
      ".css"
      ".scss"
    ];
  };

  lua-language-server = {
    command = "lua-language-server";
    extensions = [ ".lua" ];
  };

  terraform-ls = {
    command = "terraform-ls";
    args = [ "serve" ];
    extensions = [
      ".tf"
      ".tfvars"
    ];
  };

  copilot = {
    command = "copilot-language-server";
    args = [ "--stdio" ];
  };

  scls = {
    command = "simple-completion-language-server";
    config = {
      max_completion_items = 100;
      feature_words = false;
      feature_snippets = true;
      snippets_first = true;
      snippets_inline_by_word_tail = false;
      feature_unicode_input = false;
      feature_paths = false;
      feature_citations = false;
    };
  };

  ast-grep = {
    command = "ast-grep";
    args = [ "lsp" ];
    extensions = [
      ".c"
      ".cpp"
      ".css"
      ".go"
      ".nix"
      ".py"
      ".rs"
      ".sh"
      ".tmpl"
      ".ts"
      ".yaml"
      ".yml"
      ".zsh"
    ];
  };

  nu = {
    command = "nu";
    args = [ "--lsp" ];
    extensions = [ ".nu" ];
  };

  up = {
    command = "up";
    args = [
      "xpls"
      "serve"
    ];
    extensions = [ ".yaml" ];
  };
}
